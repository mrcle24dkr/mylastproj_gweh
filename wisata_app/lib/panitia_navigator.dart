// Lokasi: lib/panitia_navigator.dart
import 'package:flutter/material.dart';
import 'panitia_log_page.dart';
import 'panitia_map_page.dart';
import 'akun_panitia_page.dart';

class PanitiaNavigator extends StatefulWidget {
  const PanitiaNavigator({super.key});

  @override
  State<PanitiaNavigator> createState() => _PanitiaNavigatorState();
}

class _PanitiaNavigatorState extends State<PanitiaNavigator> {
  int _selectedIndex = 1; // Default ke tab Live Log

  final List<Widget> _pages = const [
    Center(child: Text("Halaman Input Data & Upload CSV\n(Dikerjakan Besok)", textAlign: TextAlign.center)), // Tab 0
    PanitiaLogPage(), // Tab 1
    PanitiaMapPage(), // Tab 2
    AkunPanitiaPage(), // Tab 3
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mode Panitia", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          )
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Penting jika tab > 3 agar tidak error visual
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.group_add), label: 'Tambah'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Live Log'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Radar'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Sistem'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}