// Lokasi File: lib/panitia_master_data_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PanitiaMasterDataPage extends StatefulWidget {
  const PanitiaMasterDataPage({super.key});

  @override
  State<PanitiaMasterDataPage> createState() => _PanitiaMasterDataPageState();
}

class _PanitiaMasterDataPageState extends State<PanitiaMasterDataPage> {
  List<dynamic> _pesertaList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPeserta();
  }

  // 1. READ: Ambil Data Peserta
  Future<void> _fetchPeserta() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/panitia/peserta');
      final response = await http.get(url);
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        setState(() {
          _pesertaList = json.decode(response.body)['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memuat data")));
    }
  }

  // 2. DELETE: Hapus Peserta
  Future<void> _hapusPeserta(String idPeserta) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Peserta?"),
        content: Text("Yakin ingin menghapus data $idPeserta? Semua data terkait mungkin akan hilang."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/panitia/peserta/$idPeserta');
      final response = await http.delete(url);
      
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Peserta Dihapus!"), backgroundColor: Colors.green));
        _fetchPeserta(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus peserta"), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Terjadi kesalahan jaringan"), backgroundColor: Colors.red));
    }
  }

  // 3. CREATE & UPDATE: Tembak API Golang
  Future<void> _simpanPeserta(String id, String nama, bool isEdit) async {
    if (id.isEmpty || nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ID dan Nama tidak boleh kosong!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ---> PERBAIKAN BUG URL ADA DI SINI <---
      // Menggunakan /$id agar ID Peserta masuk ke dalam alamat URL
      final url = isEdit 
          ? Uri.parse('http://116.193.190.121:8080/api/panitia/peserta/$id') 
          : Uri.parse('http://116.193.190.121:8080/api/panitia/peserta');    

      // Bentuk JSON yang akan dikirim ke Golang
      final payload = json.encode({
        "id_peserta": id,
        "nama_lengkap": nama,
        // Jika tambah baru, biasanya butuh password default dan role
        if (!isEdit) "password": id, 
        if (!isEdit) "role": "PESERTA"
      });

      // Pilih metode HTTP berdasarkan mode (Edit = PUT, Tambah = POST)
      final response = isEdit
          ? await http.put(url, headers: {"Content-Type": "application/json"}, body: payload)
          : await http.post(url, headers: {"Content-Type": "application/json"}, body: payload);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? "Data $id berhasil diupdate!" : "Peserta $id berhasil ditambahkan!"), backgroundColor: Colors.green)
        );
        _fetchPeserta(); // Refresh daftar tampilan!
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan: ${response.body}"), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal terhubung ke server"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 4. DIALOG FORM INPUT
  void _tampilkanDialogForm({Map<String, dynamic>? pesertaData}) {
    final bool isEdit = pesertaData != null;
    final TextEditingController idController = TextEditingController(text: isEdit ? pesertaData['IDPeserta'].toString() : '');
    final TextEditingController namaController = TextEditingController(text: isEdit ? pesertaData['NamaLengkap'].toString() : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(isEdit ? "Edit Peserta" : "Tambah Peserta", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController, 
                enabled: !isEdit, // ID tidak bisa diedit jika mode update (hanya nama)
                decoration: const InputDecoration(labelText: "ID Peserta", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: namaController, 
                decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog form-nya
                // Panggil fungsi simpan yang baru kita buat
                _simpanPeserta(idController.text, namaController.text, isEdit);
              },
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Master Data Peserta", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.blue), onPressed: _fetchPeserta)
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tampilkanDialogForm(), // Membuka form mode TAMBAH
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text("Tambah Peserta", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pesertaList.isEmpty
              ? const Center(child: Text("Tidak ada data peserta"))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 10), 
                  itemCount: _pesertaList.length,
                  itemBuilder: (context, index) {
                    final p = _pesertaList[index];
                    final idPeserta = p['IDPeserta'].toString();
                    final namaLengkap = p['NamaLengkap'].toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        title: Text(namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("ID: $idPeserta"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _tampilkanDialogForm(pesertaData: p), // Membuka form mode EDIT
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _hapusPeserta(idPeserta),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}