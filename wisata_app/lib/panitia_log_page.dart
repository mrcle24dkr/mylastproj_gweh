// Lokasi: lib/panitia_log_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PanitiaLogPage extends StatefulWidget {
  const PanitiaLogPage({super.key});

  @override
  State<PanitiaLogPage> createState() => _PanitiaLogPageState();
}

class _PanitiaLogPageState extends State<PanitiaLogPage> {
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  // Fungsi menyedot data dari Server Golang
  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/logs');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _logs = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
         _showError('Gagal memuat data dari server');
      }
    } catch (e) {
      _showError('Tidak dapat terhubung ke server Golang');
    }
  }

  void _showError(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Pemotong teks waktu bawaan Golang (PostgreSQL) agar rapi (HH:MM:SS)
  String _formatWaktu(String rawTime) {
    try {
      DateTime waktu = DateTime.parse(rawTime).toLocal();
      return "${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}:${waktu.second.toString().padLeft(2, '0')}";
    } catch (e) {
      return rawTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Live Log Server Golang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                // Tombol Refresh Manual
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.red),
                  onPressed: _fetchLogs,
                )
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.red))
                : _logs.isEmpty
                    ? const Center(child: Text("Belum ada data presensi di Database"))
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final data = _logs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(Icons.check, color: Colors.white),
                              ),
                              title: Text(data['nama'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("ID: ${data['id_peserta']}"),
                              trailing: Text(_formatWaktu(data['waktu'] ?? ''), style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
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