import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:patinhas_amor/models/occurrence.dart'; 
import 'package:patinhas_amor/screens/occurrence_details_screen.dart'; 

class OccurrencesMapScreen extends StatefulWidget {
  const OccurrencesMapScreen({super.key});

  @override
  State<OccurrencesMapScreen> createState() => _OccurrencesMapScreenState();
}

class _OccurrencesMapScreenState extends State<OccurrencesMapScreen> {
  final LatLng _initialCenter = LatLng(-26.2295, -51.0878);

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'PENDENTE';
      case 'in_progress': return 'EM ANDAMENTO';
      default: return 'DESCONHECIDO';
    }
  }

  Color _getMarkerColor(String status) {
    switch (status) {
      case 'pending': return Colors.redAccent;
      case 'in_progress': return Colors.blueAccent;
      default: return Colors.orange;
    }
  }

  // Widget de marcador personalizado mais moderno
  Widget _buildCustomMarker(String status) {
    return Container(
      decoration: BoxDecoration(
        color: _getMarkerColor(status),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.pets, // Ícone de patinha combinando com o app
        size: 20,
        color: Colors.white,
      ),
    );
  }

  void _showOccurrenceDetails(Map<String, dynamic> data, String docId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50, height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    data['imageUrl'],
                    height: 200, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120, color: Colors.grey[200], child: const Icon(Icons.broken_image),
                    ),
                  ),
                )
              else
                Container(
                  height: 120, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(15)),
                  child: Icon(Icons.pets, size: 50, color: Colors.orange[200]),
                ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['animalType'] ?? data['type'] ?? 'Animal Desconhecido',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getMarkerColor(data['status'] ?? '').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(data['status'] ?? ''),
                      style: TextStyle(
                        color: _getMarkerColor(data['status'] ?? ''),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Descrição:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(data['description'] ?? 'Sem descrição.', style: TextStyle(fontSize: 15, color: Colors.grey[800])),
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        final occurrence = Occurrence.fromJson(data, docId: docId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OccurrenceDetailsScreen(occurrence: occurrence),
                          ),
                        );
                      },
                      child: const Text("MAIS DETALHES", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text("FECHAR", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
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
        title: const Text("Mapa de Resgates"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FILTRO APLICADO: Onde o status NÃO É IGUAL a 'resolved'
        stream: FirebaseFirestore.instance
            .collection('occurrences')
            .where('status', whereNotIn: ['resolved', 'completed'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Erro ao carregar mapa."));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orange));

          final markers = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String docId = doc.id;
            
            final double lat = (data['latitude'] ?? 0.0).toDouble();
            final double lng = (data['longitude'] ?? 0.0).toDouble();

            return Marker(
              point: LatLng(lat, lng),
              width: 40, 
              height: 40,
              child: GestureDetector(
                onTap: () => _showOccurrenceDetails(data, docId),
                child: _buildCustomMarker(data['status'] ?? 'pending'),
              ),
            );
          }).toList();

          return FlutterMap(
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
    );
  }
}