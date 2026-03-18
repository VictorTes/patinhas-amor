import 'package:cloud_firestore/cloud_firestore.dart';

enum AnimalStatus {
  underTreatment,
  availableForAdoption,
  adopted,
  missing,
}

extension AnimalStatusExtension on AnimalStatus {
  String get value {
    switch (this) {
      case AnimalStatus.underTreatment:
        return 'under_treatment';
      case AnimalStatus.availableForAdoption:
        return 'available_for_adoption';
      case AnimalStatus.adopted:
        return 'adopted';
      case AnimalStatus.missing:
        return 'missing';
    }
  }

  String get label {
    switch (this) {
      case AnimalStatus.underTreatment:
        return 'Em Tratamento';
      case AnimalStatus.availableForAdoption:
        return 'Disponível para Adoção';
      case AnimalStatus.adopted:
        return 'Adotado';
      case AnimalStatus.missing:
        return 'Desaparecido';
    }
  }
}

class Animal {
  final String? id; 
  final String name;
  final String species;
  final int? age;
  final String description;
  final AnimalStatus status;
  final String? imageUrl;
  final DateTime? rescueDate;
  final String? sex;
  final String? size;
  final String? adopterName;
  final String? adopterAddress;
  final String? adopterPhone;

  Animal({
    this.id,
    required this.name,
    required this.species,
    this.age,
    required this.description,
    required this.status,
    this.imageUrl,
    this.rescueDate,
    this.sex,
    this.size,
    this.adopterName,
    this.adopterAddress,
    this.adopterPhone,
  });

  factory Animal.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Animal(
      id: docId ?? json['id'] as String?, 
      name: json['name'] as String? ?? '',
      species: json['species'] as String? ?? '',
      // Tratamento para garantir que idade seja int, mesmo que o Firebase mande double
      age: json['age'] is num ? (json['age'] as num).toInt() : null,
      description: json['description'] as String? ?? '',
      status: _parseStatus(json['status'] as String? ?? ''),
      imageUrl: json['imageUrl'] as String?,
      // Tratamento para DateTime: o Firebase pode mandar String ou Timestamp
      rescueDate: _parseDate(json['rescueDate']),
      sex: json['sex'] as String?,
      size: json['size'] as String?,
      adopterName: json['adopterName'] as String?,
      adopterAddress: json['adopterAddress'] as String?,
      adopterPhone: json['adopterPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      if (age != null) 'age': age,
      'description': description,
      'status': status.value,
      if (imageUrl != null) 'imageUrl': imageUrl,
      // Ao salvar, convertemos para String ISO8601 para manter compatibilidade
      if (rescueDate != null) 'rescueDate': rescueDate!.toIso8601String(),
      if (sex != null) 'sex': sex,
      if (size != null) 'size': size,
      if (adopterName != null) 'adopterName': adopterName,
      if (adopterAddress != null) 'adopterAddress': adopterAddress,
      if (adopterPhone != null) 'adopterPhone': adopterPhone,
    };
  }

  static AnimalStatus _parseStatus(String status) {
    switch (status) {
      case 'under_treatment':
        return AnimalStatus.underTreatment;
      case 'available_for_adoption':
        return AnimalStatus.availableForAdoption;
      case 'adopted':
        return AnimalStatus.adopted;
      case 'missing':
        return AnimalStatus.missing;
      default:
        return AnimalStatus.underTreatment;
    }
  }

  // Função auxiliar para evitar erros de tipo com datas
  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date);
    return null;
  }
}