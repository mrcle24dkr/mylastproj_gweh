// Lokasi: lib/panitia_map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class PanitiaMapPage extends StatefulWidget {
  const PanitiaMapPage({super.key});

  @override
  State<PanitiaMapPage> createState() => _PanitiaMapPageState();
}

class _PanitiaMapPageState extends State<PanitiaMapPage> {
  final MapController _mapController = MapController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  // Koordinat dinamis (tidak lagi final)
  double latPos = -7.74664;
  double lonPos = 110.35546;

  @override
  void initState() {
    super.initState();
    _listenTitikKumpul();
  }

  // 1. DENGARKAN PERUBAHAN LOKASI DARI PANITIA LAIN
  void _listenTitikKumpul() {
    _dbRef.child("titik_kumpul_aktif").onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          latPos = (data['lat'] as num).toDouble();
          lonPos = (data['lon'] as num).toDouble();
        });
      }
    });
  }

  // 2. FUNGSI UNTUK MENGUNCI LOKASI PANITIA SEBAGAI TITIK KUMPUL
  Future<void> _aturTitikKumpulKeLokasiSaya() async {
    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    await _dbRef.child("titik_kumpul_aktif").set({
      "lat": pos.latitude,
      "lon": pos.longitude,
      "diupdate_oleh": "PANITIA_AKTIF"
    });
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Titik kumpul dipindahkan ke lokasi Anda!"), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _aturTitikKumpulKeLokasiSaya,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(latPos, lonPos),
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.wisata_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(latPos, lonPos),
                      width: 40, height: 40,
                      child: const Icon(Icons.directions_bus, color: Colors.blue, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.red[50],
                    child: const Text(
                      "Peringatan Geofencing & Kontak Darurat", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.warning, color: Colors.red),
                          title: Text("Peserta Out-of-Bounds ${index + 1}"),
                          subtitle: const Text("Ketuk untuk lihat detail medis & telepon"),
                          trailing: IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: () {},
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}