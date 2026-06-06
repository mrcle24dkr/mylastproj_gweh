#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"
#include <Arduino.h>
#include <WiFi.h>
#include <WiFiManager.h>
#include <HTTPClient.h>
#include <ESP32QRCodeReader.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <time.h>        // Library standar C++ untuk waktu internal (Pengganti RTC)
#include "FS.h"
#include "SD_MMC.h"
#include "TOTP.h"
#include <map>

// --- KONFIGURASI PIN ---
#define SDA_PIN 12
#define SCL_PIN 13

// --- OBJEK ---
Adafruit_SSD1306 display(128, 64, &Wire, -1);
ESP32QRCodeReader reader(CAMERA_MODEL_AI_THINKER);
WiFiManager wm;

// --- DATABASE RAM ---
std::map<String, String> databasePeserta;

// --- STATUS SISTEM ---
bool isSystemOn = true;
bool isSDCardReady = false;

// --- KONFIGURASI SERVER ---
const char* urlSync = "http://116.193.190.121:8080/api/sync-keys";
const char* urlPeserta = "http://116.193.190.121:8080/api/peserta/"; 

// --- KONFIGURASI WAKTU NTP (WIB = GMT+7) ---
const long  gmtOffset_sec = 7 * 3600; 
const int   daylightOffset_sec = 0;

// --- DEKLARASI FUNGSI ---
void tampilOled(String a, String b);
String getJamSekarang();
void syncData();
void muatDatabaseKeRAM();
String dapatkanSecret(String idPeserta);
void simpanLog(String idPeserta, String status);
void prosesAbsen(String qr);
int decodeBase32(const char* encoded, uint8_t* decoded);

// =======================================================================
// FUNGSI SETUP UTAMA
// =======================================================================
void setup() {
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0); 
  Serial.begin(115200);

  // 1. INISIALISASI OLED
  Wire.begin(SDA_PIN, SCL_PIN);
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) Serial.println("OLED Error");
  display.setRotation(2);
  display.clearDisplay();
  display.setTextColor(WHITE);

  tampilOled("BOOTING...", "Cek Hardware");
  delay(1000); 

  // 2. CEK SD CARD
  if (!SD_MMC.begin("/sdcard", true) || SD_MMC.cardType() == CARD_NONE) {
    isSDCardReady = false;
    tampilOled("MODE ONLINE", "SD Card Dilepas/Rusak");
  } else {
    isSDCardReady = true;
    tampilOled("MODE HYBRID", "SD Card Terbaca");
  }
  delay(1500); 

  // 3. KONEKSI WIFI & SINKRONISASI
  tampilOled("WIFI SETUP", "Menghubungkan...");
  delay(500);
  wm.setConfigPortalTimeout(60);
  bool wifiConnected = wm.autoConnect("ABSENSI_CAM", "empirise123");

  if (wifiConnected) {
    // ---> AMBIL JAM DARI INTERNET (NTP) <---
    tampilOled("SINKRON JAM", "Ambil Waktu NTP...");
    configTime(gmtOffset_sec, daylightOffset_sec, "pool.ntp.org", "time.nist.gov");
    
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo, 10000)) { // Tunggu maksimal 10 detik
      tampilOled("JAM GAGAL", "Cek Internet!");
      delay(2000);
    } else {
      tampilOled("JAM COCOK!", getJamSekarang());
      delay(1500);
    }

    if (isSDCardReady) {
      syncData(); 
    }
  } else if (!isSDCardReady) {
    tampilOled("FATAL ERROR", "No WiFi & No SD");
    while(true) { delay(1000); }
  }

  // 4. PINDAHKAN SELURUH DATA KE RAM
  if (isSDCardReady) {
    muatDatabaseKeRAM();
  }

  // 5. SETUP KAMERA
  tampilOled("KAMERA SETUP", "Memanaskan Lensa");
  delay(1000); 
  
  reader.setup();
  reader.begin();
  delay(1000); 

  Wire.begin(SDA_PIN, SCL_PIN);
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.setRotation(2);
  display.clearDisplay();
  display.setTextColor(WHITE);

  tampilOled("SIAP SCAN", isSDCardReady ? "Mode: Cepat (RAM)" : "Mode: Online Direct");
}

