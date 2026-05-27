import 'package:otp/otp.dart';

class TotpService {
  // 1. Tambahkan parameter (String dynamicSecretKey) di sini
  static String generateCurrentOTP(String dynamicSecretKey) {
    if (dynamicSecretKey.isEmpty) return "";
    
    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    
    return OTP.generateTOTPCodeString(
      dynamicSecretKey, 
      currentTime, 
      algorithm: Algorithm.SHA1,
      interval: 30,
      length: 6,
      isGoogle: true 
    );
  }
  
  // 2. Tambahkan parameter (String dynamicSecretKey) juga di sini
  static String generatePayloadQR(String idPeserta, String dynamicSecretKey) {
    // Lempar kuncinya ke fungsi di atas
    String kodeAktual = generateCurrentOTP(dynamicSecretKey);
    if (kodeAktual.isEmpty) return "";
    
    return "$idPeserta:$kodeAktual"; 
  }
}