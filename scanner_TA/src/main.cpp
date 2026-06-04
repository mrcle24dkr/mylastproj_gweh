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
#include "RTClib.h"
#include "FS.h"
#include "SD_MMC.h"
#include "TOTP.h"
#include <map>

// --- KONFIGURASI PIN ---
#define SDA_PIN 12
#define SCL_PIN 13
// BUZZER TELAH DIHAPUS SEPENUHNYA

// --- OBJEK ---
Adafruit_SSD1306 display(128, 64, &Wire, -1);
RTC_DS3231 rtc;
ESP32QRCodeReader reader(CAMERA_MODEL_AI_THINKER);
WiFiManager wm;

// --- DATABASE RAM (Penyelamat ESP32) ---
std::map<String, String> databasePeserta;

// --- STATUS SISTEM ---
bool isSystemOn = true;
bool isSDCardReady = false;

// --- KONFIGURASI SERVER ---
const char* urlSync = "http://116.193.190.121:8080/api/sync-keys";
const char* urlPeserta = "http://116.193.190.121:8080/api/peserta/"; // API Untuk Online Direct

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
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0); // Matikan detektor drop voltase
  Serial.begin(115200);

  // 1. INISIALISASI OLED
  Wire.begin(SDA_PIN, SCL_PIN);
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) Serial.println("OLED Error");
  display.setRotation(2);
  display.clearDisplay();
  display.setTextColor(WHITE);

  tampilOled("BOOTING...", "Cek Hardware");
  delay(1000); // Waktu bernapas mesin

  // 2. CEK SD CARD
  if (!SD_MMC.begin("/sdcard", true) || SD_MMC.cardType() == CARD_NONE) {
    isSDCardReady = false;
    tampilOled("MODE ONLINE", "SD Card Dilepas/Rusak");
  } else {
    isSDCardReady = true;
    tampilOled("MODE HYBRID", "SD Card Terbaca");
  }
  delay(1500); // Waktu bernapas mesin

  // 3. CEK RTC
  if (!rtc.begin()) {
    tampilOled("ERROR RTC", "Cek Kabel I2C");
    delay(2000);
  } else if (rtc.lostPower()) {
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  }

  // 4. KONEKSI WIFI & SINKRONISASI (Jika Terhubung)
  tampilOled("WIFI SETUP", "Menghubungkan...");
  delay(500);
  wm.setConfigPortalTimeout(60);
  bool wifiConnected = wm.autoConnect("ABSENSI_CAM", "empirise123");

  if (wifiConnected) {
    if (isSDCardReady) {
      syncData(); // Unduh CSV ke SD Card
    }
  } else if (!isSDCardReady) {
    // Jika tidak ada WiFi dan tidak ada SD Card, alat lumpuh total
    tampilOled("FATAL ERROR", "No WiFi & No SD");
    while(true) { delay(1000); }
  }

  // 5. PINDAHKAN SELURUH DATA KE RAM (SUPER PENTING SEBELUM KAMERA NYALA)
  if (isSDCardReady) {
    muatDatabaseKeRAM();
  }

  // 6. SETUP KAMERA
  tampilOled("KAMERA SETUP", "Memanaskan Lensa");
  delay(1000); // WAKTU BERNAPAS PALING KRUSIAL SEBELUM TARIKAN ARUS BESAR
  
  reader.setup();
  reader.begin();
  delay(1000); // Biarkan kamera stabil

  // Bangunkan OLED lagi karena tarikan arus kamera kadang mereset jalur I2C
  Wire.begin(SDA_PIN, SCL_PIN);
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.setRotation(2);
  display.clearDisplay();
  display.setTextColor(WHITE);

  tampilOled("SIAP SCAN", isSDCardReady ? "Mode: Cepat (RAM)" : "Mode: Online Direct");
}


// =======================================================================
// LOOP KAMERA (BERSIH DARI SD CARD)
// =======================================================================
void loop() {
  if (isSystemOn) {
    struct QRCodeData qrCodeData;
    if (reader.receiveQrCode(&qrCodeData, 100)) {
      if (qrCodeData.valid) {
        String qrCode = (const char *)qrCodeData.payload;
        
        // Kasih jeda agar kamera berhenti menyedot data sesaat
        delay(200); 
        
        prosesAbsen(qrCode);

        delay(3000); // Tahan hasil scan di layar selama 3 detik sebelum lanjut
        tampilOled("SIAP SCAN", isSDCardReady ? "Mode: Cepat (RAM)" : "Mode: Online Direct");
      }
    }
    delay(10); 
  }
}


// =======================================================================
// LOGIKA PEMROSESAN ABSEN
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
  delay(300); // Waktu bernapas OLED

  // Ambil Secret (Bisa dari RAM, atau tembak API langsung jika Online Direct)
  String secretKey = dapatkanSecret(idPeserta);
  
  if (secretKey == "") {
    tampilOled("GAGAL!", "ID Tidak Dikenal");
    simpanLog(idPeserta, "GAGAL_UNREGISTERED");
    return;
  }

  uint32_t unixTime = rtc.now().unixtime();
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
// FUNGSI PENCARIAN KUNCI (HYBRID: RAM -> API ONLINE)
// =======================================================================
String dapatkanSecret(String targetID) {
  // 1. CARA TERCEPAT: Cari di memori RAM internal (Jika SD Card dipakai)
  if (databasePeserta.count(targetID) > 0) {
    return databasePeserta[targetID];
  }

  // 2. SKENARIO ONLINE DIRECT: Jika SD Card dilepas/rusak, langsung tanya ke Server Golang!
  if (!isSDCardReady && WiFi.status() == WL_CONNECTED) {
    tampilOled("ONLINE CEK...", "Menghubungi Server");
    delay(100);

    HTTPClient http;
    http.begin(String(urlPeserta) + targetID);
    int httpCode = http.GET();
    String secret = "";

    if (httpCode == HTTP_CODE_OK) {
      String payload = http.getString();
      
      // Ambil kunci rahasia langsung dari respon JSON API Flutter-mu
      int keyIndex = payload.indexOf("\"QRSecretKey\":\"");
      if(keyIndex == -1) keyIndex = payload.indexOf("\"qr_secret_key\":\""); // Coba format lain jika ada

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
    return secret; // Kembalikan kunci dari hasil download langsung
  }

  // Jika di RAM tidak ada, dan tidak ada internet
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
      
      // Bersihkan karakter aneh enter
      id.replace("\r", "");
      key.replace("\r", "");
      
      databasePeserta[id] = key; // Masukkan ke wadah RAM
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
// FUNGSI PENDUKUNG (LOG, WAKTU, DECODE, OLED)
// =======================================================================
void simpanLog(String idPeserta, String status) {
  if (!isSDCardReady) {
    // Mode Online Direct aktif = Lewati simpan log fisik
    return;
  }
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

void getJamSekarang(char* buffer, size_t maxLen) {
  DateTime now = rtc.now();
  snprintf(buffer, maxLen, "%02d-%02d-%04d %02d:%02d:%02d", 
           now.day(), now.month(), now.year(), 
           now.hour(), now.minute(), now.second());
}

String getJamSekarang() {
  char buffer[20];
  getJamSekarang(buffer, sizeof(buffer));
  return String(buffer);
}

void tampilOled(String a, String b) {
  display.clearDisplay();
  display.setCursor(0,0); display.setTextSize(1);
  display.println(a);
  display.setCursor(0,20);
  display.println(b);
  display.display();
}