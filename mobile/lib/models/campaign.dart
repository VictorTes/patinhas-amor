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
  final String? prizeImageUrl;
  final DateTime? drawDate; // Data do Sorteio

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
    this.prizeImageUrl,
    this.drawDate,
    this.address,
    this.itemsForSale,
    this.hasAccountability = false,
    this.totalCollected,
    this.expenses,
    this.receiptUrls,
  });

  CampaignModel copyWith({
    String? title,
    String? description,
    CampaignStatus? status,
    double? currentValue,
    double? goalValue,
    String? imageUrl,
    String? prize,
    String? prizeImageUrl,
    DateTime? drawDate,
    List<String>? receiptUrls,
    List<ExpenseItem>? expenses,
    double? totalCollected,
  }) {
    return CampaignModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      goalValue: goalValue ?? this.goalValue,
      currentValue: currentValue ?? this.currentValue,
      ticketValue: ticketValue,
      prize: prize ?? this.prize,
      prizeImageUrl: prizeImageUrl ?? this.prizeImageUrl,
      drawDate: drawDate ?? this.drawDate,
      address: address,
      itemsForSale: itemsForSale,
      hasAccountability: hasAccountability,
      totalCollected: totalCollected ?? this.totalCollected,
      expenses: expenses ?? this.expenses,
      receiptUrls: receiptUrls ?? this.receiptUrls,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'imageUrl': imageUrl,
      // Se createdAt for nulo (nova campanha), o Firestore gera o tempo no servidor
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'goalValue': goalValue,
      'currentValue': currentValue,
      'ticketValue': ticketValue,
      'prize': prize,
      'prizeImageUrl': prizeImageUrl,
      // Conversão segura de DateTime para Timestamp do Firebase
      'drawDate': drawDate != null ? Timestamp.fromDate(drawDate!) : null,
      'address': address,
      'itemsForSale': itemsForSale,
      'hasAccountability': hasAccountability,
      'totalCollected': totalCollected,
      'expenses': expenses?.map((e) => e.toMap()).toList(),
      'receiptUrls': receiptUrls,
    };
  }

  factory CampaignModel.fromFirestore(DocumentSnapshot doc) {
    // Garantia de que data nunca será null para evitar crash
    Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
    
    return CampaignModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: CampaignType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => CampaignType.outro,
      ),
      status: CampaignStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'ativa'),
        orElse: () => CampaignStatus.ativa,
      ),
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      goalValue: (data['goalValue'] as num?)?.toDouble(),
      currentValue: (data['currentValue'] as num?)?.toDouble(),
      ticketValue: (data['ticketValue'] as num?)?.toDouble(),
      prize: data['prize'],
      prizeImageUrl: data['prizeImageUrl'],
      // Conversão segura de Timestamp do Firebase para DateTime do Dart
      drawDate: (data['drawDate'] as Timestamp?)?.toDate(),
      address: data['address'],
      itemsForSale: data['itemsForSale'],
      hasAccountability: data['hasAccountability'] ?? false,
      totalCollected: (data['totalCollected'] as num?)?.toDouble(),
      expenses: (data['expenses'] as List?)
          ?.map((e) => ExpenseItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      receiptUrls: data['receiptUrls'] != null ? List<String>.from(data['receiptUrls']) : [],
    );
  }
}