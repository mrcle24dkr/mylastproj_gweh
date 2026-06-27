// Lokasi File: lib/map_page.dart
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

  double latPos = -7.74664;
  double lonPos = 110.35546;
  final double radiusAman = 50.0;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final MapController _mapController = MapController();
  LatLng _posisiPeserta = const LatLng(-7.74664, 110.35546);
  bool _lokasiDitemukan = false;

  @override
  void initState() {
    super.initState();
    _listenTitikKumpul(); 
    _cekIzinDanAmbilLokasi();
  }

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

      // Agar map tidak selalu berpusat memaksa ke peserta setiap detik, 
      // kamu bisa matikan auto-move ini nanti jika dirasa mengganggu saat digeser manual.
      _mapController.move(_posisiPeserta, 17.0);

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
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.wisata_app',
                    ),
                    
                    // ---> REVISI: LAYER GARIS PENUNJUK ARAH (POLYLINE) <---
                    if (_lokasiDitemukan)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [
                              _posisiPeserta, 
                              LatLng(latPos, lonPos)
                            ],
                            color: Colors.blueAccent.withOpacity(0.7),
                            strokeWidth: 5.0,
                          ),
                        ],
                      ),
                      
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(latPos, lonPos),
                          width: 40, height: 40,
                          child: const Icon(Icons.directions_bus, color: Colors.red, size: 40),
                        ),
                        if (_lokasiDitemukan)
                          Marker(
                            point: _posisiPeserta,
                            width: 40, height: 40,
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
                    Text(
                      _locationMessage, 
                      textAlign: TextAlign.center, 
                      style: const TextStyle(fontSize: 12, color: Colors.grey)
                    ),
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