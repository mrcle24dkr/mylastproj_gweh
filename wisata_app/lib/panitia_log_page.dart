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

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/logs');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _logs = json.decode(response.body)['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // FUNSI BARU: Hapus Log
  Future<void> _hapusLog(String idLog) async {
    // Tampilkan Dialog Konfirmasi
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Log?"),
        content: const Text("Peserta ini akan bisa melakukan absen ulang di alat ESP32 jika alat disinkronisasi ulang."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Hapus", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Tembak API DELETE
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/logs/$idLog');
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Log dihapus!"), backgroundColor: Colors.green),
        );
        _fetchLogs(); // Refresh daftar setelah dihapus
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menghapus log"), backgroundColor: Colors.red),
      );
    }
  }

  String _formatWaktu(String rawTime) {
    try {
      DateTime waktu = DateTime.parse(rawTime).toLocal();
      return "${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}";
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
                IconButton(icon: const Icon(Icons.refresh, color: Colors.red), onPressed: _fetchLogs)
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.red))
                : _logs.isEmpty
                    ? const Center(child: Text("Belum ada data presensi"))
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final data = _logs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
                              title: Text(data['nama'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("ID: ${data['id_peserta']}"),
                              // Tambahan Tombol Hapus di Kanan
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_formatWaktu(data['waktu'] ?? ''), style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _hapusLog(data['id'].toString()),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}