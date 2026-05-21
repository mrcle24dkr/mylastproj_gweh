// Lokasi File: lib/services/location_service.dart
import 'dart:math' show cos, sqrt, asin;

class LocationService {
  // Fungsi menghitung jarak (Haversine) sesuai Bab 4.3.4.2
  static double hitungJarakHaversine(double latPeserta, double lonPeserta, double latPos, double lonPos) {
    var p = 0.017453292519943295; // Nilai dari Pi / 180
    var c = cos;
    
    // Rumus matematika kelengkungan bumi (Haversine)
    var a = 0.5 -
        c((latPos - latPeserta) * p) / 2 +
        c(latPeserta * p) * c(latPos * p) *
        (1 - c((lonPos - lonPeserta) * p)) / 2;
        
    double radiusBumi = 6371.0; // Radius bumi dalam satuan Kilometer
    double jarakKm = 2 * radiusBumi * asin(sqrt(a));
    
    return jarakKm * 1000; // Konversi hasil ke satuan Meter
  }

  // Fungsi memvalidasi status keamanan peserta
  static String cekStatusGeofence(double jarakMeter, double radiusAman) {
    if (jarakMeter <= radiusAman) {
      return "AMAN";
    } else {
      return "LUAR BATAS";
    }
  }
}