// =======================================================================
// LOOP KAMERA 
// =======================================================================
void loop() {
  if (isSystemOn) {
    struct QRCodeData qrCodeData;
    if (reader.receiveQrCode(&qrCodeData, 100)) {
      if (qrCodeData.valid) {
        String qrCode = (const char *)qrCodeData.payload;
        delay(200); 
        prosesAbsen(qrCode);
        delay(3000); 
        tampilOled("SIAP SCAN", isSDCardReady ? "Mode: Cepat (RAM)" : "Mode: Online Direct");
      }
    }
    delay(10); 
  }
}

// =======================================================================
// LOGIKA PEMROSESAN ABSEN (DENGAN JAM INTERNAL)
// =======================================================================
void prosesAbsen(String qr) {
  qr.trim();
  int separatorIndex = qr.indexOf(':');
  if (separatorIndex == -1) {
    tampilOled("GAGAL!", "Format QR Salah");
    return;
  }
  
  String idPeserta = qr.substring(0, separatorIndex);
  String otpMasuk = qr.substring(separatorIndex + 1);
  idPeserta.trim();
  otpMasuk.trim();

  tampilOled("Cek Data...", idPeserta);
  delay(300); 

  String secretKey = dapatkanSecret(idPeserta);
  if (secretKey == "") {
    tampilOled("GAGAL!", "ID Tidak Dikenal");
    simpanLog(idPeserta, "GAGAL_UNREGISTERED");
    return;
  }

  // ---> AMBIL DETIK UNIX DARI MESIN ESP32 (BUKAN RTC) <---
  time_t now;
  time(&now); 
  uint32_t unixTime = now; 
  
  // Jika mesin mati dan jam mereset (kurang dari tahun 2020), blokir!
  if (unixTime < 1577836800) { 
    tampilOled("ERROR WAKTU", "NTP Belum Sinkron");
    return;
  }

  uint8_t hmacKey[20];
  int keyLength = decodeBase32(secretKey.c_str(), hmacKey);
  
  TOTP totp(hmacKey, keyLength);
  char* otpLokal = totp.getCode(unixTime); 
  
  if (String(otpLokal) == otpMasuk) {
    tampilOled("HADIR!", idPeserta + "\n" + getJamSekarang());
    simpanLog(idPeserta, "VALID");
  } else {
    tampilOled("KADALUARSA!", "QR Sudah Usang");
    simpanLog(idPeserta, "GAGAL_EXPIRED");
  }
}

// =======================================================================
// FUNGSI PENCARIAN KUNCI (RAM -> API ONLINE)
// =======================================================================
String dapatkanSecret(String targetID) {
  if (databasePeserta.count(targetID) > 0) {
    return databasePeserta[targetID];
  }

  if (!isSDCardReady && WiFi.status() == WL_CONNECTED) {
    tampilOled("ONLINE CEK...", "Menghubungi Server");
    delay(100);

    HTTPClient http;
    http.begin(String(urlPeserta) + targetID);
    int httpCode = http.GET();
    String secret = "";

    if (httpCode == HTTP_CODE_OK) {
      String payload = http.getString();
      int keyIndex = payload.indexOf("\"QRSecretKey\":\"");
      if(keyIndex == -1) keyIndex = payload.indexOf("\"qr_secret_key\":\""); 

      if (keyIndex != -1) {
        int colonIndex = payload.indexOf(":", keyIndex);
        int startQuote = payload.indexOf("\"", colonIndex);
        int endQuote = payload.indexOf("\"", startQuote + 1);
        if(startQuote != -1 && endQuote != -1) {
          secret = payload.substring(startQuote + 1, endQuote);
        }
      }
    }
    http.end();
    return secret; 
  }
  return ""; 
}

