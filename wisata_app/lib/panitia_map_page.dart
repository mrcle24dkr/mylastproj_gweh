// Lokasi File: lib/panitia_map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; 

class PanitiaMapPage extends StatefulWidget {
  const PanitiaMapPage({super.key});

  @override
  State<PanitiaMapPage> createState() => _PanitiaMapPageState();
}

class _PanitiaMapPageState extends State<PanitiaMapPage> {
  final MapController _mapController = MapController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  double latPos = -7.74664;
  double lonPos = 110.35546;

  Map<String, dynamic> _pesertaTracking = {};
  Map<String, dynamic> _mapDetailPeserta = {}; 

  @override
  void initState() {
    super.initState();
    _fetchMasterDataPeserta();
    _listenTitikKumpul();
    _listenTrackingPeserta();
  }

  Future<void> _fetchMasterDataPeserta() async {
    try {
      final url = Uri.parse('http://116.193.190.121:8080/api/panitia/peserta');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        if(mounted) {
          setState(() {
            for (var p in data) {
              _mapDetailPeserta[p['IDPeserta'].toString()] = p; 
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat detail peserta: $e");
    }
  }

  void _listenTitikKumpul() {
    _dbRef.child("titik_kumpul_aktif").onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map?;
      if (data != null && mounted) {
        setState(() {
          latPos = (data['lat'] as num).toDouble();
          lonPos = (data['lon'] as num).toDouble();
        });
      }
    });
  }

  void _listenTrackingPeserta() {
    _dbRef.child("tracking").onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map?;
      if (data != null && mounted) {
        setState(() {
          _pesertaTracking = Map<String, dynamic>.from(data);
        });
      }
    });
  }

