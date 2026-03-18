/// Represents an occurrence (report) of animal abandonment or abuse.
///
/// Occurrences are submitted by the public through the web platform
/// and managed by the NGO team through this mobile app.

/// Enum representing the possible statuses of an occurrence.
enum OccurrenceStatus {
  pending,
  inProgress,
  resolved,
}

/// Extension to provide string conversion for OccurrenceStatus
extension OccurrenceStatusExtension on OccurrenceStatus {
  /// Converts the enum to a string value for API
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

  /// Returns a user-friendly label for the status
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

/// Model class representing an occurrence report.
class Occurrence {
  /// Unique identifier for the occurrence
  final int id;

  /// Type of occurrence (e.g., abandonment, abuse, injured)
  final String type;

  /// Detailed description of the occurrence
  final String description;

  /// Location where the occurrence was reported
  final String location;

  /// Current status of the occurrence
  final OccurrenceStatus status;

  /// Date when the occurrence was reported
  final DateTime? createdAt;

  Occurrence({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    required this.status,
    this.createdAt,
  });

  /// Creates an Occurrence from a JSON map (API response)
  factory Occurrence.fromJson(Map<String, dynamic> json) {
    return Occurrence(
      id: json['id'],
      type: json['type'],
      description: json['description'],
      location: json['location'],
      status: _parseStatus(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  /// Converts the Occurrence to a JSON map for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'location': location,
      'status': status.value,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Creates a copy of this Occurrence with the given fields replaced
  Occurrence copyWith({
    int? id,
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

  /// Parses a status string into an OccurrenceStatus enum
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
}
