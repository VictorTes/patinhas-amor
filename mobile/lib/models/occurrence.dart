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
  /// O ID agora é String para suportar o padrão do Firestore (ex: "abc123XYZ")
  final String? id; 
  final String type;
  final String description;
  final String location;
  final OccurrenceStatus status;
  final DateTime? createdAt;

  Occurrence({
    this.id,
    required this.type,
    required this.description,
    required this.location,
    required this.status,
    this.createdAt,
  });

  /// Converte um documento do Firestore em um objeto Occurrence
  factory Occurrence.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Occurrence(
      id: docId ?? json['id'] as String?,
      type: json['type'] as String? ?? 'Outro',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      createdAt: _parseDate(json['createdAt'] ?? json['timestamp']),
    );
  }

  /// Converte o objeto para um mapa para salvar no Firestore
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'location': location,
      'status': status.value,
      // Usamos serverTimestamp para garantir a hora correta do servidor
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Cria uma cópia da ocorrência alterando apenas os campos desejados
  Occurrence copyWith({
    String? id,
    String? type,
    String? description,
    String? location,
    OccurrenceStatus? status,
    DateTime? createdAt,
  }) {
    return Occurrence(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Helper para transformar String do banco no Enum correspondente
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

  /// Helper robusto para lidar com datas (Timestamp ou ISO String)
  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date);
    return null;
  }
}