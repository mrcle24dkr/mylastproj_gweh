// Lokasi File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'panitia_navigator.dart';
import 'qr_page.dart';
import 'map_page.dart';
import 'rundown_page.dart';
import 'akun_peserta_page.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  debugPrint("1. Mulai load env...");
  await dotenv.load(fileName: ".env");
  
  final String apiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';
  final String authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  final String databaseURL = dotenv.env['FIREBASE_DATABASE_URL'] ?? '';
  final String projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  final String storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  final String messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  final String appId = dotenv.env['FIREBASE_APP_ID'] ?? '';
  final String measurementId = dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '';

  debugPrint("2. Mulai load Firebase...");
  try {
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
      ),
    );
    debugPrint("Firebase berhasil diinisialisasi secara manual.");
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint("Firebase [DEFAULT] sudah dinyalakan oleh sistem Android. Aman untuk dilewati.");
    } else {
      rethrow;
    }
  }

  // ---> 3. CEK SESI LOGIN DI MEMORI HP <---
  debugPrint("3. Mengecek sesi login...");
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String role = prefs.getString('role') ?? '';
  final String idPeserta = prefs.getString('id_peserta') ?? '';

  // Penentuan rute awal
  Widget halamanPertama = const LoginPage();
  
  if (isLoggedIn) {
    if (role == 'PANITIA') {
      halamanPertama = const PanitiaNavigator();
    } else if (role == 'PESERTA' && idPeserta.isNotEmpty) {
      halamanPertama = MainNavigator(idPeserta: idPeserta);
    }
  }
  
  debugPrint("4. Memanggil runApp...");
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      // Lempar halamanPertama ke dalam WisataApp
      child: WisataApp(halamanPertama: halamanPertama),
    ),
  );
}

class WisataApp extends StatelessWidget {
  final Widget halamanPertama; // Menerima lemparan halaman dari main()

  const WisataApp({super.key, required this.halamanPertama});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Empirise Jalan-Jalan',
      debugShowCheckedModeBanner: false,
      
      themeMode: themeProvider.themeMode,
      
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        cardColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
        ),
      ),
      
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
        ),
      ),
      
      // Gunakan halaman yang sudah diseleksi oleh SharedPreferences
      home: halamanPertama, 
    );
  }
}

class MainNavigator extends StatefulWidget {
  final String idPeserta; 
  
  const MainNavigator({super.key, required this.idPeserta});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const RundownPage(),
    QrPage(idPeserta: widget.idPeserta),
    MapPage(idPeserta: widget.idPeserta),
    AkunPesertaPage(idPeserta: widget.idPeserta),
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
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'QR Tiket'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Lokasi & Radar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun Saya'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}