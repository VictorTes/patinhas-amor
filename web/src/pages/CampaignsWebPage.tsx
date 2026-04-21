import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';
import 'widgets/campaign_card_web.dart';
import 'widgets/campaign_detail_modal.dart';

class CampaignsWebPage extends StatefulWidget {
  const CampaignsWebPage({super.key});

  @override
  State<CampaignsWebPage> createState() => _CampaignsWebPageState();
}

class _CampaignsWebPageState extends State<CampaignsWebPage> {
  final CampaignService _service = CampaignService();
  CampaignStatus? _filterStatus = CampaignStatus.ativa; // Filtro inicial

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Campanhas Solidárias', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          _buildFilterChips(),
          const SizedBox(width: 20),
        ],
      ),
      body: StreamBuilder<List<CampaignModel>>(
        stream: _service.getCampaignsStream(null),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Erro ao carregar dados.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Aplica o filtro de status localmente
          final campaigns = snapshot.data!.where((c) {
            if (_filterStatus == null) return true;
            return c.status == _filterStatus;
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400, // Largura máxima de cada card
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    mainAxisExtent: 450, // Altura fixa para manter o alinhamento
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = campaigns[index];
                      return CampaignCardWeb(
                        campaign: item,
                        onTap: () => _openDetail(item),
                      );
                    },
                    childCount: campaigns.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        FilterChip(
          label: const Text('Ativas'),
          selected: _filterStatus == CampaignStatus.ativa,
          onSelected: (val) => setState(() => _filterStatus = val ? CampaignStatus.ativa : null),
          selectedColor: Colors.orange.shade100,
          checkmarkColor: Colors.orange.shade900,
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('Concluídas'),
          selected: _filterStatus == CampaignStatus.finalizada,
          onSelected: (val) => setState(() => _filterStatus = val ? CampaignStatus.finalizada : null),
          selectedColor: Colors.grey.shade300,
        ),
      ],
    );
  }

  void _openDetail(CampaignModel campaign) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => CampaignDetailModal(campaign: campaign),
    );
  }
}