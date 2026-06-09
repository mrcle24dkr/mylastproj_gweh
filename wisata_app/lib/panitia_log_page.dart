// Lokasi File: lib/panitia_log_page.dart
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
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _logs = json.decode(response.body)['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _hapusLog(String idLog) async {
    bool? confirm = await showDialog<bool>(
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
    );

    if (confirm != true) return;

    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/logs/$idLog');
      final response = await http.delete(url);
      
      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Log dihapus!"), backgroundColor: Colors.green));
        _fetchLogs(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus log"), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Terjadi kesalahan jaringan"), backgroundColor: Colors.red));
    }
  }

  // TRANSLATE WAKTU MENJADI FORMAT SEPERTI DI DESAIN GAMBAR
  String _formatWaktuLengkap(String rawTime) {
    try {
      DateTime waktu = DateTime.parse(rawTime).toLocal();
      List<String> bulan = ["", "Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
      String pad(int n) => n.toString().padLeft(2, '0');
      return "${pad(waktu.day)} ${bulan[waktu.month]} ${waktu.year} - ${pad(waktu.hour)}:${pad(waktu.minute)} WIB";
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
          // HEADER SESUAI GAMBAR
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 10, top: 20, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Log Presensi Server Golang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                Row(
                  children: [
                    Text("Total: ${_logs.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    IconButton(icon: const Icon(Icons.refresh, color: Colors.blue), onPressed: _fetchLogs)
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                : _logs.isEmpty
                    ? const Center(child: Text("Belum ada data presensi", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final data = _logs[index];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: const CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(0xFF4CAF50), // Hijau sesuai gambar
                                child: Icon(Icons.check, color: Colors.white, size: 28),
                              ),
                              title: Text(data['nama'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(_formatWaktuLengkap(data['waktu'] ?? ''), style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _hapusLog(data['id_peserta'].toString()),
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