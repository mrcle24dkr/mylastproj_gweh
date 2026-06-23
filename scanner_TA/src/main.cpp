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
#include <time.h>
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

// --- DATABASE RAM & INGATAN ---
std::map<String, String> databasePeserta;
std::map<String, bool> sudahAbsen; 

// --- STATUS SISTEM & PEMANTAU WIFI ---
bool isSystemOn = true;
bool isSDCardReady = false;
bool wasWiFiConnected = false;     
unsigned long lastWiFiCheck = 0;   
const unsigned long wifiCheckInterval = 5000; 

// --- KONFIGURASI SERVER ---
const char* urlSync = "http://116.193.190.121:8080/api/sync-keys";
const char* urlPeserta = "http://116.193.190.121:8080/api/peserta/"; 
const char* urlLog = "http://116.193.190.121:8080/api/logs";

const long  gmtOffset_sec = 7 * 3600; 
const int   daylightOffset_sec = 0;

// --- DEKLARASI FUNGSI ---
void tampilOled(String a, String b);
String getJamSekarang();
void syncData();
void kirimLogOfflineKeServer(); 
void muatDatabaseKeRAM();
String dapatkanSecret(String idPeserta);
void simpanLog(String idPeserta, String status);
void prosesAbsen(String qr);
int decodeBase32(const char* encoded, uint8_t* decoded);
void configModeCallback(WiFiManager *myWiFiManager); 

// =======================================================================
// CALLBACK WIFI MANAGER
// =======================================================================
void configModeCallback(WiFiManager *myWiFiManager) {
  tampilOled("PORTAL AKTIF!", "Cari WiFi:\nABSENSI_CAM");
}

// =======================================================================
// SETUP UTAMA
// =======================================================================
void setup() {
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0); 
  
  Wire.begin(SDA_PIN, SCL_PIN);
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    // Abaikan jika OLED bermasalah saat boot awal
  }
  display.setRotation(2);
  display.clearDisplay();
  display.setTextColor(WHITE);

  tampilOled("BOOTING...", "Cek Hardware");
  delay(1000); 

  if (!SD_MMC.begin("/sdcard", true) || SD_MMC.cardType() == CARD_NONE) {
    isSDCardReady = false;
    tampilOled("MODE ONLINE", "SD Card Dilepas/Rusak");
  } else {
    isSDCardReady = true;
    tampilOled("MODE HYBRID", "SD Card Terbaca");
  }
  delay(1500); 

  tampilOled("WIFI SETUP", "Menghubungkan...");
  delay(500);
  
  wm.setAPCallback(configModeCallback); 
  wm.setConfigPortalTimeout(60); 
  
  bool wifiConnected = wm.autoConnect("ABSENSI_CAM", "empirise123");

  if (wifiConnected) {
    wasWiFiConnected = true; 
    WiFi.setAutoReconnect(true); 
    
    tampilOled("SINKRON JAM", "Ambil Waktu NTP...");
    configTime(gmtOffset_sec, daylightOffset_sec, "pool.ntp.org", "time.nist.gov");
    
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo, 10000)) { 
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

  if (isSDCardReady) {
    muatDatabaseKeRAM();
  }

  tampilOled("KAMERA SETUP", "Memanaskan Lensa");
  delay(1000); 
  
  reader.setup();
  reader.begin();
  delay(1000); 

  // Inisialisasi ulang OLED setelah kamera menyala (menghindari bentrok I2C)
  Wire.begin(SDA_PIN, SCL_PIN);
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.setRotation(2);
  display.clearDisplay();
  display.setTextColor(WHITE);

  tampilOled("SIAP SCAN", isSDCardReady ? "Mode: Cepat (SD/RAM)" : "Mode: Online Direct");
}

