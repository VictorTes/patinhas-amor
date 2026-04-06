import 'package:cloud_firestore/cloud_firestore.dart';

class PendingOccurrence {
  final String id;
  final String description;
  final String imageUrl;
  final String location;
  final String reporterName;
  final String reporterPhone;
  final String type;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String status;
  final String protocol; 

  PendingOccurrence({
    required this.id,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.reporterName,
    required this.reporterPhone,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.status,
    required this.protocol,
  });

  factory PendingOccurrence.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return PendingOccurrence(
      id: doc.id,
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      reporterName: data['reporterName']?.toString() ?? 'Anônimo',
      reporterPhone: data['reporterPhone']?.toString() ?? '',
      type: data['type']?.toString() ?? 'Geral',
      
      // Conversão segura de num para double
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      
      // Conversão segura de data
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : (data['timestamp'] is Timestamp 
              ? (data['timestamp'] as Timestamp).toDate() 
              : DateTime.now()),
          
      status: data['status']?.toString() ?? 'pending',

      protocol: doc.id,
    );
  }
}