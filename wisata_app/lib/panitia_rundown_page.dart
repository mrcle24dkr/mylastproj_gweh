// Lokasi File: lib/panitia_rundown_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PanitiaRundownPage extends StatefulWidget {
  const PanitiaRundownPage({super.key});

  @override
  State<PanitiaRundownPage> createState() => _PanitiaRundownPageState();
}

class _PanitiaRundownPageState extends State<PanitiaRundownPage> {
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

  Future<void> _hapusRundown(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Jadwal?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    final url = Uri.parse('http://116.193.190.121:8080/api/panitia/rundown/$id');
    await http.delete(url);
    _fetchRundown();
  }

  void _tampilkanFormDialog({Map<String, dynamic>? dataEdit}) {
    final bool isEdit = dataEdit != null;
    final waktuCtrl = TextEditingController(text: isEdit ? dataEdit['waktu'] : '');
    final kegiatanCtrl = TextEditingController(text: isEdit ? dataEdit['kegiatan'] : '');
    final lokasiCtrl = TextEditingController(text: isEdit ? dataEdit['lokasi'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? "Edit Jadwal" : "Tambah Jadwal"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: waktuCtrl, decoration: const InputDecoration(labelText: "Waktu (Misal: 07:00 - 08:00)")),
                TextField(controller: kegiatanCtrl, decoration: const InputDecoration(labelText: "Nama Kegiatan")),
                TextField(controller: lokasiCtrl, decoration: const InputDecoration(labelText: "Lokasi")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                
                final payload = json.encode({
                  "waktu": waktuCtrl.text,
                  "kegiatan": kegiatanCtrl.text,
                  "lokasi": lokasiCtrl.text
                });

                if (isEdit) {
                  await http.put(Uri.parse('http://116.193.190.121:8080/api/panitia/rundown/${dataEdit['id']}'), headers: {"Content-Type": "application/json"}, body: payload);
                } else {
                  await http.post(Uri.parse('http://116.193.190.121:8080/api/panitia/rundown'), headers: {"Content-Type": "application/json"}, body: payload);
                }
                _fetchRundown();
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Rundown Acara", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.blue), onPressed: _fetchRundown)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tampilkanFormDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rundownList.isEmpty
              ? const Center(child: Text("Jadwal masih kosong"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rundownList.length,
                  itemBuilder: (context, index) {
                    final data = _rundownList[index];
                    final bool isLast = index == _rundownList.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // UI Garis Timeline
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
                          // Card Konten
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    Expanded(
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
                                          )
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(icon: const Icon(Icons.edit, color: Colors.orange, size: 20), onPressed: () => _tampilkanFormDialog(dataEdit: data)),
                                        IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _hapusRundown(data['id'])),
                                      ],
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