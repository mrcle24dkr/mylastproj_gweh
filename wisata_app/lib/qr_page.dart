// Lokasi File: lib/qr_page.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; // ---> IMPORT DITAMBAHKAN
import 'services/totp_service.dart';

class QrPage extends StatefulWidget {
  final String idPeserta;
  const QrPage({super.key, required this.idPeserta});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  Timer? _timer;
  String secretKey = "";
  String currentTOTP = "";
  String namaPeserta = "Memuat data...";

  @override
  void initState() {
    super.initState();
    // 1. Jalankan inisialisasi offline terlebih dahulu
    _inisialisasiDataOffline();
  }

  // ---> FUNGSI INTI OFFLINE DITAMBAHKAN <---
  Future<void> _inisialisasiDataOffline() async {
    final prefs = await SharedPreferences.getInstance();

    // Coba baca data dari memori lokal (Mode Offline)
    String savedKey = prefs.getString('qr_secret_key_${widget.idPeserta}') ?? "";
    String savedNama = prefs.getString('nama_peserta_${widget.idPeserta}') ?? "Memuat data...";

    if (savedKey.isNotEmpty) {
      if (mounted) {
        setState(() {
          secretKey = savedKey;
          if (savedNama != "Memuat data...") {
            namaPeserta = savedNama;
          }
        });
      }
      _mulaiTimer(); // Langsung jalankan mesin QR pakai data offline!
    }

    // 2. Walaupun sudah dapat dari memori, tetap coba sedot dari Golang
    // secara diam-diam untuk sinkronisasi (Background Sync)
    _fetchDataPeserta(prefs);
  }

  // Fungsi menembak API Golang yang sudah dimodifikasi
  Future<void> _fetchDataPeserta(SharedPreferences prefs) async {
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/peserta/${widget.idPeserta}');
      
      // Kasih batas waktu 5 detik agar tidak nyangkut jika sedang tidak ada sinyal
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        
        String fetchedKey = data['qr_secret_key'] ?? data['QRSecretKey'] ?? '';
        String fetchedNama = data['nama_lengkap'] ?? data['NamaLengkap'] ?? 'Unknown';

        if (fetchedKey.isNotEmpty) {
          // Simpan pembaruan ke memori HP
          await prefs.setString('qr_secret_key_${widget.idPeserta}', fetchedKey);
          await prefs.setString('nama_peserta_${widget.idPeserta}', fetchedNama);

          if (mounted) {
            setState(() {
              secretKey = fetchedKey;
              namaPeserta = fetchedNama;
            });

            // Jika sebelumnya HP belum punya memori (timer belum jalan), nyalakan sekarang
            if (_timer == null || !_timer!.isActive) {
              _mulaiTimer();
            }
          }
        }
      } else if (secretKey.isEmpty) {
        // Hanya tampilkan error 404 jika memang belum punya cache sama sekali
        if (mounted) {
          setState(() {
            namaPeserta = "Data peserta tidak ditemukan (404)";
          });
        }
      }
    } catch (e) {
      // Jika error (karena benar-benar di blank spot), sistem akan diam saja
      // dan tetap membiarkan QR Code menyala menggunakan data dari memori.
      debugPrint("Sistem Offline aktif. Mengandalkan memori lokal. Info: $e"); 
      
      if (secretKey.isEmpty && mounted) {
        setState(() {
          namaPeserta = "Hubungkan ke internet untuk pertama kali.";
        });
      }
    }
  }

  // Fungsi menyalakan detak jantung aplikasi
  void _mulaiTimer() {
    generateTOTP(); // Panggil racikan pertama
    
    _timer?.cancel(); // Pastikan tidak ada timer ganda yang berjalan
    // Mulai timer berdetak setiap 1 detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      generateTOTP();
    });
  }

  // Fungsi meracik QR Code dinamis (TIDAK BERUBAH)
  void generateTOTP() {
    if (secretKey.isNotEmpty) {
      final payload = TotpService.generatePayloadQR(widget.idPeserta, secretKey);

      if (currentTOTP != payload && mounted) {
        setState(() {
          currentTOTP = payload;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        // Tampilkan loading HANYA JIKA kunci belum didapat dari Golang DAN belum ada di memori
        child: secretKey.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.red),
                  const SizedBox(height: 20),
                  Text(namaPeserta, style: const TextStyle(color: Colors.grey)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("QR CODE", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 5),
                  Text("Halo, $namaPeserta", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  const Text("Tunjukkan QR Code ini kepada panitia"),
                  const SizedBox(height: 40),
                  
                  // Kotak QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: currentTOTP, // Data ini berisi format dari TotpService
                      version: QrVersions.auto,
                      size: 250.0,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  Text("ID: ${widget.idPeserta}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  const Text("QR berubah otomatis setiap 30 detik", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(
                    "Kode Aktif: ${currentTOTP.contains(':') ? currentTOTP.split(':')[1] : '...'}", 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.red)
                  ),
                ],
              ),
      ),
    );
  }
}