import 'package:flutter/material.dart';
import '../../models/pending_occurrence.dart';
import '../../services/moderation_service.dart';
import '../../widgets/moderation_card.dart';
import '../../widgets/role_guard.dart'; // Import do RoleGuard atualizado
import 'moderation_detail_screen.dart';

class ModerationListScreen extends StatelessWidget {
  const ModerationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ModerationService moderationService = ModerationService();

    return RoleGuard(
      // Caso não seja admin, o fallback exibe uma tela de erro em vez de ficar em branco
      fallback: Scaffold(
        appBar: AppBar(backgroundColor: Colors.orange[800]),
        body: const Center(
          child: Text("Acesso negado. Apenas administradores podem acessar esta área."),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Moderação (Pendentes)"),
          backgroundColor: Colors.orange[800],
          elevation: 0,
        ),
        body: StreamBuilder<List<PendingOccurrence>>(
          stream: moderationService.getPendingOccurrences(),
          builder: (context, snapshot) {
            // 1. Estado de Carregamento do Firestore
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              );
            }

            // 2. Tratamento de Erro
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Erro ao carregar dados.\nVerifique sua conexão ou permissões no Firebase.",
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // 3. Lista de Ocorrências
            final occurrences = snapshot.data ?? [];
            
            // Caso a lista esteja vazia
            if (occurrences.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.done_all_rounded, size: 64, color: Colors.green[300]),
                    const SizedBox(height: 16),
                    const Text(
                      "Nenhuma ocorrência aguardando revisão.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            // 4. Exibição com o Widget Customizado
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: occurrences.length,
              itemBuilder: (context, index) {
                final item = occurrences[index];
                return ModerationCard(
                  occurrence: item,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ModerationDetailScreen(occurrence: item),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}