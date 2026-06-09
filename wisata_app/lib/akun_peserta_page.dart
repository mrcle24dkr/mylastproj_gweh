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
  bool _isDarkMode = false; // Variabel untuk fitur Change Mode

  String namaPeserta = "Memuat data...";
  String infoBus = "BUS 1"; // Placeholder

  @override
  void initState() {
    super.initState();
    _fetchDataPeserta();
  }

  // Menyedot data nama peserta dari Golang
  Future<void> _fetchDataPeserta() async {
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/peserta/${widget.idPeserta}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        
        // Cek mounted sebelum update UI (Best Practice)
        if (mounted) {
          setState(() {
            namaPeserta = data['nama_lengkap'] ?? data['NamaLengkap'] ?? 'Unknown';
            // Jika backend sudah mengirim data bus, bisa diubah di sini
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          namaPeserta = "Gagal memuat data";
        });
      }
    }
  }

  // FUNGSI GANTI PASSWORD (MENGGUNAKAN API LAMA)
  Future<void> _gantiPassword() async {
    if (_passLamaController.text.isEmpty || _passBaruController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kata sandi tidak boleh kosong!"), backgroundColor: Colors.red),
      );
      return;
    }

    if (mounted) setState(() => _isLoading = true);

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

      // ---> PERBAIKAN BUG ASYNC GAPS <---
      if (!mounted) return;

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
        );
        _passLamaController.clear();
        _passBaruController.clear();
        Navigator.pop(context); // Tutup dialog jika sukses
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Terjadi kesalahan'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // ---> PERBAIKAN BUG ASYNC GAPS <---
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke server"), backgroundColor: Colors.red),
      );
    } finally {
      // ---> PERBAIKAN BUG ASYNC GAPS <---
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // TAMPILAN POP-UP UNTUK GANTI PASSWORD
  void _tampilkanDialogPassword() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Agar indikator loading di dalam dialog bisa update
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _passLamaController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Current Password", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passBaruController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "New Password", border: OutlineInputBorder()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setStateDialog(() => _isLoading = true);
                    await _gantiPassword();
                    if (mounted) {
                      setStateDialog(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD07044)),
                  child: _isLoading 
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Simpan", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  // --- WIDGET BUILDER UNTUK DESAIN CARD --- //
  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE28B5B), Color(0xFFD07044)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap, bool showBorder = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          border: showBorder ? const Border(bottom: BorderSide(color: Colors.white30, width: 1)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Icon(Icons.arrow_right, color: Colors.black87),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definisi warna dasar berdasarkan mode
    Color bgColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = _isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER TITLE
              Padding(
                padding: const EdgeInsets.only(left: 25, top: 20, bottom: 10),
                child: Text(
                  "Account", 
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textColor),
                ),
              ),

              // 1. PROFIL CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE28B5B), Color(0xFFD07044)],
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25, backgroundColor: Colors.black87,
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(namaPeserta, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 5),
                          Text("${widget.idPeserta}   •   $infoBus", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const Divider(color: Colors.white54, height: 10),
                          const Text("No. Kursi: 12A   •   PESERTA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. ID CARD & MEDICAL RECORD
              _buildMenuCard(
                children: [
                  _buildMenuItem(icon: Icons.badge, title: "ID CARD", showBorder: true, onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Membuka ID Card...")));
                  }),
                  _buildMenuItem(icon: Icons.medical_information, title: "MEDICAL RECORD", onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Membuka Data Medis...")));
                  }),
                ]
              ),

              // 3. EMERGENCY CALL & GPS
              _buildMenuCard(
                children: [
                  _buildMenuItem(icon: Icons.phone_in_talk, title: "EMERGENCY CALL", showBorder: true, onTap: () {}),
                  _buildMenuItem(icon: Icons.pin_drop, title: "GPS & SYSTEM STATUS", onTap: () {}),
                ]
              ),

              // 4. PASSWORD & PRIVACY
              _buildMenuCard(
                children: [
                  _buildMenuItem(icon: Icons.password, title: "CHANGE PASSWORD", showBorder: true, onTap: _tampilkanDialogPassword),
                  _buildMenuItem(icon: Icons.security, title: "PRIVACY & SECURE", onTap: () {}),
                ]
              ),

              // 5. CHANGE MODE & FAQ
              _buildMenuCard(
                children: [
                  // FITUR CHANGE MODE
                  _buildMenuItem(icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode, title: "CHANGE MODE", showBorder: true, onTap: () {
                    setState(() {
                      _isDarkMode = !_isDarkMode; // Mengubah state dari terang ke gelap atau sebaliknya
                    });
                  }),
                  _buildMenuItem(icon: Icons.help_outline, title: "HELP & FAQ", onTap: () {}),
                ]
              ),

              const SizedBox(height: 30),

              // COPYRIGHT TEXT
              Center(
                child: Text(
                  "© 2026 EMPIRISE KARYA HUTAMA",
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: textColor),
                ),
              ),

              const SizedBox(height: 20),

              // LOG OUT BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: InkWell(
                  onTap: () => Navigator.pushReplacementNamed(context, '/'), // Kembali ke Login Page
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE28B5B), Color(0xFFD07044)],
                        begin: Alignment.centerLeft, end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.logout, color: Colors.black87),
                        SizedBox(width: 10),
                        Text(
                          "LOG OUT", 
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30), // Ruang lega untuk Bottom Navigation Bar
            ],
          ),
        ),
      ),
    );
  }
}