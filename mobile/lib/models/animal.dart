enum AnimalStatus {
  underTreatment,
  availableForAdoption,
  adopted,
  missing, // 1. Nova opção adicionada
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
        return 'missing'; // 2. Valor para persistência (banco/API)
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
        return 'Desaparecido'; // 3. Label para interface
    }
  }
}

class Animal {
  final int id;
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
    required this.id,
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

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'],
      name: json['name'],
      species: json['species'],
      age: json['age'],
      description: json['description'],
      status: _parseStatus(json['status']),
      imageUrl: json['imageUrl'],
      rescueDate: json['rescueDate'] != null
          ? DateTime.parse(json['rescueDate'])
          : null,
      sex: json['sex'],
      size: json['size'],
      adopterName: json['adopterName'],
      adopterAddress: json['adopterAddress'],
      adopterPhone: json['adopterPhone'],
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
        return AnimalStatus.missing; // 4. Mapeamento da leitura do JSON
      default:
        return AnimalStatus.underTreatment;
    }
  }
}