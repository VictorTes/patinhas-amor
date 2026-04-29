import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';

class CampanhasView extends StatefulWidget {
  const CampanhasView({super.key});

  @override
  State<CampanhasView> createState() => _CampanhasViewState();
}

class _CampanhasViewState extends State<CampanhasView> {
  final CampaignService _service = CampaignService();
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campanhas e Rifas'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: _buildList(null), // Null traz todas as campanhas juntas
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/criar-campanha'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(String? statusFilter) {
    return StreamBuilder<List<CampaignModel>>(
      stream: _service.getCampaignsStream(statusFilter),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar dados.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final campaigns = snapshot.data ?? [];

        if (campaigns.isEmpty) {
          return const Center(child: Text('Nenhuma campanha encontrada.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            return _buildCampaignCard(campaigns[index]);
          },
        );
      },
    );
  }

  Widget _buildCampaignCard(CampaignModel campaign) {
    bool isRifa = campaign.type == CampaignType.rifa;
    String statusStr = campaign.status.name;
    bool isActive = campaign.status == CampaignStatus.ativa; // Verifica se está ativa
    String title = campaign.title;
    String imageUrl = campaign.imageUrl ?? 'https://via.placeholder.com/400x200';

    double goalValue = campaign.goalValue ?? 0;
    double currentValue = campaign.totalCollected ?? 0;
    double price = campaign.ticketValue ?? 0;

    double progress = 0;
    if (isRifa && goalValue > 0) {
      progress = currentValue / goalValue;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context, 
          '/detalhe-campanha', 
          arguments: campaign.id 
        ),
        child: Stack(
          children: [
            // CONTEÚDO PRINCIPAL (Com efeito cinza/opacidade se inativo)
            Opacity(
              opacity: isActive ? 1.0 : 0.6, // Fica meio "apagado" se não for ativa
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ColorFiltered(
                    colorFilter: isActive 
                      ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                      : const ColorFilter.mode(Colors.grey, BlendMode.saturation), // Efeito cinza na imagem
                    child: Image.network(
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
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isRifa ? '🎟️ RIFA' : '🛍️ BAZAR',
                              style: TextStyle(
                                color: isActive ? Colors.orange.shade900 : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            if (isRifa)
                              Text(
                                '${currencyFormat.format(price)}/nº',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (isRifa) ...[
                          LinearProgressIndicator(
                            value: progress > 1 ? 1 : progress,
                            backgroundColor: Colors.grey.shade200,
                            color: isActive ? Colors.orange.shade600 : Colors.grey,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Arrecadado: ${currencyFormat.format(currentValue)} / ${currencyFormat.format(goalValue)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                        if (!isRifa) ...[
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  campaign.address ?? 'Endereço não informado',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
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
            // STATUS COLORIDO (Posicionado acima do conteúdo e sem opacidade/filtro)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(statusStr),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Text(
                  statusStr.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ativa':
        return Colors.green;
      case 'concluida':
        return Colors.blue;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}