// Lokasi: lib/panitia_map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PanitiaMapPage extends StatefulWidget {
  const PanitiaMapPage({super.key});

  @override
  State<PanitiaMapPage> createState() => _PanitiaMapPageState();
}

class _PanitiaMapPageState extends State<PanitiaMapPage> {
  final MapController _mapController = MapController();
  final double latPos = -7.74664;
  final double lonPos = 110.35546;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PETA GEOLOKASI (Setengah layar atas)
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
                  // Marker Titik Kumpul (Bus)
                  Marker(
                    point: LatLng(latPos, lonPos),
                    width: 40, height: 40,
                    child: const Icon(Icons.directions_bus, color: Colors.blue, size: 40),
                  ),
                  // TODO: Nanti kita looping marker merah/hijau dari Firebase Realtime
                ],
              ),
            ],
          ),
        ),
        
        // DAFTAR KONTAK DARURAT (Setengah layar bawah)
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
                    itemCount: 3, // Mock data sementara
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text("Peserta Out-of-Bounds ${index + 1}"),
                        subtitle: const Text("Ketuk untuk lihat detail medis & telepon"),
                        trailing: IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () {},
                        ),
                        onTap: () {
                          // TODO: Tampilkan BottomSheet detail peserta
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}