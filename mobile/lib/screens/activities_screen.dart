import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  // Armazena os IDs das atividades que foram dispensadas/apagadas pelo usuário
  final Set<String> _dismissedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDismissedIds();
  }

  // Carrega os IDs salvos localmente
  Future<void> _loadDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('dismissed_activity_ids') ?? [];
    
    if (mounted) {
      setState(() {
        _dismissedIds.addAll(savedIds);
        _isLoading = false;
      });
    }
  }

  // Salva os IDs no dispositivo
  Future<void> _saveDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dismissed_activity_ids', _dismissedIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

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

          // Filtra os documentos para ignorar os excluídos localmente e persistidos
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
                direction: DismissDirection.endToStart,
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
                  // Adiciona o ID ao conjunto e salva no dispositivo
                  setState(() {
                    _dismissedIds.add(doc.id);
                  });
                  _saveDismissedIds();

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
}