// Lokasi File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'qr_page.dart';
import 'map_page.dart';

void main() async {
  // Wajib dipanggil sebelum inisialisasi Firebase
  WidgetsFlutterBinding.ensureInitialized(); 
  
  const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const String authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  const String databaseURL = String.fromEnvironment('FIREBASE_DATABASE_URL');
  const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const String storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  const String messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const String appId = String.fromEnvironment('FIREBASE_APP_ID');
  const String measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

  // Menyalakan koneksi ke Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: apiKey,
      authDomain: authDomain,
      databaseURL: databaseURL,
      projectId: projectId,
      storageBucket: storageBucket,
      messagingSenderId: messagingSenderId,
      appId: appId,
      measurementId: measurementId,
    )
  ); 
  
  runApp(const WisataApp());
}

class WisataApp extends StatelessWidget {
  const WisataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Pemantauan Wisata',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;
  final String idPeserta = "EMP-01"; 

  late final List<Widget> _pages = [
    QrPage(idPeserta: idPeserta),
    MapPage(idPeserta: idPeserta),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'QR Tiket'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Lokasi & Radar'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red[800],
        onTap: _onItemTapped,
      ),
    );
  }
}