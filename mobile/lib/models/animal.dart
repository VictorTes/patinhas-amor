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
      case AnimalStatus.underTreatment: return 'under_treatment';
      case AnimalStatus.availableForAdoption: return 'available_for_adoption';
      case AnimalStatus.adopted: return 'adopted';
      case AnimalStatus.missing: return 'missing';
    }
  }

  String get label {
    switch (this) {
      case AnimalStatus.underTreatment: return 'Em Tratamento';
      case AnimalStatus.availableForAdoption: return 'Disponível para Adoção';
      case AnimalStatus.adopted: return 'Adotado';
      case AnimalStatus.missing: return 'Desaparecido';
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
  
  // Dados do Adotante (Existentes)
  final String? adopterName;
  final String? adopterAddress;
  final String? adopterPhone;

  // --- NOVO CAMPO DE TEXTO ---
  final String? currentLocation; // Ex: "Lar Temporário - Casa da Maria" ou "Clínica Vet Vida"

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
    this.currentLocation,
  });

  factory Animal.fromJson(Map<String, dynamic> json, {String? docId}) {
    String? _nullIfEmpty(dynamic value) {
      if (value == null || (value is String && value.isEmpty)) return null;
      return value.toString();
    }

    return Animal(
      id: docId ?? json['id'] as String?, 
      name: json['name'] as String? ?? '',
      species: json['species'] as String? ?? '',
      age: json['age'] is num ? (json['age'] as num).toInt() : null,
      description: json['description'] as String? ?? '',
      status: _parseStatus(json['status'] as String? ?? ''),
      imageUrl: _nullIfEmpty(json['imageUrl']),
      rescueDate: _parseDate(json['rescueDate']),
      sex: _nullIfEmpty(json['sex']),
      size: _nullIfEmpty(json['size']),
      adopterName: _nullIfEmpty(json['adopterName']),
      adopterAddress: _nullIfEmpty(json['adopterAddress']),
      adopterPhone: _nullIfEmpty(json['adopterPhone']),
      // Novo campo com trava de segurança
      currentLocation: _nullIfEmpty(json['currentLocation']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'age': age,
      'description': description,
      'status': status.value,
      'imageUrl': imageUrl,
      'rescueDate': rescueDate != null ? Timestamp.fromDate(rescueDate!) : null,
      'sex': sex,
      'size': size,
      'adopterName': adopterName,
      'adopterAddress': adopterAddress,
      'adopterPhone': adopterPhone,
      // Salva o novo campo no Firebase
      'currentLocation': currentLocation,
    };
  }

  static AnimalStatus _parseStatus(String status) {
    switch (status) {
      case 'under_treatment': return AnimalStatus.underTreatment;
      case 'available_for_adoption': return AnimalStatus.availableForAdoption;
      case 'adopted': return AnimalStatus.adopted;
      case 'missing': return AnimalStatus.missing;
      default: return AnimalStatus.underTreatment;
    }
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date);
    return null;
  }
}