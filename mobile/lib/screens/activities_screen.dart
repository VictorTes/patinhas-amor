import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

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
            .limit(20) // Limita para as 20 últimas atualizações
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma atividade recente.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final activities = snapshot.data!.docs;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index].data() as Map<String, dynamic>;
              
              return Card(
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
                      _redirect(context, activity['type'], activity['targetId']);
                    }
                  },
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
    // Você pode importar e redirecionar para as telas de detalhes correspondentes aqui
    // Exemplo:
    /*
    if (type == 'campanha') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CampaignDetailScreen(campaignId: targetId),
        ),
      );
    } else if (type == 'animal') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimalDetailScreen(animalId: targetId),
        ),
      );
    }
    */
    
    // Como alternativa, você pode exibir apenas um SnackBar temporário para teste:
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Redirecionando para o item ID: $targetId')),
    );
  }
}