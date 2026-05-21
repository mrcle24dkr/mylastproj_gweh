// Lokasi File: lib/services/totp_service.dart
import 'package:otp/otp.dart';

class TotpService {
  // Secret Key ini HARUS SAMA dengan hmackey di kode C++ ESP32 Anda!
  static const String secretKeyBase32 = "JBSWY3DPEHPK3PXP"; 

  static String generateCurrentOTP() {
    // Ambil waktu saat ini dalam format milidetik (Epoch time)
    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // Generate TOTP (Algoritma SHA1, 6 digit, interval 30 detik)
    return OTP.generateTOTPCodeString(
      secretKeyBase32, 
      currentTime, 
      algorithm: Algorithm.SHA1,
      interval: 30,
      length: 6
    );
  }
  
  static String generatePayloadQR(String idPeserta) {
    String kodeAktual = generateCurrentOTP();
    return "$idPeserta:$kodeAktual";
  }
}