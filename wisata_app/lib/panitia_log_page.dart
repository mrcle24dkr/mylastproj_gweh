// Lokasi: lib/panitia_log_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';

class PanitiaLogPage extends StatefulWidget {
  const PanitiaLogPage({super.key});

  @override
  State<PanitiaLogPage> createState() => _PanitiaLogPageState();
}

class _PanitiaLogPageState extends State<PanitiaLogPage> {
  final Query _logsRef = FirebaseDatabase.instance.ref().child('logs').orderByKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Live Log ESP32-CAM", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: FirebaseAnimatedList(
              query: _logsRef,
              sort: (a, b) => b.key!.compareTo(a.key!), // Urutkan dari terbaru
              defaultChild: const Center(child: CircularProgressIndicator(color: Colors.red)),
              itemBuilder: (context, snapshot, animation, index) {
                Map data = snapshot.value as Map;
                DateTime waktu = DateTime.fromMillisecondsSinceEpoch(int.parse(snapshot.key.toString()));
                String formatWaktu = "${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}:${waktu.second.toString().padLeft(2, '0')}";

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                    title: Text(data['nama'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("ID: ${data['qr']}"),
                    trailing: Text(formatWaktu, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Tombol Backup Scan via HP
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigasi ke halaman kamera HP untuk scan manual
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Membuka Kamera HP... (Coming Soon)")),
          );
        },
        backgroundColor: Colors.red[800],
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text("Scan Manual", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}