import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// TODO: Descomente e ajuste os imports das suas telas de detalhes correspondentes
// import 'package:patinhas_amor/screens/campaign_detail_screen.dart';
// import 'package:patinhas_amor/screens/animal_detail_screen.dart';
// import 'package:patinhas_amor/screens/register_occurrence_screen.dart';

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

          final activities = snapshot.data!.docs;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final doc = activities[index];
              final activity = doc.data() as Map<String, dynamic>;

              return Dismissible(
                // O Key precisa ser único para o Dismissible funcionar corretamente
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
                  // Apaga o documento do Firestore ao deslizar
                  FirebaseFirestore.instance.collection('activities').doc(doc.id).delete();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notificação apagada'),
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
                        _redirect(context, activity['type'], activity['targetId']);
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
    // TODO: Ajuste os nomes das classes (AnimalDetailScreen, etc.) conforme o seu projeto.
    
    /*
    Widget? targetScreen;

    switch (type) {
      case 'campanha':
        // targetScreen = CampaignDetailScreen(campaignId: targetId);
        break;
      case 'animal':
        // targetScreen = AnimalDetailScreen(animalId: targetId);
        break;
      case 'ocorrencia':
        // targetScreen = RegisterOccurrenceScreen(occurrenceId: targetId); 
        break;
    }

    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      );
      return;
    }
    */

    // Fallback temporário (Remova após implementar a navegação real acima)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ação de clique acionada. Tipo: $type | ID: $targetId'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}