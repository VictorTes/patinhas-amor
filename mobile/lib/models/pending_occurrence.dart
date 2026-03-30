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
  });

  factory PendingOccurrence.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PendingOccurrence(
      id: doc.id,
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      location: data['location'] ?? '',
      reporterName: data['reporterName'] ?? '',
      reporterPhone: data['reporterPhone'] ?? '',
      type: data['type'] ?? '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }
}