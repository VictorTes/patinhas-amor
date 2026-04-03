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

  late AnimationController _pulseController;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initLocationService();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      _updateLocalState(position);
    } catch (e) {
      debugPrint("Erro ao obter posição inicial: $e");
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, 
        distanceFilter: 5,
      ),
    ).listen((Position position) => _updateLocalState(position));
  }

  void _updateLocalState(Position position) {
    if (mounted) {
      setState(() {
        _currentPalyerLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    }
  }

  // --- WIDGETS VISUAIS ---

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.orange, strokeWidth: 3),
          const SizedBox(height: 20),
          Text(
            "Carregando mapa...",
            style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildUserLocationMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 15 + (_pulseController.value * 25),
              height: 15 + (_pulseController.value * 25),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.4 * (1 - _pulseController.value)),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ],
        );
      },
    );
  }

  // MODIFICADO: Agora recebe se é Web ou não
  Widget _buildCustomMarker(String status, bool isWeb) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _getMarkerColor(status),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: const Center(
            child: Icon(Icons.pets, size: 18, color: Colors.white),
          ),
        ),
        if (isWeb)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.public, size: 12, color: Colors.white),
            ),
          ),
      ],
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

  void _showOccurrenceDetails(Map<String, dynamic> data, String docId) {
    final bool isWeb = data['status_web'] != null || data['statusWeb'] != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
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
                  child: Image.network(data['imageUrl'], height: 220, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 20),
              if (isWeb)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.public, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text("ORIGEM: PORTAL WEB", 
                        style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(data['type'] ?? 'Ocorrência', 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                  ),
                  _buildStatusBadge(data['status'] ?? ''),
                ],
              ),
              const SizedBox(height: 10),
              Text(data['description'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => OccurrenceDetailsScreen(
                    occurrence: Occurrence.fromJson(data, docId: docId)
                  )));
                },
                child: const Text("DETALHES DO RESGATE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getMarkerColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(color: _getMarkerColor(status), fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de Ocorrências", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _isLoadingLocation 
          ? _buildLoadingWidget()
          : StreamBuilder<QuerySnapshot>(
              key: const ValueKey('map_content'),
              stream: FirebaseFirestore.instance
                  .collection('occurrences')
                  .where('status', whereNotIn: ['resolved', 'completed'])
                  .snapshots(),
              builder: (context, snapshot) {
                List<Marker> markers = [];

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

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final double lat = (data['latitude'] ?? 0.0).toDouble();
                    final double lng = (data['longitude'] ?? 0.0).toDouble();
                    
                    // Verifica se veio da web
                    final bool isFromWeb = data['status_web'] != null || data['statusWeb'] != null;

                    if (lat != 0.0) {
                      markers.add(
                        Marker(
                          point: LatLng(lat, lng),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _showOccurrenceDetails(data, doc.id),
                            child: _buildCustomMarker(data['status'] ?? 'pending', isFromWeb),
                          ),
                        ),
                      );
                    }
                  }
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPalyerLocation ?? _initialCenter,
                    initialZoom: 15.0,
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          if (_currentPalyerLocation != null) {
            _mapController.move(_currentPalyerLocation!, 16.5);
          }
        },
        child: const Icon(Icons.my_location, color: Colors.blueAccent),
      ),
    );
  }
}