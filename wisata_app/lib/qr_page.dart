// Lokasi File: lib/qr_page.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'services/totp_service.dart';

class QrPage extends StatefulWidget {
  final String idPeserta;
  const QrPage({super.key, required this.idPeserta});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  late Timer _timer;
  String _qrPayload = "";

  @override
  void initState() {
    super.initState();
    _updateQrPayload();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateQrPayload();
    });
  }

  void _updateQrPayload() {
    setState(() {
      _qrPayload = TotpService.generatePayloadQR(widget.idPeserta);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("QR CODE", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 10),
            const Text("Tunjukkan QR Code ini kepada panitia"),
            const SizedBox(height: 40),
            QrImageView(
              data: _qrPayload,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 40),
            Text("ID: ${widget.idPeserta}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            const Text("QR berubah otomatis setiap 30 detik", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}