import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Necessário para formatar a data
import '../../models/pending_occurrence.dart';
import '../../services/moderation_service.dart';
import 'moderation_detail_screen.dart'; // Importação da tela de detalhes

class ModerationListScreen extends StatelessWidget {
  ModerationListScreen({super.key}); // Adicionado construtor padrão
  
  final ModerationService _service = ModerationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Moderação (Pendentes)"),
        backgroundColor: Colors.orange[800], // Mantendo sua paleta de cores
      ),
      body: StreamBuilder<List<PendingOccurrence>>(
        stream: _service.getPendingOccurrences(),
        builder: (context, snapshot) {
          // 1. Estado de Carregamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 2. Tratamento de Erros de Leitura do Firestore
          if (snapshot.hasError) {
             return Center(
               child: Text(
                 "Erro ao carregar dados: ${snapshot.error}",
                 textAlign: TextAlign.center,
               )
             );
          }

          // 3. Empty State (Tudo moderado)
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    "Tudo limpo!\nNenhuma ocorrência pendente.", 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              )
            );
          }

          // 4. Lista de Ocorrências
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              
              // Formata a data para exibir no card (ex: 26/03/2026 22:44)
              final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl, 
                      width: 60, 
                      height: 60, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60, 
                        height: 60, 
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                  title: Text(
                    item.type, 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        item.location, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Enviado em: $dateStr", 
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.orange),
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => ModerationDetailScreen(occurrence: item)
                    )
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}