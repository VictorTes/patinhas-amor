import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';
import 'campaign_form_screen.dart';

class CampaignDetailScreen extends StatelessWidget {
  final String campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final CampaignService service = CampaignService();

    return StreamBuilder<List<CampaignModel>>(
      // Filtramos a stream para pegar apenas esta campanha específica
      stream: service.getCampaignsStream(null), 
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        // Localiza a campanha pelo ID dentro da lista da stream
        final campaign = snapshot.data!.firstWhere((c) => c.id == campaignId);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Cabeçalho com imagem expansível
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    campaign.imageUrl ?? 'https://via.placeholder.com/600x300',
                    fit: BoxFit.cover,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CampaignFormScreen(campaign: campaign)),
                    ),
                  ),
                ],
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBadge(campaign),
                        const SizedBox(height: 10),
                        Text(campaign.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(campaign.description, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const Divider(height: 40),
                        
                        if (campaign.type == CampaignType.rifa) _buildRifaProgress(campaign, currencyFormat),
                        if (campaign.type == CampaignType.bazar) _buildBazarInfo(campaign),
                        
                        const SizedBox(height: 30),
                        if (campaign.hasAccountability) _buildAccountability(campaign, currencyFormat),
                        
                        const SizedBox(height: 100), // Espaço para não bater no fundo
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
          floatingActionButton: campaign.type == CampaignType.rifa 
              ? FloatingActionButton.extended(
                  onPressed: () { /* Lógica para marcar números vendidos */ },
                  label: const Text('GERENCIAR NÚMEROS'),
                  icon: const Icon(Icons.list_alt),
                  backgroundColor: Colors.orange.shade800,
                )
              : null,
        );
      },
    );
  }

  Widget _buildBadge(CampaignModel c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.type == CampaignType.rifa ? Colors.purple.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        c.type == CampaignType.rifa ? '🎟️ RIFA' : '🛍️ BAZAR',
        style: TextStyle(
          color: c.type == CampaignType.rifa ? Colors.purple : Colors.orange.shade900,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRifaProgress(CampaignModel c, NumberFormat fmt) {
    double progress = (c.currentValue ?? 0) / (c.goalValue ?? 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Progresso da Arrecadação', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 15,
            backgroundColor: Colors.grey[200],
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 10),
        Text('Meta: ${fmt.format(c.goalValue)}', style: const TextStyle(color: Colors.grey)),
        if (c.prize != null) ...[
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
            title: const Text('Prêmio'),
            subtitle: Text(c.prize!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ]
      ],
    );
  }

  Widget _buildBazarInfo(CampaignModel c) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.location_on, color: Colors.red),
          title: const Text('Localização'),
          subtitle: Text(c.address ?? 'Não informado'),
        ),
        ListTile(
          leading: const Icon(Icons.shopping_bag, color: Colors.blue),
          title: const Text('Itens Disponíveis'),
          subtitle: Text(c.itemsForSale ?? 'Verificar no local'),
        ),
      ],
    );
  }

  Widget _buildAccountability(CampaignModel c, NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📊 Prestação de Contas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Card(
          color: Colors.grey[50],
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Arrecadado:'),
                    Text(fmt.format(c.totalCollected ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const Divider(),
                ...?c.expenses?.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.description),
                      Text('- ${fmt.format(e.value)}', style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text('Comprovantes:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: c.receiptUrls?.length ?? 0,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(c.receiptUrls![index], width: 100, height: 100, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ],
    );
  }
}