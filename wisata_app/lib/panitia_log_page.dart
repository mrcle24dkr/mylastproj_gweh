// Lokasi File: lib/panitia_log_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'panitia_map_page.dart'; // Import halaman map panitia

class PanitiaLogPage extends StatefulWidget {
  const PanitiaLogPage({super.key});

  @override
  State<PanitiaLogPage> createState() => _PanitiaLogPageState();
}

class _PanitiaLogPageState extends State<PanitiaLogPage> {
  List<dynamic> _logs = [];
  List<dynamic> _masterPeserta = []; // Menyimpan semua peserta terdaftar
  bool _isLoading = true;
  
  String _sesiAktif = "Belum Ada Jadwal Presensi"; 
  
  // ---> REVISI: Daftar sesi tidak lagi hardcode, akan diisi dari API Rundown <---
  List<String> _daftarSesi = ["Belum Ada Jadwal Presensi"];

  // VARIABEL UNTUK FILTER & SORTING
  String _filterStatus = 'Semua'; 
  String _sortBy = 'Waktu Terbaru'; 

  @override
  void initState() {
    super.initState();
    _muatDataAwal();
  }

  Future<void> _muatDataAwal() async {
    setState(() => _isLoading = true);
    await _fetchDaftarSesiRundown(); // ---> Panggil API Rundown terlebih dahulu
    await _fetchSesiAktif();
    await _fetchMasterPeserta();
    await _fetchLogs();
  }

