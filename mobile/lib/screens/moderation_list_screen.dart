import 'package:flutter/material.dart';
import '../../models/pending_occurrence.dart';
import '../../services/moderation_service.dart';
import '../../widgets/moderation_card.dart';
import '../../widgets/role_guard.dart';
import 'moderation_detail_screen.dart';

class ModerationListScreen extends StatefulWidget {
  const ModerationListScreen({super.key});

  @override
  State<ModerationListScreen> createState() => _ModerationListScreenState();
}

class _ModerationListScreenState extends State<ModerationListScreen> {
  final ModerationService moderationService = ModerationService();

  // Função para forçar o rebuild se necessário
  Future<void> _onRefresh() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    // PROTEÇÃO: RoleGuard configurado para cargos administrativos
    return RoleGuard(
      requiredRole: 'admin', // Se o seu RoleGuard permitir listas, use ['admin', 'superAdmin']
      fallback: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_person_outlined, size: 80, color: Colors.red[300]),
                const SizedBox(height: 24),
                const Text(
                  "Acesso Restrito", 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 12),
                const Text(
                  "Apenas administradores podem acessar esta área de moderação.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("VOLTAR"),
                )
              ],
            ),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("Moderação", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "PENDENTES",
                  style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: StreamBuilder<List<PendingOccurrence>>(
          stream: moderationService.getPendingOccurrences(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.orange));
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text("Erro ao carregar moderação", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () => setState(() {}), child: const Text("Tentar novamente")),
                  ],
                ),
              );
            }

            final occurrences = snapshot.data ?? [];

            if (occurrences.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: Colors.orange,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: occurrences.length,
                itemBuilder: (context, index) {
                  final item = occurrences[index];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ModerationCard(
                      occurrence: item,
                      onTap: () => _navigateToDetail(context, item),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, PendingOccurrence item) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => ModerationDetailScreen(occurrence: item),
        transitionsBuilder: (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green[400]),
            ),
            const SizedBox(height: 24),
            const Text("Tudo em dia!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Nenhuma ocorrência aguardando revisão.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}