// =======================================================================
// FUNGSI SINKRONISASI & PEMINDAHAN KE RAM
// =======================================================================
void muatDatabaseKeRAM() {
  databasePeserta.clear();
  if (!isSDCardReady) return;

  tampilOled("MEMUAT RAM", "Membaca SD Card...");
  delay(500);

  File file = SD_MMC.open("/database_peserta.csv", FILE_READ);
  if (!file) {
    tampilOled("RAM GAGAL", "File CSV Hilang");
    delay(2000);
    return;
  }

  while (file.available()) {
    String line = file.readStringUntil('\n');
    line.trim();
    int commaIndex = line.indexOf(',');
    if (commaIndex != -1) {
      String id = line.substring(0, commaIndex);
      String key = line.substring(commaIndex + 1);
      id.replace("\r", "");
      key.replace("\r", "");
      databasePeserta[id] = key; 
    }
  }
  file.close();
  
  tampilOled("RAM SUKSES!", String(databasePeserta.size()) + " Peserta Siap");
  delay(1500);
}

void syncData() {
  tampilOled("SINKRONISASI", "Unduh Data Server");
  delay(500);

  HTTPClient http;
  http.begin(urlSync);
  int httpCode = http.GET();
  
  if (httpCode == HTTP_CODE_OK) {
    File file = SD_MMC.open("/database_peserta.csv", FILE_WRITE);
    if (file) {
      http.writeToStream(&file);
      file.close();
      tampilOled("SINKRON SUKSES", "Database Terkini");
      delay(1500);
    } else {
      tampilOled("SINKRON GAGAL", "Gagal Tulis SD Card");
      delay(2000);
    }
  } else {
    tampilOled("SINKRON GAGAL", "Server Down/Error");
    delay(2000);
  }
  http.end();
}

// =======================================================================
// FUNGSI PENDUKUNG WAKTU INTERNAL (PENGGANTI RTC)
// =======================================================================
String getJamSekarang() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    return "NTP BELUM SINKRON";
  }
  char buffer[20];
  snprintf(buffer, sizeof(buffer), "%02d-%02d-%04d %02d:%02d:%02d", 
           timeinfo.tm_mday, timeinfo.tm_mon + 1, timeinfo.tm_year + 1900, 
           timeinfo.tm_hour, timeinfo.tm_min, timeinfo.tm_sec);
  return String(buffer);
}

void simpanLog(String idPeserta, String status) {
  if (!isSDCardReady) return;
  
  File file = SD_MMC.open("/log_presensi.csv", FILE_APPEND);
  if (file) {
    file.print(idPeserta); file.print(",");
    file.print(status); file.print(",");
    file.println(getJamSekarang());
    file.close();
  }
}

int decodeBase32(const char* encoded, uint8_t* decoded) {
  int buffer = 0, bitsLeft = 0, count = 0;
  for (const char* ptr = encoded; *ptr; ++ptr) {
    char ch = *ptr;
    if (ch == ' ' || ch == '=') continue; 
    buffer <<= 5;
    if (ch >= 'A' && ch <= 'Z') buffer |= (ch - 'A');
    else if (ch >= 'a' && ch <= 'z') buffer |= (ch - 'a');
    else if (ch >= '2' && ch <= '7') buffer |= (ch - '2' + 26);
    else return -1; 
    
    bitsLeft += 5;
    if (bitsLeft >= 8) {
      decoded[count++] = buffer >> (bitsLeft - 8);
      bitsLeft -= 8;
    }
  }
  return count;
}

void tampilOled(String a, String b) {
  display.clearDisplay();
  display.setCursor(0,0); display.setTextSize(1);
  display.println(a);
  display.setCursor(0,20);
  display.println(b);
  display.display();
}