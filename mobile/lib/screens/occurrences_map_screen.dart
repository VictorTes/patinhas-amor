import 'dart:async'; // Necessário para o StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Importante!
import 'package:patinhas_amor/models/occurrence.dart';
import 'package:patinhas_amor/screens/occurrence_details_screen.dart';

class OccurrencesMapScreen extends StatefulWidget {
  const OccurrencesMapScreen({super.key});

  @override
  State<OccurrencesMapScreen> createState() => _OccurrencesMapScreenState();
}

class _OccurrencesMapScreenState extends State<OccurrencesMapScreen> {
  final LatLng _initialCenter = LatLng(-26.2295, -51.0878);
  final MapController _mapController = MapController();
  
  LatLng? _currentPalyerLocation; // Onde o usuário está agora
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initLocationService();
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // Limpa o stream ao sair da tela
    super.dispose();
  }

  // --- LÓGICA DE LOCALIZAÇÃO DO USUÁRIO ---

  Future<void> _initLocationService() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Verifica se o GPS do celular está ligado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // 2. Verifica/Pede permissão
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // 3. Começa a escutar a posição em tempo real
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Atualiza a cada 10 metros
      ),
    ).listen((Position position) {
      setState(() {
        _currentPalyerLocation = LatLng(position.latitude, position.longitude);
      });
    });
  }

  // --- WIDGETS VISUAIS ---

  Widget _buildUserLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, spreadRadius: 5),
        ],
      ),
    );
  }

  Widget _buildCustomMarker(String status) {
    return Container(
      decoration: BoxDecoration(
        color: _getMarkerColor(status),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: const Icon(Icons.pets, size: 20, color: Colors.white),
    );
  }

  Color _getMarkerColor(String status) {
    switch (status) {
      case 'pending': return Colors.redAccent;
      case 'in_progress': return Colors.blueAccent;
      default: return Colors.orange;
    }
  }

  

  // --- MODAL DE DETALHES (Resumido para o exemplo) ---

  void _showOccurrenceDetails(Map<String, dynamic> data, String docId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(data['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 20),
              Text(data['type'] ?? 'Ocorrência', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(data['description'] ?? '', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => OccurrenceDetailsScreen(occurrence: Occurrence.fromJson(data, docId: docId))));
                },
                child: const Text("VER DETALHES COMPLETOS", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de Ocorrências"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('occurrences')
            .where('status', whereNotIn: ['resolved', 'completed'])
            .snapshots(),
        builder: (context, snapshot) {
          List<Marker> markers = [];

          // 1. Adiciona o Ponto Azul do Usuário (se a localização foi capturada)
          if (_currentPalyerLocation != null) {
            markers.add(
              Marker(
                point: _currentPalyerLocation!,
                width: 25,
                height: 25,
                child: _buildUserLocationMarker(),
              ),
            );
          }

          // 2. Adiciona as Ocorrências do Firebase
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final double lat = (data['latitude'] ?? 0.0).toDouble();
              final double lng = (data['longitude'] ?? 0.0).toDouble();

              if (lat != 0.0) {
                markers.add(
                  Marker(
                    point: LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showOccurrenceDetails(data, doc.id),
                      child: _buildCustomMarker(data['status'] ?? 'pending'),
                    ),
                  ),
                );
              }
            }
          }

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.patinhas_amor.app',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
      // Botão flutuante para centralizar no usuário
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          if (_currentPalyerLocation != null) {
            _mapController.move(_currentPalyerLocation!, 16.0);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Aguardando sinal do GPS...")),
            );
          }
        },
        child: const Icon(Icons.my_location, color: Colors.blue),
      ),
    );
  }
}