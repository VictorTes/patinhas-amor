import 'package:cloud_firestore/cloud_firestore.dart';

enum CampaignType { rifa, bazar, outro }
enum CampaignStatus { ativa, concluida, cancelada }

class ExpenseItem {
  final String description;
  final double value;

  ExpenseItem({required this.description, required this.value});

  Map<String, dynamic> toMap() => {
    'description': description,
    'value': value,
  };

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      description: map['description'] ?? '',
      value: (map['value'] ?? 0).toDouble(),
    );
  }
}

class CampaignModel {
  final String? id;
  final String title;
  final String description;
  final CampaignType type;
  final CampaignStatus status;
  final String? imageUrl;
  final DateTime? createdAt;
  
  // Campos específicos de Rifa
  final double? goalValue;
  final double? currentValue;
  final double? ticketValue;
  final String? prize;
  
  // Campos específicos de Bazar
  final String? address;
  final String? itemsForSale;

  // Prestação de Contas
  final bool hasAccountability;
  final double? totalCollected;
  final List<ExpenseItem>? expenses;
  final List<String>? receiptUrls;

  CampaignModel({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.imageUrl,
    this.createdAt,
    this.goalValue,
    this.currentValue,
    this.ticketValue,
    this.prize,
    this.address,
    this.itemsForSale,
    this.hasAccountability = false,
    this.totalCollected,
    this.expenses,
    this.receiptUrls,
  });
  

  // Converte objeto para Map (Salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'imageUrl': imageUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'goalValue': goalValue,
      'currentValue': currentValue,
      'ticketValue': ticketValue,
      'prize': prize,
      'address': address,
      'itemsForSale': itemsForSale,
      'hasAccountability': hasAccountability,
      'totalCollected': totalCollected,
      'expenses': expenses?.map((e) => e.toMap()).toList(),
      'receiptUrls': receiptUrls,
    };
  }

  // Converte Firestore para Objeto (Ler do Banco)
  factory CampaignModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CampaignModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: CampaignType.values.firstWhere((e) => e.name == data['type']),
      status: CampaignStatus.values.firstWhere((e) => e.name == data['status']),
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      goalValue: (data['goalValue'] as num?)?.toDouble(),
      currentValue: (data['currentValue'] as num?)?.toDouble(),
      ticketValue: (data['ticketValue'] as num?)?.toDouble(),
      prize: data['prize'],
      address: data['address'],
      itemsForSale: data['itemsForSale'],
      hasAccountability: data['hasAccountability'] ?? false,
      totalCollected: (data['totalCollected'] as num?)?.toDouble(),
      expenses: (data['expenses'] as List?)
          ?.map((e) => ExpenseItem.fromMap(e))
          .toList(),
      receiptUrls: List<String>.from(data['receiptUrls'] ?? []),
    );
  }
}