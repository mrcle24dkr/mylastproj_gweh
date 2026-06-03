// Lokasi File: lib/akun_panitia_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AkunPanitiaPage extends StatefulWidget {
  const AkunPanitiaPage({super.key});

  @override
  State<AkunPanitiaPage> createState() => _AkunPanitiaPageState();
}

class _AkunPanitiaPageState extends State<AkunPanitiaPage> {
  final TextEditingController _passLamaController = TextEditingController();
  final TextEditingController _passBaruController = TextEditingController();
  bool _isLoading = false;

  Future<void> _gantiPasswordPanitia() async {
    if (_passLamaController.text.isEmpty || _passBaruController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kata sandi tidak boleh kosong!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/user/password');
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "id_peserta": "PANITIA", // Langsung tembak ID Panitia
          "password_lama": _passLamaController.text,
          "password_baru": _passBaruController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
        );
        _passLamaController.clear();
        _passBaruController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Terjadi kesalahan'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke server Golang"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black87,
              child: Icon(Icons.admin_panel_settings, size: 60, color: Colors.amber),
            ),
            const SizedBox(height: 15),
            const Text("PANITIA", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Administrator Sistem Empirise", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            // MENU MANAJEMEN PESERTA (Fitur Eksklusif Panitia)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: const Icon(Icons.manage_accounts, color: Colors.blue, size: 40),
                title: const Text("Kelola Master Data", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Edit nama, pindah bus, atau koreksi data mahasiswa."),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Besok kita buatkan halaman MasterDataPage
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Membuka Master Data... (Coming Soon)")),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),

            // FORM GANTI PASSWORD PANITIA
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Ganti Kata Sandi Admin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passLamaController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Kata Sandi Saat Ini", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passBaruController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Kata Sandi Baru", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _gantiPasswordPanitia,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("SIMPAN PASSWORD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}