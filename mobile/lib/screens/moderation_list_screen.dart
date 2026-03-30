import 'package:flutter/material.dart';
import '../../models/pending_occurrence.dart';
import '../../services/moderation_service.dart';

class ModerationListScreen extends StatelessWidget {
  final ModerationService _service = ModerationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Moderação (Pendentes)")),
      body: StreamBuilder<List<PendingOccurrence>>(
        stream: _service.getPendingOccurrences(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Nenhuma ocorrência pendente."));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(item.type),
                  subtitle: Text(item.location),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => ModerationDetailScreen(occurrence: item))
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