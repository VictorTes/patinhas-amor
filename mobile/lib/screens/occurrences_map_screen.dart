import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:patinhas_amor/models/occurrence.dart';
import 'package:patinhas_amor/screens/occurrence_details_screen.dart';

class OccurrencesMapScreen extends StatefulWidget {
  const OccurrencesMapScreen({super.key});

  @override
  State<OccurrencesMapScreen> createState() => _OccurrencesMapScreenState();
}

class _OccurrencesMapScreenState extends State<OccurrencesMapScreen> with TickerProviderStateMixin {
  final LatLng _initialCenter = LatLng(-26.2295, -51.0878);
  final MapController _mapController = MapController();
  
  LatLng? _currentPalyerLocation; 
  StreamSubscription<Position>? _positionStream;

  // Controlador da animação de pulso
  late AnimationController _pulseController;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // 1. Inicializa a animação primeiro
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _pulseController.repeat(reverse: true);
    
    setState(() {
      _isControllerInitialized = true;
    });

    // 2. Inicia o GPS
    _initLocationService();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, 
        distanceFilter: 5, // Atualiza a cada 5 metros para ser mais suave
      ),
    ).listen((Position position) {
      if (mounted) {
        LatLng newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPalyerLocation = newLocation;
        });

        // FAZ O MAPA SEGUIR O USUÁRIO AUTOMATICAMENTE
        _mapController.move(newLocation, _mapController.camera.zoom);
      }
    });
  }

  // --- WIDGETS VISUAIS ---

  Widget _buildUserLocationMarker() {
    if (!_isControllerInitialized) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Efeito de pulsação/brilho
            Container(
              width: 20 + (_pulseController.value * 25),
              height: 20 + (_pulseController.value * 25),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.4 * (1 - _pulseController.value)),
                shape: BoxShape.circle,
              ),
            ),
            // Ponto central
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
            ),
          ],
        );
      },
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'PENDENTE';
      case 'in_progress': return 'EM ANDAMENTO';
      default: return 'DESCONHECIDO';
    }
  }

  // --- MODAL DE DETALHES ---

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(data['type'] ?? 'Ocorrência', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMarkerColor(data['status'] ?? '').withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusLabel(data['status'] ?? ''),
                      style: TextStyle(color: _getMarkerColor(data['status'] ?? ''), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(data['description'] ?? '', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
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

          // 1. Marcador do Usuário (Animado)
          if (_currentPalyerLocation != null) {
            markers.add(
              Marker(
                point: _currentPalyerLocation!,
                width: 60,
                height: 60,
                child: _buildUserLocationMarker(),
              ),
            );
          }

          // 2. Marcadores das Ocorrências
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          if (_currentPalyerLocation != null) {
            _mapController.move(_currentPalyerLocation!, 17.0);
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