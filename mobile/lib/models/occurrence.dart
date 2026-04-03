import 'package:cloud_firestore/cloud_firestore.dart';

enum OccurrenceStatus { pending, inProgress, resolved }

extension OccurrenceStatusExtension on OccurrenceStatus {
  String get value {
    switch (this) {
      case OccurrenceStatus.pending:
        return 'pending';
      case OccurrenceStatus.inProgress:
        return 'in_progress';
      case OccurrenceStatus.resolved:
        return 'resolved';
    }
  }

  String get label {
    switch (this) {
      case OccurrenceStatus.pending:
        return 'Pendente';
      case OccurrenceStatus.inProgress:
        return 'Em Andamento';
      case OccurrenceStatus.resolved:
        return 'Resolvida';
    }
  }
}

class Occurrence {
  final String? id;
  final String type;
  final String description;
  final String location;
  final String? imageUrl;
  final OccurrenceStatus status;
  final DateTime? createdAt;
  final double? latitude;
  final double? longitude;
  final String? resolutionDescription;
  
  // Campo que identifica a moderação vinda da Web
  final String? statusWeb; 

  Occurrence({
    this.id,
    required this.type,
    required this.description,
    required this.location,
    this.imageUrl,
    required this.status,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.resolutionDescription,
    this.statusWeb,
  });

  factory Occurrence.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Occurrence.fromJson(data, docId: doc.id);
  }

  factory Occurrence.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Occurrence(
      id: docId ?? json['id'] as String?,
      type: (json['type'] ?? json['animalType']) as String? ?? 'Outro',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      createdAt: _parseDate(json['createdAt'] ?? json['timestamp']),
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      resolutionDescription: json['resolutionDescription'] as String?,
      // Mapeia o campo vindo do Firestore (geralmente status_web)
      statusWeb: json['status_web'] as String? ?? json['statusWeb'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'type': type,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'status': status.value,
      'latitude': latitude,
      'longitude': longitude,
      'resolutionDescription': resolutionDescription,
      'status_web': statusWeb, // Salva de volta se necessário
    };

    if (createdAt != null) {
      data['createdAt'] = Timestamp.fromDate(createdAt!);
    }

    return data;
  }

  Occurrence copyWith({
    String? id,
    String? type,
    String? description,
    String? location,
    String? imageUrl,
    OccurrenceStatus? status,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
    Object? resolutionDescription = _sentinel,
    String? statusWeb,
  }) {
    return Occurrence(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      statusWeb: statusWeb ?? this.statusWeb,
      resolutionDescription: resolutionDescription == _sentinel 
          ? this.resolutionDescription 
          : resolutionDescription as String?,
    );
  }

  static const _sentinel = Object();

  static OccurrenceStatus _parseStatus(String status) {
    switch (status) {
      case 'pending': return OccurrenceStatus.pending;
      case 'in_progress': 
      case 'inProgress': return OccurrenceStatus.inProgress;
      case 'resolved': 
      case 'completed': return OccurrenceStatus.resolved;
      default: return OccurrenceStatus.pending;
    }
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date);
    return null;
  }
}