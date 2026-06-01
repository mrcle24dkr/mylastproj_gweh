// Lokasi: lib/panitia_navigator.dart
import 'package:flutter/material.dart';
import 'panitia_log_page.dart';
import 'panitia_map_page.dart';

class PanitiaNavigator extends StatefulWidget {
  const PanitiaNavigator({super.key});

  @override
  State<PanitiaNavigator> createState() => _PanitiaNavigatorState();
}

class _PanitiaNavigatorState extends State<PanitiaNavigator> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    PanitiaLogPage(),
    PanitiaMapPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mode Panitia", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          )
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Live Log ESP32'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Radar Peserta'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red[800],
        onTap: _onItemTapped,
      ),
    );
  }
}