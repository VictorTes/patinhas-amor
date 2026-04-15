enum CampaignType { rifa, bazar, outro }
enum CampaignStatus { ativa, concluida, cancelada }

class CampaignModel {
  final String id;
  final String title;
  final String description;
  final CampaignType type;
  final CampaignStatus status;
  final String? imageUrl;
  final DateTime createdAt;
  
  // Rifa
  final double? goalValue;
  final double? currentValue;
  final double? ticketValue;
  final String? prize;
  
  // Bazar
  final String? address;
  final String? itemsForSale;

  CampaignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.imageUrl,
    required this.createdAt,
    this.goalValue,
    this.currentValue,
    this.ticketValue,
    this.prize,
    this.address,
    this.itemsForSale,
  });

  // Factory para converter do Firestore
  factory CampaignModel.fromMap(String id, Map<String, dynamic> map) {
    return CampaignModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: CampaignType.values.firstWhere((e) => e.name == map['type']),
      status: CampaignStatus.values.firstWhere((e) => e.name == map['status']),
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as dynamic).toDate(),
      goalValue: (map['goalValue'] as num?)?.toDouble(),
      currentValue: (map['currentValue'] as num?)?.toDouble(),
      ticketValue: (map['ticketValue'] as num?)?.toDouble(),
      prize: map['prize'],
      address: map['address'],
      itemsForSale: map['itemsForSale'],
    );
  }
}