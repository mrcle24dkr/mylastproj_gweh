// Lokasi File: lib/akun_peserta_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AkunPesertaPage extends StatefulWidget {
  final String idPeserta;
  const AkunPesertaPage({super.key, required this.idPeserta});

  @override
  State<AkunPesertaPage> createState() => _AkunPesertaPageState();
}

class _AkunPesertaPageState extends State<AkunPesertaPage> {
  final TextEditingController _passLamaController = TextEditingController();
  final TextEditingController _passBaruController = TextEditingController();
  bool _isLoading = false;

  Future<void> _gantiPassword() async {
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
          "id_peserta": widget.idPeserta,
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
          SnackBar(content: Text(data['message']), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke server"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Akun Saya", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.redAccent,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 15),
            Text(widget.idPeserta, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Peserta Kunjungan Industri", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            
            // Form Ganti Password
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Ganti Kata Sandi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      onPressed: _isLoading ? null : _gantiPassword,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
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