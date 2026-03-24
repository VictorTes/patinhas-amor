import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 

class OccurrencesMapScreen extends StatefulWidget {
  const OccurrencesMapScreen({super.key});

  @override
  State<OccurrencesMapScreen> createState() => _OccurrencesMapScreenState();
}

class _OccurrencesMapScreenState extends State<OccurrencesMapScreen> {
  // Ponto central do mapa (Porto União / União da Vitória)
  final LatLng _initialCenter = LatLng(-26.2295, -51.0878);

  // Define a cor do ícone baseada no status da ocorrência
  Color _getMarkerColor(String status) {
    switch (status) {
      case 'pending': return Colors.red;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.green;
      default: return Colors.orange;
    }
  }

  // Mostra os detalhes ao clicar no Pin
  void _showOccurrenceDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['animalType'] ?? 'Animal',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.pets, color: Colors.orange[300]),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Descrição da Situação:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(data['description'] ?? 'Sem descrição detalhada.'),
            const SizedBox(height: 12),
            Text("Status: ${data['status']?.toUpperCase() ?? 'N/A'}", 
              style: TextStyle(color: _getMarkerColor(data['status'] ?? ''), fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("VOLTAR AO MAPA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
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
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('occurrences').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Erro ao carregar mapa."));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orange));

          // Mapeia os documentos do Firestore para a lista de Marcadores
          final markers = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Converte para double com segurança
            final double lat = (data['latitude'] ?? 0.0).toDouble();
            final double lng = (data['longitude'] ?? 0.0).toDouble();

            return Marker(
              point: LatLng(lat, lng),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showOccurrenceDetails(data),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sombra/Efeito de pulso simples para o Pin
                    Icon(Icons.location_on, size: 45, color: _getMarkerColor(data['status'] ?? 'pending')),
                    const Positioned(
                      top: 10,
                      child: Icon(Icons.circle, size: 12, color: Colors.white),
                    ),
                  ],
                ),
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