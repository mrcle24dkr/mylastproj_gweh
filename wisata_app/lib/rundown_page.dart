// Lokasi File: lib/rundown_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RundownPage extends StatefulWidget {
  const RundownPage({super.key});

  @override
  State<RundownPage> createState() => _RundownPageState();
}

class _RundownPageState extends State<RundownPage> {
  List<dynamic> _rundownList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRundown();
  }

  Future<void> _fetchRundown() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/rundown');
      final response = await http.get(url);
      if (mounted && response.statusCode == 200) {
        setState(() {
          _rundownList = json.decode(response.body)['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Jadwal Perjalanan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.blue), onPressed: _fetchRundown)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rundownList.isEmpty
              ? const Center(child: Text("Jadwal belum tersedia"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rundownList.length,
                  itemBuilder: (context, index) {
                    final data = _rundownList[index];
                    final bool isLast = index == _rundownList.length - 1;
                    final bool perluPresensi = data['perlu_presensi'] ?? false;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 30,
                            child: Column(
                              children: [
                                Container(
                                  width: 15, height: 15,
                                  decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.blue.shade100, width: 3)),
                                ),
                                if (!isLast)
                                  Expanded(child: Container(width: 2, color: Colors.blue.shade200)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: perluPresensi ? Colors.blue.shade50 : Colors.grey.shade100, 
                                  borderRadius: BorderRadius.circular(12),
                                  border: perluPresensi ? Border.all(color: Colors.blue.shade200) : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['waktu'] ?? '', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 5),
                                    Text(data['kegiatan'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(data['lokasi'] ?? '', style: const TextStyle(color: Colors.grey))),
                                      ],
                                    ),
                                    // ---> TAMBAHAN BADGE PRESENSI <---
                                    if (perluPresensi)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(6)),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.qr_code_scanner, color: Colors.white, size: 12),
                                            SizedBox(width: 4),
                                            Text("Siapkan Tiket QR", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}