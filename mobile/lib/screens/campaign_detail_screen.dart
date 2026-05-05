import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';
import 'campaign_form_screen.dart';

class CampaignDetailScreen extends StatelessWidget {
  final String campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  // Método para exibir imagem em tela cheia com botão fechar
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy'); 
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
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBadge(campaign),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 24, color: Colors.grey),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CampaignFormScreen(campaign: campaign),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(campaign.title,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(campaign.description,
                            style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const Divider(height: 40),
                        
                        if (campaign.type == CampaignType.rifa)
                          _buildRifaProgress(context, campaign, currencyFormat, dateFormat),
                        if (campaign.type == CampaignType.evento)
                          _buildBazarInfo(campaign),
                          
                        const SizedBox(height: 30),
                        if (campaign.hasAccountability)
                          _buildAccountability(context, campaign, currencyFormat),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
          // O FloatingActionButton foi removido conforme solicitado.
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
        c.type == CampaignType.rifa ? '🎟️ RIFA' : '🛍️ EVENTO',
        style: TextStyle(
          color: c.type == CampaignType.rifa ? Colors.purple : Colors.orange.shade900,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRifaProgress(BuildContext context, CampaignModel c, NumberFormat fmt, DateFormat dateFmt) {
    double rawProgress = (c.totalCollected ?? 0) / (c.goalValue ?? 1);
    double visualProgress = rawProgress > 1.0 ? 1.0 : rawProgress;
    bool isGoalReached = (c.totalCollected ?? 0) >= (c.goalValue ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Progresso da Arrecadação', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${(rawProgress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.orange, 
                  fontWeight: FontWeight.bold
                )),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: visualProgress,
            minHeight: 15,
            backgroundColor: Colors.grey[200],
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 10),
        if (isGoalReached)
          const Text('🎉 Meta atingida!', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
        Text('Arrecadado: ${fmt.format(c.totalCollected ?? 0)} / Meta: ${fmt.format(c.goalValue ?? 0)}',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        
        if (c.drawDate != null) ...[
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.blue.shade800),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data do Sorteio', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(
                      dateFmt.format(c.drawDate!),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        if (c.winner != null && c.winner!.isNotEmpty) ...[
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GANHADOR(A)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                      Text(
                        c.winner!.toUpperCase(),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        if (c.prize != null) ...[
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prêmio'),
                    Text(c.prize!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (c.prizeImageUrl != null) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _showFullScreenImage(context, c.prizeImageUrl!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(c.prizeImageUrl!, height: 120, width: 120, fit: BoxFit.cover),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
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

  Widget _buildAccountability(BuildContext context, CampaignModel c, NumberFormat fmt) {
    final double totalExpenses = c.expenses?.fold(0.0, (sum, item) => sum! + item.value) ?? 0;
    final double totalCollected = c.totalCollected ?? 0;
    final double netValue = totalCollected - totalExpenses;

    // Define as cores baseadas no saldo
    final Color netValueColor = netValue < 0 ? Colors.red : Colors.green.shade600;
    final Color collectedColor = totalCollected < totalExpenses ? Colors.red : Colors.green.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            const Text('Prestação de Contas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Arrecadado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      fmt.format(totalCollected), 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: collectedColor)
                    ),
                  ],
                ),

                const Divider(height: 24),

                if (c.expenses != null && c.expenses!.isNotEmpty) ...[
                  ...c.expenses!.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
                        Text('- ${fmt.format(e.value)}', style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
                  const Divider(height: 24),
                ],
                
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saldo Final', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      fmt.format(netValue), 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: netValueColor)
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
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
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context, c.receiptUrls![index]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(c.receiptUrls![index], width: 100, height: 100, fit: BoxFit.cover),
                  ),
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