// =======================================================================
// LOOP UTAMA KAMERA & WIFI CHECKER
// =======================================================================
void loop() {
  if (isSystemOn) {
    // ---> DETEKTOR WIFI PUTUS-NYAMBUNG <---
    if (millis() - lastWiFiCheck >= wifiCheckInterval) {
      lastWiFiCheck = millis();
      bool isConnectedNow = (WiFi.status() == WL_CONNECTED);

      if (isConnectedNow && !wasWiFiConnected) {
        tampilOled("WIFI KEMBALI", "Tunggu Jaringan\nStabil...");
        delay(4000); // Jeda stabilisasi koneksi
        
        kirimLogOfflineKeServer(); 
        wasWiFiConnected = true;
        tampilOled("SIAP SCAN", "Mode: Cepat (SD/RAM)");
      } 
      else if (!isConnectedNow && wasWiFiConnected) {
        tampilOled("WIFI PUTUS!", "Masuk Mode Offline");
        delay(1500);
        wasWiFiConnected = false;
        tampilOled("SIAP SCAN", "Mode: Offline AKTIF!");
      }
    }

    // ---> PEMROSESAN KAMERA <---
    struct QRCodeData qrCodeData;
    if (reader.receiveQrCode(&qrCodeData, 100)) {
      if (qrCodeData.valid) {
        String qrCode = (const char *)qrCodeData.payload;
        delay(200); 
        prosesAbsen(qrCode);
        delay(3000); 
        tampilOled("SIAP SCAN", wasWiFiConnected ? "Mode: Cepat (SD/RAM)" : "Mode: Offline AKTIF!");
      }
    }
    delay(10); 
  }
}