  Future<void> _aturTitikKumpulKeLokasiSaya() async {
    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    await _dbRef.child("titik_kumpul_aktif").set({
      "lat": pos.latitude, "lon": pos.longitude, "diupdate_oleh": "PANITIA_AKTIF"
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Titik kumpul dipindahkan ke lokasi Anda!"), backgroundColor: Colors.blue));
  }

  Future<void> _teleponDarurat(String nomor) async {
    final Uri url = Uri.parse('tel:$nomor');
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak dapat membuka aplikasi telepon")));
    }
  }

  void _tampilkanDetailPeserta(String idPeserta, Map<dynamic, dynamic> info) {
    final bool isAman = info['status'] == "AMAN";
    
    final detail = _mapDetailPeserta[idPeserta] ?? {};
    final String namaPeserta = detail['NamaLengkap']?.toString() ?? idPeserta;
    final String seat = detail['Seat']?.toString() ?? '-';
    final String penyakit = detail['PenyakitBawaan']?.toString() ?? '-';
    final String alergi = detail['Alergi']?.toString() ?? '-';
    final String noDarurat = detail['KontakDarurat']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return Wrap( 
          children: [
            Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 45), 
                  padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("FOTO PROFIL", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                      const SizedBox(height: 5),
                      Text(namaPeserta.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      const SizedBox(height: 5),
                      Text("SEAT : $seat", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isAman ? Colors.green : const Color(0xFFD32F2F),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isAman ? Icons.check_circle : Icons.warning_amber_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Status : ${isAman ? 'Di Dalam Radius Aman' : 'Di Luar Radius Aman!'}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      const Divider(thickness: 2),
                      const SizedBox(height: 15),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("DATA MEDIS :", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, fontStyle: FontStyle.italic)),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Icon(Icons.sick, color: Colors.deepOrange),
                          const SizedBox(width: 15),
                          const Text("Penyakit Bawaan : ", style: TextStyle(fontSize: 15)),
                          Expanded(child: Text(penyakit, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.no_meals, color: Colors.deepOrange),
                          const SizedBox(width: 15),
                          const Text("Alergi : ", style: TextStyle(fontSize: 15)),
                          Expanded(child: Text(alergi, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
                        ],
                      ),
                      
                      const SizedBox(height: 35),
                      
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: noDarurat.isEmpty ? Colors.grey : Colors.black, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: noDarurat.isEmpty 
                              ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada nomor kontak darurat!"))) 
                              : () => _teleponDarurat(noDarurat),
                          icon: Icon(Icons.call, color: noDarurat.isEmpty ? Colors.grey : Colors.black),
                          label: Text("TELEPON KONTAK DARURAT", style: TextStyle(color: noDarurat.isEmpty ? Colors.grey : Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Positioned(
                  top: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 8), 
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    child: const CircleAvatar(
                      radius: 45,
                      backgroundColor: Color(0xFFD07044), 
                      child: Icon(Icons.person, size: 55, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> mapMarkers = [
      Marker(
        point: LatLng(latPos, lonPos),
        width: 40, height: 40,
        child: const Icon(Icons.directions_bus, color: Colors.blue, size: 40),
      ),
    ];

    List<MapEntry<String, dynamic>> trackingList = _pesertaTracking.entries.toList();

    trackingList.sort((a, b) {
      if (a.value['status'] == "LUAR BATAS" && b.value['status'] == "AMAN") return -1;
      if (a.value['status'] == "AMAN" && b.value['status'] == "LUAR BATAS") return 1;
      return 0;
    });

    for (var peserta in trackingList) {
      double pLat = (peserta.value['latitude'] ?? 0).toDouble();
      double pLon = (peserta.value['longitude'] ?? 0).toDouble();
      bool isAman = peserta.value['status'] == "AMAN";
      String idPeserta = peserta.key;

      mapMarkers.add(
        Marker(
          point: LatLng(pLat, pLon),
          width: 50, height: 50, // Diperbesar sedikit agar mudah diklik dengan jari
          // ---> REVISI: FITUR MAP TO LIST (MARKER BISA DIKLIK) <---
          child: GestureDetector(
            onTap: () {
              // Menampilkan detail medis saat marker diklik
              _tampilkanDetailPeserta(idPeserta, peserta.value);
            },
            child: Icon(
              Icons.person_pin_circle, 
              color: isAman ? Colors.green : Colors.red, 
              size: 35
            ),
          ),
        )
      );
    }

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
                MarkerLayer(markers: mapMarkers),
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
                    child: trackingList.isEmpty
                        ? const Center(child: Text("Belum ada data pelacakan aktif", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: trackingList.length,
                            itemBuilder: (context, index) {
                              final idPeserta = trackingList[index].key;
                              final info = trackingList[index].value;
                              final status = info['status'] ?? '-';
                              final bool isAman = status == "AMAN";
                              
                              final detail = _mapDetailPeserta[idPeserta] ?? {};
                              final namaTampil = detail['NamaLengkap'] ?? idPeserta;

                              return ListTile(
                                leading: Icon(
                                  isAman ? Icons.check_circle : Icons.warning_amber_rounded,
                                  color: isAman ? Colors.green : Colors.red,
                                  size: 30,
                                ),
                                title: Text(namaTampil, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: const Text("Ketuk untuk cari lokasi & lihat detail", style: TextStyle(color: Colors.grey)),
                                trailing: const Icon(Icons.my_location, color: Colors.blue), // Ganti icon biar lebih pas maknanya
                                onTap: () {
                                  // ---> REVISI: FITUR LIST TO MAP (KAMERA MAP BERGERAK) <---
                                  double tLat = (info['latitude'] ?? 0).toDouble();
                                  double tLon = (info['longitude'] ?? 0).toDouble();
                                  
                                  // Menggeser peta ke posisi peserta yang diklik dengan zoom 18.0
                                  _mapController.move(LatLng(tLat, tLon), 18.0);
                                  
                                  // Menampilkan popup detail
                                  _tampilkanDetailPeserta(idPeserta, info);
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
      ),
    );
  }
}