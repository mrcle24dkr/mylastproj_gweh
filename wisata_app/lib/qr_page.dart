// Lokasi File: lib/qr_page.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
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
    // Tarik data dari Golang saat halaman pertama kali dibuka
    fetchDataPeserta();
  }

  // Fungsi menembak API Golang menggunakan idPeserta yang dinamis
  Future<void> fetchDataPeserta() async {
    try {
      // Perhatikan: URL sekarang menggunakan widget.idPeserta
      final url = Uri.parse('http://116.193.190.121:8080/api/sync-keys${widget.idPeserta}');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          secretKey = data['QRSecretKey'];
          namaPeserta = data['NamaLengkap'];
        });
        
        generateTOTP(); // Panggil racikan pertama
        
        // Mulai timer berdetak setiap 1 detik
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          generateTOTP();
        });
      } else {
        setState(() {
          namaPeserta = "Data peserta tidak ditemukan";
        });
      }
    } catch (e) {
      setState(() {
        namaPeserta = "Gagal terhubung ke Server";
      });
    }
  }

  // Fungsi meracik QR Code dinamis
  void generateTOTP() {
    if (secretKey.isNotEmpty) {
      final payload = TotpService.generatePayloadQR(widget.idPeserta, secretKey);

      if (currentTOTP != payload) {
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
        // Tampilkan loading jika kunci belum didapat dari Golang
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
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: currentTOTP, // Data ini berisi 6 digit angka TOTP
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