import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representando os possíveis status de uma ocorrência.
enum OccurrenceStatus {
  pending,
  inProgress,
  resolved,
}

/// Extensão para facilitar a conversão do enum para String e labels da UI
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
  });

  /// Converte um documento do Firestore em um objeto Occurrence
  factory Occurrence.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Occurrence(
      id: docId ?? json['id'] as String?,
      type: json['type'] as String? ?? 'Outro',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      createdAt: _parseDate(json['createdAt'] ?? json['timestamp']),
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      resolutionDescription: json['resolutionDescription'] as String?,
    );
  }

  /// Converte o objeto para um mapa para salvar no Firestore
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'status': status.value,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'resolutionDescription': resolutionDescription,
    };
  }

  /// Cria uma cópia da ocorrência alterando apenas os campos desejados.
  /// 
  /// NOTA: Para campos que podem ser nulos (como resolutionDescription),
  /// usamos uma verificação para permitir que o valor seja resetado para null.
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
    // Usamos dynamic ou uma lógica de fallback para permitir null real
    Object? resolutionDescription = _sentinel, 
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
      // Se passarmos algo (incluindo null), ele usa. Se não passarmos nada, mantém o antigo.
      resolutionDescription: resolutionDescription == _sentinel 
          ? this.resolutionDescription 
          : resolutionDescription as String?,
    );
  }

  // Valor estático privado usado apenas para identificar quando o parâmetro não foi passado
  static const _sentinel = Object();

  static OccurrenceStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return OccurrenceStatus.pending;
      case 'in_progress':
        return OccurrenceStatus.inProgress;
      case 'resolved':
        return OccurrenceStatus.resolved;
      default:
        return OccurrenceStatus.pending;
    }
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date);
    return null;
  }
}