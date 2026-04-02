import 'package:flutter/material.dart';
import '../../models/pending_occurrence.dart';
import '../../services/moderation_service.dart';
import '../../widgets/moderation_card.dart';
import '../../widgets/role_guard.dart';
import 'moderation_detail_screen.dart';

class ModerationListScreen extends StatelessWidget {
  const ModerationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ModerationService moderationService = ModerationService();

    return RoleGuard(
      // Fallback estilizado para acesso negado
      fallback: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Apenas administradores podem acessar esta área de moderação.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "Moderação",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          actions: [
            // Badge indicativo de revisão pendente (estético)
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
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: StreamBuilder<List<PendingOccurrence>>(
          stream: moderationService.getPendingOccurrences(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      "Erro ao carregar moderação",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {}, // Adicione lógica de retry se necessário
                      child: const Text("Tentar novamente"),
                    )
                  ],
                ),
              );
            }

            final occurrences = snapshot.data ?? [];

            if (occurrences.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async => (context as Element).markNeedsBuild(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: occurrences.length,
                itemBuilder: (context, index) {
                  final item = occurrences[index];
                  
                  // Animação de entrada suave
                  return AnimatedOpacity(
                    duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 500)),
                    opacity: 1.0,
                    curve: Curves.easeIn,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ModerationCard(
                        occurrence: item,
                        onTap: () => _navigateToDetail(context, item),
                      ),
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
        transitionsBuilder: (c, anim, a2, child) => 
          FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green[400]),
          ),
          const SizedBox(height: 24),
          const Text(
            "Tudo em dia!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Nenhuma ocorrência aguardando revisão.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}