// =======================================================================
// VALIDASI ABSENSI & TOTP
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

  if (sudahAbsen[idPeserta]) {
    tampilOled("SUDAH ABSEN!", "Tidak Bisa 2x");
    return; 
  }

  time_t now;
  time(&now); 
  uint32_t unixTime = now; 
  
  if (unixTime < 1577836800) { 
    tampilOled("ERROR WAKTU", "NTP Belum Sinkron\nTethering HP Dulu!");
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
// PENCARIAN KUNCI PESERTA
// =======================================================================
String dapatkanSecret(String targetID) {
  if (databasePeserta.count(targetID) > 0) {
    return databasePeserta[targetID];
  }

  if (!isSDCardReady && WiFi.status() == WL_CONNECTED) {
    tampilOled("ONLINE CEK...", "Menghubungi Server");
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
// SIMPAN LOG SUPER AMAN (BYPASS BUG FILE_APPEND & RE-MOUNT)
// =======================================================================
void simpanLog(String idPeserta, String status) {
  bool terkirimOnline = false;
  bool berhasilDisimpan = false; 

  // 1. Coba kirim online
  if (WiFi.status() == WL_CONNECTED && status == "VALID") {
    HTTPClient http;
    http.begin(urlLog); 
    http.addHeader("Content-Type", "application/json");
    String payload = "{\"id_peserta\":\"" + idPeserta + "\"}";
    int responseCode = http.POST(payload);
    
    if(responseCode == 200 || responseCode == 201) {
       terkirimOnline = true; 
       berhasilDisimpan = true; 
    }
    http.end();
  }

  // 2. Simpan offline jika gagal online
  if (!terkirimOnline && isSDCardReady) {
    delay(200); // Beri nafas untuk modul SD Card paska pemrosesan kamera
    
    File file;
    
    // CEK DULU KEBERADAAN FILE (MENGHINDARI BUG FILE_APPEND ESP32)
    if (!SD_MMC.exists("/log_presensi.csv")) {
      file = SD_MMC.open("/log_presensi.csv", FILE_WRITE); 
    } else {
      file = SD_MMC.open("/log_presensi.csv", FILE_APPEND); 
    }

    // JURUS PAMUNGKAS: JIKA SD CARD MASIH TERTIDUR, KITA RE-MOUNT
    if (!file) {
      SD_MMC.end();                   // Matikan paksa modul SD Card
      delay(150);                     // Tunggu sebentar
      SD_MMC.begin("/sdcard", true);  // Nyalakan ulang SD Card
      
      // Coba buka lagi setelah di-restart
      if (!SD_MMC.exists("/log_presensi.csv")) {
        file = SD_MMC.open("/log_presensi.csv", FILE_WRITE); 
      } else {
        file = SD_MMC.open("/log_presensi.csv", FILE_APPEND); 
      }
    }

    // CEK AKHIR PENULISAN
    if (file) {
      file.print(idPeserta); file.print(",");
      file.print(status); file.print(",");
      file.println(getJamSekarang());
      file.close();
      
      berhasilDisimpan = true; 
      
      tampilOled("SD CARD OK!", "Tersimpan Offline\n" + idPeserta);
      delay(1500); 
    } else {
      tampilOled("SD ERROR!", "Gagal Nulis CSV");
      delay(2000);
    }
  }

  // 3. Kunci Double Scan HANYA jika data berhasil diselamatkan (Online/Offline)
  if (status == "VALID" && berhasilDisimpan) {
    sudahAbsen[idPeserta] = true; 
  }
}

// =======================================================================
// KIRIM LOG OFFLINE OTOMATIS
// =======================================================================
void kirimLogOfflineKeServer() {
  if (!isSDCardReady) return;

  File fileLog = SD_MMC.open("/log_presensi.csv", FILE_READ);
  
  if (!fileLog) {
    return; // File belum ada, aman
  }

  tampilOled("KIRIM LOG...", "Mengunggah...");
  int sukses = 0;
  int gagal = 0;

  File fileSisa = SD_MMC.open("/log_sisa.csv", FILE_WRITE);

  while (fileLog.available()) {
    String line = fileLog.readStringUntil('\n');
    line.trim();
    if (line.length() == 0) continue;

    int comma1 = line.indexOf(',');
    int comma2 = line.indexOf(',', comma1 + 1);

    if (comma1 != -1) {
      String idPeserta = line.substring(0, comma1);
      String status = (comma2 != -1) ? line.substring(comma1 + 1, comma2) : line.substring(comma1 + 1);

      idPeserta.trim(); 
      status.trim();

      if (status == "VALID") {
        HTTPClient http;
        http.begin(urlLog);
        http.addHeader("Content-Type", "application/json");
        String payload = "{\"id_peserta\":\"" + idPeserta + "\"}";
        
        int responseCode = http.POST(payload);
        http.end();

        if (responseCode == 200 || responseCode == 201) {
          sukses++;
        } else {
          gagal++;
          if (fileSisa) fileSisa.println(line); 
        }
      }
    }
  }
  
  fileLog.close();
  if (fileSisa) fileSisa.close();

  SD_MMC.remove("/log_presensi.csv");

  if (gagal > 0) {
    SD_MMC.rename("/log_sisa.csv", "/log_presensi.csv");
    tampilOled("UPLOAD SELESAI", String(sukses) + " Berhasil\n" + String(gagal) + " GAGAL!");
  } else {
    SD_MMC.remove("/log_sisa.csv");
    tampilOled("UPLOAD SUKSES!", String(sukses) + " Log Terkirim");
  }
  delay(3500);
}

// =======================================================================
// SINKRONISASI MASTER DATA
// =======================================================================
void syncData() {
  kirimLogOfflineKeServer(); 

  tampilOled("SINKRONISASI", "Unduh Data Server");
  delay(500);

  HTTPClient http;
  http.begin(urlSync);
  int httpCode = http.GET();
  
  if (httpCode == HTTP_CODE_OK) {
    sudahAbsen.clear();

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
// BACA SD CARD KE RAM
// =======================================================================
void muatDatabaseKeRAM() {
  databasePeserta.clear();
  if (!isSDCardReady) return;

  tampilOled("MEMUAT RAM", "Membaca SD Card...");

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

  sudahAbsen.clear();
  File fileLog = SD_MMC.open("/log_presensi.csv", FILE_READ);
  if (fileLog) {
    while (fileLog.available()) {
      String lineLog = fileLog.readStringUntil('\n');
      int firstComma = lineLog.indexOf(',');
      if (firstComma != -1) {
        String idLog = lineLog.substring(0, firstComma);
        idLog.trim();
        sudahAbsen[idLog] = true; 
      }
    }
    fileLog.close();
  }
  
  tampilOled("RAM SUKSES!", String(databasePeserta.size()) + " Peserta Siap");
  delay(1500);
}

// =======================================================================
// FUNGSI PENDUKUNG WAKTU & DECODE
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