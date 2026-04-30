import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Imports dos fluxos de detalhes do projeto
import 'package:patinhas_amor/screens/campaign_detail_screen.dart';
import 'package:patinhas_amor/screens/animals_list_screen.dart';
import 'package:patinhas_amor/screens/occurrence_details_screen.dart';

// O modelo Occurrence importado para tipagem no redirecionamento
import 'package:patinhas_amor/models/occurrence.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  // Armazena os IDs das atividades que foram dispensadas/apagadas pelo usuário localmente
  final Set<String> _dismissedIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mural de Atividades'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activities')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma atividade recente.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // Filtra os documentos para ignorar os excluídos localmente
          final allDocs = snapshot.data!.docs;
          final activeActivities = allDocs
              .where((doc) => !_dismissedIds.contains(doc.id))
              .toList();

          if (activeActivities.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma atividade recente.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: activeActivities.length,
            itemBuilder: (context, index) {
              final doc = activeActivities[index];
              final activity = doc.data() as Map<String, dynamic>;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart, // Deslizar da direita para a esquerda
                background: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white, size: 28),
                ),
                onDismissed: (direction) {
                  // Adiciona o ID ao conjunto de itens ignorados sem apagar do Firestore
                  setState(() {
                    _dismissedIds.add(doc.id);
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notificação apagada localmente'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: _getIcon(activity['type']),
                    title: Text(
                      activity['title'] ?? 'Novo item',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        activity['description'] ?? '',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
                    onTap: () {
                      if (activity['targetId'] != null) {
                        _redirect(
                          context,
                          activity['type'],
                          activity['targetId'],
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getIcon(String? type) {
    switch (type) {
      case 'campanha':
        return const CircleAvatar(
          backgroundColor: Colors.deepOrange,
          child: Icon(Icons.confirmation_number, color: Colors.white),
        );
      case 'animal':
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.pets, color: Colors.white),
        );
      case 'ocorrencia':
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.notification_important, color: Colors.white),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.star, color: Colors.white),
        );
    }
  }

  void _redirect(BuildContext context, String? type, String targetId) {
    Widget? targetScreen;

    switch (type) {
      case 'campanha':
        targetScreen = CampaignDetailScreen(campaignId: targetId);
        break;
      case 'animal':
        // Como 'AnimalsListScreen' é usada para listagem geral, você pode redirecionar para ela ou adicionar um DetailScreen caso possua.
        targetScreen = const AnimalsListScreen();
        break;
      case 'ocorrencia':
        // Caso possua o objeto Occurrence completo, adapte se o targetId for uma string
        targetScreen = OccurrenceDetailsScreen(
          occurrence: Occurrence(
            id: targetId,
            type: '',
            status: OccurrenceStatus.pending, // Selecione o status padrão adequado
            description: '',
            location: '',
          ),
        );
        break;
    }

    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen!),
      );
      return;
    }

    // Fallback caso nenhuma tela seja compatível
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando para detalhes. Tipo: $type | ID: $targetId'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}