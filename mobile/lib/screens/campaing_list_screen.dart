import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatar moeda (R$)

class CampanhasView extends StatefulWidget {
  const CampanhasView({super.key}); // Adicionado const no construtor da classe

  @override
  _CampanhasViewState createState() => _CampanhasViewState();
}

class _CampanhasViewState extends State<CampanhasView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Formatador de moeda profissional do pacote intl
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Campanhas e Rifas'), // Adicionado const
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
          bottom: const TabBar( // Adicionado const
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Ativas'),
              Tab(text: 'Concluídas'),
              Tab(text: 'Todas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList('ativa'),
            _buildList('concluida'),
            _buildList(null),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/criar-campanha'),
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add), // Adicionado const
        ),
      ),
    );
  }

  Widget _buildList(String? statusFilter) {
    Query query = _firestore.collection('campaigns');
    
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter); 
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Erro ao carregar dados.'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('Nenhuma campanha encontrada.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12), // Adicionado const
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return _buildCampaignCard(data, docs[index].id);
          },
        );
      },
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> data, String id) {
    bool isRifa = data['type'] == 'rifa';
    String status = data['status'] ?? 'desconhecida';
    String title = data['title'] ?? 'Sem Título';
    String imageUrl = data['imageUrl'] ?? 'https://via.placeholder.com/400x200';
    
    double goalValue = (data['goalValue'] ?? 0).toDouble();
    double currentValue = (data['currentValue'] ?? 0).toDouble();
    double price = (data['pricePerNumber'] ?? 0).toDouble();
    
    double progress = 0;
    if (isRifa && goalValue > 0) {
      progress = currentValue / goalValue;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16), // Adicionado const
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/detalhe-campanha', arguments: id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Adicionado const
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(15), // Adicionado const
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isRifa ? '🎟️ RIFA' : '🛍️ BAZAR',
                        style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      if (isRifa) 
                        Text('${currencyFormat.format(price)}/nº', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 5), // Adicionado const
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8), // Adicionado const
                  
                  if (isRifa) ...[
                    LinearProgressIndicator(
                      value: progress > 1 ? 1 : progress,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.orange.shade600,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 5), // Adicionado const
                    Text(
                      'Arrecadado: ${currencyFormat.format(currentValue)} / ${currencyFormat.format(goalValue)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],

                  if (!isRifa) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey), // Adicionado const
                        const SizedBox(width: 4), // Adicionado const
                        Expanded(
                          child: Text(
                            data['address'] ?? 'Endereço não informado', 
                            style: const TextStyle(fontSize: 12, color: Colors.grey)
                          )
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ativa': return Colors.green;
      case 'concluida': return Colors.blue;
      case 'cancelada': return Colors.red;
      default: return Colors.grey;
    }
  }
}