  // ---> FITUR BARU: Ambil daftar sesi dari Rundown API <---
  Future<void> _fetchDaftarSesiRundown() async {
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/rundown');
      final response = await http.get(url);
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(response.body)['data'] ?? [];
        
        // Filter hanya kegiatan yang perlu_presensi == true
        List<String> sesiDariRundown = data
            .where((item) => item['perlu_presensi'] == true)
            .map((item) => item['kegiatan'].toString())
            .toList();

        setState(() {
          if (sesiDariRundown.isNotEmpty) {
            _daftarSesi = sesiDariRundown;
          } else {
            _daftarSesi = ["Belum Ada Jadwal Presensi"];
            _sesiAktif = "Belum Ada Jadwal Presensi";
          }
        });
      }
    } catch (e) {
      debugPrint("Gagal menarik daftar sesi rundown: $e");
    }
  }

  Future<void> _fetchSesiAktif() async {
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/panitia/sesi');
      final response = await http.get(url);
      if (response.statusCode == 200 && mounted) {
        String sesiDariServer = json.decode(response.body)['sesi'] ?? "Pemberangkatan Awal";
        
        setState(() {
          // Validasi: Jika sesi dari server ternyata tidak ada di jadwal rundown saat ini,
          // kembalikan ke jadwal pertama yang ada di list, atau biarkan kosong.
          if (!_daftarSesi.contains(sesiDariServer)) {
            _sesiAktif = _daftarSesi.isNotEmpty ? _daftarSesi.first : "Belum Ada Jadwal Presensi";
          } else {
            _sesiAktif = sesiDariServer;
          }
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil sesi aktif");
    }
  }

  // Tarik data SEMUA peserta dari Master Data
  Future<void> _fetchMasterPeserta() async {
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/panitia/peserta');
      final response = await http.get(url);
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _masterPeserta = json.decode(response.body)['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Gagal menarik master peserta: $e");
    }
  }

  Future<void> _fetchLogs() async {
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/logs');
      final response = await http.get(url);
      if (mounted) {
        setState(() {
          _logs = response.statusCode == 200 ? (json.decode(response.body)['data'] ?? []) : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ubahSesiAktif(String sesiBaru) async {
    // Jika tidak ada jadwal presensi, batalkan fungsi
    if (sesiBaru == "Belum Ada Jadwal Presensi") return;

    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/panitia/sesi');
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"sesi": sesiBaru}),
      );
      
      if (response.statusCode == 200 && mounted) {
        setState(() => _sesiAktif = sesiBaru);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sesi diubah ke: $sesiBaru"), backgroundColor: Colors.blue));
        _fetchLogs(); // Ambil log ulang pas sesi diganti
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengubah sesi!"), backgroundColor: Colors.red));
    }
  }

  Future<void> _presensiManual(String idPeserta, String nama) async {
    if (_sesiAktif == "Belum Ada Jadwal Presensi") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Buat jadwal presensi terlebih dahulu di menu Rundown!"), backgroundColor: Colors.orange));
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Presensi Manual"),
        content: Text("Apakah Anda yakin ingin menandai Hadir untuk $nama ($idPeserta)?\n\nGunakan ini jika perangkat peserta bermasalah (mati/habis baterai)."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Ya, Hadir", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/logs');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"id_peserta": idPeserta}),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Berhasil melakukan presensi manual untuk $nama!"), backgroundColor: Colors.green)
        );
        _muatDataAwal(); 
      } else {
        final errorMsg = json.decode(response.body)['message'] ?? "Gagal memproses";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $errorMsg"), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Terjadi kesalahan jaringan"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _hapusLog(String idPeserta) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Batalkan Absen?"),
        content: const Text("Peserta akan diubah menjadi 'Belum Absen' untuk sesi ini."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Ya, Batalkan", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/logs/$idPeserta');
      final response = await http.delete(url);
      
      if (mounted && response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Absen dibatalkan!"), backgroundColor: Colors.orange));
        _muatDataAwal(); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Terjadi kesalahan jaringan"), backgroundColor: Colors.red));
    }
  }

  String _formatWaktuLengkap(String rawTime) {
    if (rawTime.isEmpty) return "-";
    try {
      DateTime waktu = DateTime.parse(rawTime).toLocal();
      List<String> bulan = ["", "Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Ags", "Sep", "Okt", "Nov", "Des"];
      String pad(int n) => n.toString().padLeft(2, '0');
      return "${pad(waktu.day)} ${bulan[waktu.month]} - ${pad(waktu.hour)}:${pad(waktu.minute)} WIB";
    } catch (e) {
      return rawTime;
    }
  }

  List<Map<String, dynamic>> get _processedData {
    List<Map<String, dynamic>> combinedList = [];

    // 1. GABUNGKAN MASTER PESERTA DENGAN LOG ABSENSI
    for (var peserta in _masterPeserta) {
      String idPeserta = peserta['IDPeserta'].toString();
      String namaLengkap = peserta['NamaLengkap'] ?? 'Unknown';
      
      var logAktif = _logs.cast<Map<String, dynamic>>().firstWhere(
        (log) => log['id_peserta'] == idPeserta && (log['nama_sesi'] ?? '') == _sesiAktif,
        orElse: () => <String, dynamic>{},
      );

      bool sudahAbsen = logAktif.isNotEmpty;

      combinedList.add({
        'id_peserta': idPeserta,
        'nama': namaLengkap,
        'sudah_absen': sudahAbsen,
        'waktu': sudahAbsen ? logAktif['waktu'] : null,
      });
    }

    // 2. FILTERING DATA
    if (_filterStatus == 'Sudah Absen') {
      combinedList.retainWhere((item) => item['sudah_absen'] == true);
    } else if (_filterStatus == 'Belum Absen') {
      combinedList.retainWhere((item) => item['sudah_absen'] == false);
    }

    // 3. SORTING DATA
    combinedList.sort((a, b) {
      if (_sortBy == 'Waktu Terbaru') {
        if (a['waktu'] == null && b['waktu'] == null) return a['nama'].compareTo(b['nama']);
        if (a['waktu'] == null) return 1;
        if (b['waktu'] == null) return -1;
        return DateTime.parse(b['waktu']).compareTo(DateTime.parse(a['waktu']));
      } else if (_sortBy == 'Nama (A-Z)') {
        return a['nama'].toString().compareTo(b['nama'].toString());
      } else if (_sortBy == 'Nama (Z-A)') {
        return b['nama'].toString().compareTo(a['nama'].toString());
      }
      return 0;
    });

    return combinedList;
  }

  @override
  Widget build(BuildContext context) {
    final dataTampil = _processedData;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 10, top: 20, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Log Presensi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                Row(
                  children: [
                    Text("Total: ${dataTampil.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    IconButton(icon: const Icon(Icons.refresh, color: Colors.blue), onPressed: _muatDataAwal)
                  ],
                )
              ],
            ),
          ),
          
          // CARD SESI AKTIF
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available, color: Colors.blue),
                const SizedBox(width: 10),
                const Expanded(child: Text("Sesi Active:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13))),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sesiAktif,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                    items: _daftarSesi.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) _ubahSesiAktif(newValue);
                    },
                  ),
                ),
              ],
            ),
          ),

          // BARIS FILTER & SORTING
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _filterStatus,
                        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                        items: ['Semua', 'Sudah Absen', 'Belum Absen'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                        onChanged: (String? newValue) => setState(() => _filterStatus = newValue!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _sortBy,
                        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                        items: ['Waktu Terbaru', 'Nama (A-Z)', 'Nama (Z-A)'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                        onChanged: (String? newValue) => setState(() => _sortBy = newValue!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // LISTVIEW DATA PESERTA
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                : dataTampil.isEmpty
                    ? const Center(child: Text("Tidak ada data yang cocok", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: dataTampil.length,
                        itemBuilder: (context, index) {
                          final data = dataTampil[index];
                          final bool isHadir = data['sudah_absen'];
                          
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: isHadir ? const Color(0xFF4CAF50) : const Color(0xFFF44336), 
                                child: Icon(isHadir ? Icons.check : Icons.close, color: Colors.white, size: 24),
                              ),
                              title: Text(data['nama'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  isHadir ? _formatWaktuLengkap(data['waktu']) : 'Belum Melakukan Presensi', 
                                  style: TextStyle(
                                    color: isHadir ? Colors.grey[700] : Colors.red[300], 
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 12
                                  )
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // SHORTCUT MAPS
                                  IconButton(
                                    icon: const Icon(Icons.map, color: Colors.blue),
                                    tooltip: "Lacak Posisi",
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mencari lokasi ${data['nama']}...")));
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PanitiaMapPage()));
                                    },
                                  ),
                                  
                                  // LOGIKA TOMBOL BERDASARKAN STATUS ABSENSI
                                  if (!isHadir) 
                                    IconButton(
                                      icon: const Icon(Icons.check_box_outlined, color: Colors.green),
                                      tooltip: "Presensi Manual",
                                      onPressed: () => _presensiManual(data['id_peserta'], data['nama']),
                                    ),
                                  if (isHadir) 
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: "Batalkan Absen",
                                      onPressed: () => _hapusLog(data['id_peserta']), 
                                    ),
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