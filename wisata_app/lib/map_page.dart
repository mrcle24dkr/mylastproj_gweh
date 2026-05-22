import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; 
import 'services/location_service.dart';

class MapPage extends StatefulWidget {
  final String idPeserta;
  const MapPage({super.key, required this.idPeserta});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String _locationMessage = "Mencari lokasi...";
  String _statusGeofence = "-";
  double _jarakMeter = 0;

  final double latPos = -7.74664;
  final double lonPos = 110.35546;
  final double radiusAman = 50.0;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  // Kontroler untuk menggerakkan kamera peta
  final MapController _mapController = MapController();
  LatLng _posisiPeserta = const LatLng(-7.74664, 110.35546);
  bool _lokasiDitemukan = false;

  @override
  void initState() {
    super.initState();
    _cekIzinDanAmbilLokasi();
  }

  Future<void> _cekIzinDanAmbilLokasi() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationMessage = "GPS tidak aktif.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Dengarkan perubahan lokasi HP secara Real-Time
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
    ).listen((Position position) {
      double jarak = LocationService.hitungJarakHaversine(
        position.latitude, position.longitude, latPos, lonPos
      );
      String status = LocationService.cekStatusGeofence(jarak, radiusAman);

      setState(() {
        _jarakMeter = jarak;
        _statusGeofence = status;
        _locationMessage = "Lat: ${position.latitude}\nLon: ${position.longitude}";
        _posisiPeserta = LatLng(position.latitude, position.longitude);
        _lokasiDitemukan = true;
      });

      // Geser kamera peta secara otomatis mengikuti peserta
      _mapController.move(_posisiPeserta, 17.0);

      // Kirim data Tracking ke Firebase
      _dbRef.child("tracking").child(widget.idPeserta).set({
        "latitude": position.latitude,
        "longitude": position.longitude,
        "jarak_meter": double.parse(jarak.toStringAsFixed(2)),
        "status": status,
        "waktu_update": DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Radar Pemantauan (OSM)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // --- RENDER PETA OPENSTREETMAP ---
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(latPos, lonPos),
                    initialZoom: 16.0,
                  ),
                  children: [
                    // Lapisan Peta Dasar dari server OSM (Gratis & Bebas Kuota)
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.wisata_app',
                    ),
                    // Lapisan Penanda (Markers)
                    MarkerLayer(
                      markers: [
                        // Marker Titik Kumpul (Merah)
                        Marker(
                          point: LatLng(latPos, lonPos),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                        // Marker Posisi Peserta (Biru) - Muncul jika GPS sudah terkunci
                        if (_lokasiDitemukan)
                          Marker(
                            point: _posisiPeserta,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text("Jarak ke Titik Kumpul: ${_jarakMeter.toStringAsFixed(1)} Meter", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text("Status: $_statusGeofence", 
                      style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold,
                        color: _statusGeofence == "AMAN" ? Colors.green : Colors.red,
                      )),
                    const SizedBox(height: 10),
                    Text(_locationMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}