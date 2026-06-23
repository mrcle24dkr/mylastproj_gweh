// Lokasi File: lib/akun_panitia_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; // ---> IMPORT TAMBAHAN
import 'providers/theme_provider.dart'; 
import 'login_page.dart'; // ---> IMPORT TAMBAHAN

class AkunPanitiaPage extends StatefulWidget {
  const AkunPanitiaPage({super.key});

  @override
  State<AkunPanitiaPage> createState() => _AkunPanitiaPageState();
}

class _AkunPanitiaPageState extends State<AkunPanitiaPage> {
  final TextEditingController _passLamaController = TextEditingController();
  final TextEditingController _passBaruController = TextEditingController();
  final TextEditingController _idRoleController = TextEditingController(); 
  
  bool _isLoading = false;

  // FUNGSI GANTI PASSWORD PANITIA
  Future<void> _gantiPasswordPanitia() async {
    if (_passLamaController.text.isEmpty || _passBaruController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kata sandi tidak boleh kosong!"), backgroundColor: Colors.red));
      return;
    }
    if (mounted) setState(() => _isLoading = true);
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/user/password');
      final response = await http.put(url, headers: {"Content-Type": "application/json"},
        body: json.encode({"id_peserta": "PANITIA", "password_lama": _passLamaController.text, "password_baru": _passBaruController.text}),
      );
      if (!mounted) return;
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
        _passLamaController.clear(); _passBaruController.clear(); Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Terjadi kesalahan'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal terhubung ke server"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FUNGSI UBAH ROLE JADI PANITIA
  Future<void> _ubahRoleJadiPanitia() async {
    if (_idRoleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ID Peserta tidak boleh kosong!"), backgroundColor: Colors.red));
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/user/role'); 
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "id_peserta": _idRoleController.text,
          "role": "PANITIA" 
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Berhasil! ${_idRoleController.text} sekarang adalah Panitia."), backgroundColor: Colors.green));
        _idRoleController.clear();
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengubah role"), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal terhubung ke server"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---> FUNGSI BARU: LOGOUT YANG MENGHAPUS SESI MEMORI <---
  Future<void> _prosesLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus memori login dari HP

    if (!mounted) return;
    
    // Hapus semua rute layar dan lempar kembali ke Login Page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // DIALOG UBAH ROLE
  void _tampilkanDialogUbahRole() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Ubah Role ke Panitia", style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Masukkan ID Peserta yang ingin diangkat menjadi Panitia/Admin.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 15),
                TextField(
                  controller: _idRoleController, 
                  decoration: const InputDecoration(labelText: "ID Peserta (Contoh: EMP-001)", border: OutlineInputBorder())
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  setStateDialog(() => _isLoading = true);
                  await _ubahRoleJadiPanitia();
                  if (mounted) setStateDialog(() => _isLoading = false);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isLoading ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Jadikan Panitia", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
      },
    );
  }

  // DIALOG GANTI PASSWORD
  void _tampilkanDialogPassword() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _passLamaController, obscureText: true, decoration: const InputDecoration(labelText: "Current Password", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: _passBaruController, obscureText: true, decoration: const InputDecoration(labelText: "New Password", border: OutlineInputBorder())),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  setStateDialog(() => _isLoading = true);
                  await _gantiPasswordPanitia();
                  if (mounted) setStateDialog(() => _isLoading = false);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD07044)),
                child: _isLoading ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Simpan", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE28B5B), Color(0xFFD07044)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap, bool showBorder = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(border: showBorder ? const Border(bottom: BorderSide(color: Colors.white30, width: 1)) : null),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 15),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            const Icon(Icons.arrow_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode; 

    Color bgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              const CircleAvatar(radius: 50, backgroundColor: Colors.black87, child: Icon(Icons.admin_panel_settings, size: 60, color: Colors.amber)),
              const SizedBox(height: 15),
              Text("PANITIA", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
              const Text("Administrator Sistem", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              // KELOMPOK 1: MANAJEMEN
              _buildMenuCard(children: [
                _buildMenuItem(icon: Icons.admin_panel_settings_outlined, title: "UBAH ROLE PESERTA", onTap: _tampilkanDialogUbahRole),
              ]),

              // KELOMPOK 2: PERSONAL & SAFETY
              _buildMenuCard(children: [
                _buildMenuItem(icon: Icons.badge, title: "ID CARD", showBorder: true, onTap: () {}),
                _buildMenuItem(icon: Icons.phone_in_talk, title: "EMERGENCY CALL", showBorder: true, onTap: () {}),
                _buildMenuItem(icon: Icons.pin_drop, title: "GPS & SYSTEM STATUS", onTap: () {}),
              ]),

              // KELOMPOK 3: SETTINGS
              _buildMenuCard(children: [
                _buildMenuItem(icon: Icons.password, title: "CHANGE PASSWORD", showBorder: true, onTap: _tampilkanDialogPassword),
                _buildMenuItem(icon: Icons.security, title: "PRIVACY & SECURE", onTap: () {}),
              ]),

              // KELOMPOK 4: MODE & FAQ
              _buildMenuCard(children: [
                _buildMenuItem(
                  icon: isDarkMode ? Icons.light_mode : Icons.dark_mode, 
                  title: "CHANGE MODE", 
                  showBorder: true, 
                  onTap: () {
                    themeProvider.toggleTheme();
                  }
                ),
                _buildMenuItem(icon: Icons.help_outline, title: "HELP & FAQ", onTap: () {}),
              ]),
              
              Padding(
                padding: const EdgeInsets.all(20),
                // ---> TOMBOL LOGOUT MEMANGGIL FUNGSI _prosesLogout <---
                child: OutlinedButton.icon(
                  onPressed: _prosesLogout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("LOG OUT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}