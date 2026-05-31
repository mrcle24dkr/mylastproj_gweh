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

// --- KONFIGURASI PIN ---
#define SDA_PIN 12
#define SCL_PIN 13
#define BUZZER_PIN 4

// --- OBJEK ---
Adafruit_SSD1306 display(128, 64, &Wire, -1);
RTC_DS3231 rtc;
ESP32QRCodeReader reader(CAMERA_MODEL_AI_THINKER);
WiFiManager wm;

// --- STATUS SISTEM ---
bool isSystemOn = true;       
bool isSDCardReady = false; 

// --- KONFIGURASI SERVER ---
const char* urlSync = "http://116.193.190.121:8080/api/sync-keys"; 

// --- DEKLARASI FUNGSI ---
void tampilOled(String a, String b);
String getJamSekarang();
void syncData();
String dapatkanSecret(String idPeserta);
void simpanLog(String idPeserta, String status);
void prosesAbsen(String qr);
void beep(int durasi);
int decodeBase32(const char* encoded, uint8_t* decoded); 

void setup() {
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0); 
  Serial.begin(115200);
  
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW); 

  Wire.begin(SDA_PIN, SCL_PIN);
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) Serial.println("OLED Error"); 
  display.setRotation(2); 
  display.clearDisplay();
  display.setTextColor(WHITE);
  
  tampilOled("BOOTING...", "Cek SD Card");
  delay(1000);

  // 1. CEK SD CARD (Mode 1-Bit)
  if (!SD_MMC.begin("/sdcard", true) || SD_MMC.cardType() == CARD_NONE) {
    isSDCardReady = false;
    tampilOled("MODE ONLINE", "SD Card Gagal");
  } else {
    isSDCardReady = true;
    tampilOled("MODE HYBRID", "SD Card Aktif");
  }
  delay(1500);

  // 2. CEK RTC
  if (!rtc.begin()) {
    tampilOled("ERROR RTC", "Cek Kabel I2C");
    delay(2000);
  } else if (rtc.lostPower()) {
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  }

  // 3. KONEKSI WIFI & SINKRONISASI
  tampilOled("WIFI SETUP", "Menghubungkan...");
  wm.setConfigPortalTimeout(60); 
  if (wm.autoConnect("ABSENSI_CAM", "empirise123")) {
    if (isSDCardReady) syncData();
  } else if (!isSDCardReady) {
    tampilOled("FATAL ERROR", "No WiFi & No SD");
    while(true); 
  }

  // 4. SETUP KAMERA
  tampilOled("KAMERA SETUP", "Memanaskan Lensa");
  reader.setup(); 
  reader.begin();
  
  // Bangunkan OLED
  delay(100); 
  Wire.begin(SDA_PIN, SCL_PIN);
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.setRotation(2);
  display.clearDisplay();
  display.setTextColor(WHITE);

  tampilOled("SIAP SCAN", isSDCardReady ? "Store & Forward" : "Online Direct");
}

void loop() {
  // --- LOGIKA SCANNING MURNI ---
  if (isSystemOn) {
    struct QRCodeData qrCodeData;
    if (reader.receiveQrCode(&qrCodeData, 100)) {
      if (qrCodeData.valid) {
        String qrCode = (const char *)qrCodeData.payload;
        Serial.println("QR DITEMUKAN: " + qrCode);
        prosesAbsen(qrCode);
        delay(2000); 
        tampilOled("SIAP SCAN", isSDCardReady ? "Store & Forward" : "Online Direct");
      }
    }
    delay(10); 
  }
}

void syncData() {
  tampilOled("SINKRONISASI", "Unduh Data CSV...");
  HTTPClient http;
  http.begin(urlSync);
  int httpCode = http.GET();
  
  if (httpCode == HTTP_CODE_OK) {
    File file = SD_MMC.open("/database_peserta.csv", FILE_WRITE);
    if (file) {
      http.writeToStream(&file); 
      file.close();
      tampilOled("SINKRON SUKSES", "Kunci Diperbarui");
      beep(200); delay(100); beep(200); 
    }
  } else {
    tampilOled("SINKRON GAGAL", "Server Down/Error");
    beep(1000); 
  }
  http.end();
  delay(2000);
}

void prosesAbsen(String qr) {
  int separatorIndex = qr.indexOf(':');
  if (separatorIndex == -1) {
    tampilOled("GAGAL!", "Format QR Salah");
    beep(1000);
    return;
  }
  
  String idPeserta = qr.substring(0, separatorIndex);
  String otpMasuk = qr.substring(separatorIndex + 1);
  tampilOled("Cek Data...", idPeserta);

  String secretKey = dapatkanSecret(idPeserta);
  if (secretKey == "") {
    tampilOled("GAGAL!", "ID Tidak Dikenal");
    simpanLog(idPeserta, "GAGAL_UNREGISTERED");
    beep(1000);
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
    beep(200); 
  } else {
    tampilOled("KADALUARSA!", "QR Sudah Usang");
    simpanLog(idPeserta, "GAGAL_EXPIRED");
    beep(1000); 
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

String dapatkanSecret(String targetID) {
  if (!isSDCardReady) return "";
  File file = SD_MMC.open("/database_peserta.csv", FILE_READ);
  if (!file) return "";
  while (file.available()) {
    String line = file.readStringUntil('\n');
    line.trim();
    if (line.startsWith(targetID)) {
      int commaIndex = line.indexOf(',');
      if (commaIndex != -1) {
        file.close();
        return line.substring(commaIndex + 1); 
      }
    }
  }
  file.close();
  return ""; 
}

void simpanLog(String idPeserta, String status) {
  if (!isSDCardReady) return;
  File file = SD_MMC.open("/log_presensi.csv", FILE_APPEND);
  if (file) {
    file.print(idPeserta);
    file.print(",");
    file.print(status);
    file.print(",");
    file.println(getJamSekarang());
    file.close();
  }
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

void beep(int durasi) {
  digitalWrite(BUZZER_PIN, HIGH);
  delay(durasi);
  digitalWrite(BUZZER_PIN, LOW);
}