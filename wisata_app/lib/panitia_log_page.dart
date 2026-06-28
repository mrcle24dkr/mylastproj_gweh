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
  // _logs akan menyimpan SEMUA data dari database
  List<dynamic> _logs = [];
  bool _isLoading = true;
  
  String _sesiAktif = "Pemberangkatan Awal"; 
  final List<String> _daftarSesi = [
    "Pemberangkatan Awal",
    "Makan Siang",
    "Kunjungan Industri",
    "Check-in Hotel",
    "Perjalanan Pulang"
  ];

  // ---> REVISI PENTING: Membuat fungsi filter dinamis <---
  // Fungsi ini hanya akan mengembalikan log yang nama_sesi-nya cocok dengan Dropdown
  List<dynamic> get _filteredLogs {
    return _logs.where((log) {
      final namaSesi = log['nama_sesi'] ?? 'Pemberangkatan Awal';
      return namaSesi == _sesiAktif;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchSesiAktif();
    _fetchLogs();
  }

  Future<void> _fetchSesiAktif() async {
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/panitia/sesi');
      final response = await http.get(url);
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _sesiAktif = json.decode(response.body)['sesi'] ?? "Pemberangkatan Awal";
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil sesi aktif: $e");
    }
  }

  Future<void> _ubahSesiAktif(String sesiBaru) async {
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/panitia/sesi');
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"sesi": sesiBaru}),
      );
      
      if (response.statusCode == 200 && mounted) {
        setState(() => _sesiAktif = sesiBaru);
        // Saat setState dipanggil, UI akan otomatis merender ulang menggunakan _filteredLogs yang baru
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sesi diubah ke: $sesiBaru"), backgroundColor: Colors.blue));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengubah sesi!"), backgroundColor: Colors.red));
    }
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
        content: const Text("Peserta ini akan bisa melakukan absen ulang di alat ESP32 untuk sesi ini."),
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
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 10, top: 20, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Log Presensi Server", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                Row(
                  children: [
                    // ---> REVISI: Angka Total sekarang membaca list yang sudah difilter <---
                    Text("Total: ${_filteredLogs.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    IconButton(icon: const Icon(Icons.refresh, color: Colors.blue), onPressed: _fetchLogs)
                  ],
                )
              ],
            ),
          ),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available, color: Colors.blue),
                const SizedBox(width: 15),
                const Expanded(
                  child: Text("Sesi Scanner Aktif :", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sesiAktif,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
                    items: _daftarSesi.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) _ubahSesiAktif(newValue);
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                // ---> REVISI: Render list UI menggunakan _filteredLogs <---
                : _filteredLogs.isEmpty
                    ? Center(child: Text("Belum ada data presensi untuk sesi $_sesiAktif", style: const TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _filteredLogs.length,
                        itemBuilder: (context, index) {
                          final data = _filteredLogs[index];
                          final namaSesi = data['nama_sesi'] ?? 'Pemberangkatan Awal';
                          
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: const CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(0xFF4CAF50), 
                                child: Icon(Icons.check, color: Colors.white, size: 28),
                              ),
                              title: Text(data['nama'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_formatWaktuLengkap(data['waktu'] ?? ''), style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                                      child: Text(namaSesi, style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
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