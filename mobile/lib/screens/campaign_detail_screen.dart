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
      stream: service.getCampaignsStream(null),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text('Erro ao carregar')));
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final campaigns = snapshot.data!;
        final campaign = campaigns
            .cast<CampaignModel?>()
            .firstWhere((c) => c?.id == campaignId, orElse: () => null);

        if (campaign == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Campanha não encontrada.')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
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
                      MaterialPageRoute(
                        builder: (context) => CampaignFormScreen(campaign: campaign),
                      ),
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
                        Text(campaign.title,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(campaign.description,
                            style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const Divider(height: 40),
                        if (campaign.type == CampaignType.rifa)
                          _buildRifaProgress(campaign, currencyFormat),
                        if (campaign.type == CampaignType.bazar)
                          _buildBazarInfo(campaign),
                        const SizedBox(height: 30),
                        if (campaign.hasAccountability)
                          _buildAccountability(campaign, currencyFormat),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showManageProgressSheet(context, campaign, service),
            label: Text(campaign.type == CampaignType.rifa ? 'GERENCIAR NÚMEROS' : 'ATUALIZAR VENDAS'),
            icon: const Icon(Icons.edit_notifications),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      },
    );
  }

  // Painel Inferior para edição rápida de valores
  void _showManageProgressSheet(BuildContext context, CampaignModel campaign, CampaignService service) {
    final controller = TextEditingController(text: campaign.currentValue?.toString() ?? '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20, left: 20, right: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Atualizar Progresso', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Campanha: ${campaign.title}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Total Arrecadado (R\$)',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () async {
                  final newValue = double.tryParse(controller.text) ?? 0;
                  
                  // Atualiza apenas o campo currentValue preservando o restante
                  final updated = campaign.copyWith(currentValue: newValue);
                  
                  await service.saveCampaign(updated, null, []);
                  
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('SALVAR ALTERAÇÕES'),
              ),
            ),
          ],
        ),
      ),
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
    if (progress > 1.0) progress = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Progresso da Arrecadação', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${(progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
        Text('Arrecadado: ${fmt.format(c.currentValue ?? 0)} / Meta: ${fmt.format(c.goalValue ?? 0)}',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.location_on, color: Colors.red),
          title: const Text('Localização'),
          subtitle: Text(c.address ?? 'Não informado'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
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
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
          color: Colors.grey[50],
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Final Arrecadado:'),
                    Text(fmt.format(c.totalCollected ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const Divider(),
                if (c.expenses == null || c.expenses!.isEmpty)
                  const Text('Nenhuma despesa registrada.', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
        if (c.receiptUrls != null && c.receiptUrls!.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: c.receiptUrls!.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(c.receiptUrls![index], width: 100, height: 100, fit: BoxFit.cover),
                ),
              ),
            ),
          )
        else
          const Text('Nenhum comprovante anexado.', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}