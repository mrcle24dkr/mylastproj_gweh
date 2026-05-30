// Lokasi File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'qr_page.dart';
import 'map_page.dart';

void main() async {
  // Wajib dipanggil sebelum inisialisasi Firebase
  WidgetsFlutterBinding.ensureInitialized(); 
  
  await dotenv.load(fileName: ".env");
  
  // Mengambil data dari dotenv (ganti String.fromEnvironment)
  final String apiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';
  final String authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  final String databaseURL = dotenv.env['FIREBASE_DATABASE_URL'] ?? '';
  final String projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  final String storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  final String messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  final String appId = dotenv.env['FIREBASE_APP_ID'] ?? '';
  final String measurementId = dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '';

  // Menyalakan koneksi ke Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
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
  final String idPeserta = "EMP-VA01-038"; 

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