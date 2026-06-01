// Lokasi File: lib/login_page.dart
import 'package:flutter/material.dart';
import 'main.dart'; // Memanggil MainNavigator (Peserta)
import 'panitia_navigator.dart'; // Memanggil PanitiaNavigator (Panitia)

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

    // Validasi kosong
    if (idInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ID Pengguna tidak boleh kosong!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // TODO: Nanti disambungkan ke API Golang untuk validasi password
    await Future.delayed(const Duration(seconds: 1)); // Simulasi loading API

    setState(() => _isLoading = false);

    if (!mounted) return;

    // LOGIKA ROUTING ROLE (Panitia vs Peserta)
    if (idInput.contains("PANITIA") || idInput.contains("ADMIN")) {
      // Masuk ke Mode Panitia
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PanitiaNavigator()),
      );
    } else {
      // Masuk ke Mode Peserta (Kirimkan ID yang diketik ke MainNavigator)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainNavigator(idPeserta: idInput)),
      );
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
                  "Sistem Presensi\nPT Empirise",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 40),
                
                // Form Input ID
                TextField(
                  controller: _idController,
                  textCapitalization: TextCapitalization.characters, // Otomatis huruf besar
                  decoration: InputDecoration(
                    labelText: "ID Pengguna (Peserta / Panitia)",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[800]!, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Form Input Password
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
                
                // Tombol Login
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
                const Text(
                  "Gunakan ID 'PANITIA' untuk masuk sebagai panitia.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}