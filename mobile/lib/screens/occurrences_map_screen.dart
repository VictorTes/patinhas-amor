import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong2.dart'; // Importação essencial

class OccurrencesMapScreen extends StatefulWidget {
  const OccurrencesMapScreen({super.key});

  @override
  State<OccurrencesMapScreen> createState() => _OccurrencesMapScreenState();
}

class _OccurrencesMapScreenState extends State<OccurrencesMapScreen> {
  // Removi o 'const' aqui para evitar conflito se o compilador não reconhecer o LatLng como constante de cara
  final LatLng _initialCenter = LatLng(-26.2295, -51.0878);

  Color _getMarkerColor(String status) {
    switch (status) {
      case 'pending': return Colors.red;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.green;
      default: return Colors.orange;
    }
  }

  void _showOccurrenceDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['animalType'] ?? 'Animal',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Situação: ${data['description'] ?? 'Sem descrição'}"),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("FECHAR", style: TextStyle(color: Colors.white)),
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('occurrences').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Erro ao carregar dados."));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Criando a lista de Marcadores
          final markers = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Garantindo que os valores sejam double
            final double lat = (data['latitude'] ?? 0.0).toDouble();
            final double lng = (data['longitude'] ?? 0.0).toDouble();

            return Marker(
              point: LatLng(lat, lng), // Aqui o LatLng deve ser reconhecido agora
              width: 45,
              height: 45,
              child: GestureDetector(
                onTap: () => _showOccurrenceDetails(data),
                child: Icon(
                  Icons.location_on,
                  size: 45,
                  color: _getMarkerColor(data['status'] ?? 'pending'),
                ),
              ),
            );
          }).toList();

          return FlutterMap(
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 13.0,
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