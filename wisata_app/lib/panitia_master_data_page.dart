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
        _fetchPeserta(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus peserta"), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Terjadi kesalahan jaringan"), backgroundColor: Colors.red));
    }
  }

  // UPDATE PAYLOAD JSON DENGAN DATA BARU (Termasuk id_bus)
  Future<void> _simpanPeserta(Map<String, dynamic> dataForm, bool isEdit) async {
    if (dataForm['id_peserta'].isEmpty || dataForm['nama_lengkap'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ID dan Nama tidak boleh kosong!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String id = dataForm['id_peserta'];
      final url = isEdit 
          ? Uri.parse('http://116.193.190.121:8080/api/panitia/peserta/$id') 
          : Uri.parse('http://116.193.190.121:8080/api/panitia/peserta');    

      final payload = json.encode(dataForm);

      final response = isEdit
          ? await http.put(url, headers: {"Content-Type": "application/json"}, body: payload)
          : await http.post(url, headers: {"Content-Type": "application/json"}, body: payload);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? "Data $id berhasil diupdate!" : "Peserta $id berhasil ditambahkan!"), backgroundColor: Colors.green)
        );
        _fetchPeserta(); 
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

  // DIALOG FORM INPUT DIREVISI (Tambah Controller ID Bus)
  void _tampilkanDialogForm({Map<String, dynamic>? pesertaData}) {
    final bool isEdit = pesertaData != null;
    
    // Inisialisasi Data Default
    final idController = TextEditingController(text: isEdit ? pesertaData['IDPeserta']?.toString() : '');
    final namaController = TextEditingController(text: isEdit ? pesertaData['NamaLengkap']?.toString() : '');
    final seatController = TextEditingController(text: isEdit ? pesertaData['Seat']?.toString() : '');
    final penyakitController = TextEditingController(text: isEdit ? pesertaData['PenyakitBawaan']?.toString() : '-');
    final alergiController = TextEditingController(text: isEdit ? pesertaData['Alergi']?.toString() : '-');
    final kontakController = TextEditingController(text: isEdit ? pesertaData['KontakDarurat']?.toString() : '');
    
    // ---> TAMBAHAN: Controller ID Bus <---
    final busIdController = TextEditingController(text: isEdit ? pesertaData['IDBus']?.toString() : '');
    
    // Password default diset '123456' untuk pendaftar baru
    final passController = TextEditingController(text: isEdit ? '' : '123456'); 

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(isEdit ? "Edit Peserta" : "Tambah Peserta", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView( // Agar tidak overflow saat ngetik
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: idController, enabled: !isEdit, decoration: const InputDecoration(labelText: "ID Peserta (Wajib)", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: namaController, decoration: const InputDecoration(labelText: "Nama Lengkap (Wajib)", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                
                // ---> TAMBAHAN: Form Input ID Bus <---
                TextField(
                  controller: busIdController, 
                  keyboardType: TextInputType.number, 
                  decoration: const InputDecoration(labelText: "ID Bus (Contoh: 1 atau 2)", border: OutlineInputBorder(), helperText: "Kosongkan jika belum ada bus")
                ),
                const SizedBox(height: 15),
                
                TextField(controller: seatController, decoration: const InputDecoration(labelText: "No. Seat (Misal: 14A)", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: penyakitController, decoration: const InputDecoration(labelText: "Penyakit Bawaan", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: alergiController, decoration: const InputDecoration(labelText: "Alergi Makanan/Obat", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: kontakController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Kontak Darurat (No HP)", border: OutlineInputBorder())),
                
                if (!isEdit) ...[
                  const SizedBox(height: 15),
                  TextField(
                    controller: passController, 
                    decoration: const InputDecoration(labelText: "Password Akun", helperText: "Bisa diganti jika tidak ingin pakai default", border: OutlineInputBorder())
                  ),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                // Bungkus jadi Map
                Map<String, dynamic> dataForm = {
                  "id_peserta": idController.text,
                  "nama_lengkap": namaController.text,
                  "seat": seatController.text,
                  "penyakit_bawaan": penyakitController.text,
                  "alergi": alergiController.text,
                  "kontak_darurat": kontakController.text,
                  
                  // ---> TAMBAHAN: Masukkan ID Bus ke Payload JSON <---
                  "id_bus": int.tryParse(busIdController.text) 
                };

                if (!isEdit) {
                  dataForm["password"] = passController.text;
                  dataForm["role"] = "PESERTA";
                }

                Navigator.pop(context); 
                _simpanPeserta(dataForm, isEdit);
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
        onPressed: () => _tampilkanDialogForm(), 
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
                    final idPeserta = p['IDPeserta']?.toString() ?? '-';
                    final namaLengkap = p['NamaLengkap']?.toString() ?? '-';
                    final seat = p['Seat']?.toString() ?? '-';
                    
                    // ---> TAMBAHAN: Tarik nama Bus dari relasi tabel untuk ditampilkan <---
                    final busName = p['Bus']?['NamaBus']?.toString() ?? '(Belum Ada Bus)';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        title: Text(namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                        
                        // ---> TAMBAHAN: Tampilkan Bus di Subtitle <---
                        subtitle: Text("ID: $idPeserta  |  Seat: $seat  |  Bus: $busName"),
                        
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _tampilkanDialogForm(pesertaData: p), 
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