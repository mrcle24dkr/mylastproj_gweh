// Lokasi File: lib/login_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ---> TAMBAHAN IMPORT
import 'main.dart'; // Memanggil MainNavigator (Peserta)
import 'panitia_navigator.dart'; // Memanggil PanitiaNavigator (Panitia)
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    String idInput = _idController.text.trim().toUpperCase();
    String passwordInput = _passwordController.text;

    if (idInput.isEmpty || passwordInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ID dan Kata Sandi tidak boleh kosong!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "id_pengguna": idInput, 
          "kata_sandi": passwordInput,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        String role = data['data']['role'];
        String idValid = data['data']['id']; 

        // ---> PROSES SIMPAN SESI KE MEMORI HP <---
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('role', role);
        await prefs.setString('id_peserta', idValid); // Simpan ID valid dari database

        // LOGIKA ROUTING ROLE
        if (role == "PANITIA") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PanitiaNavigator()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainNavigator(idPeserta: idValid)),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login gagal'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint("Error Login: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke Server"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.security, size: 80, color: Colors.red[800]),
                const SizedBox(height: 20),
                const Text(
                  "Sistem Presensi\nPT Empirise Karya Hutama",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 40),
                
                TextField(
                  controller: _idController,
                  textCapitalization: TextCapitalization.characters, 
                  decoration: InputDecoration(
                    labelText: "ID Pengguna",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[800]!, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Kata Sandi",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[800]!, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("MASUK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}