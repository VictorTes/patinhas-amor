import 'package:flutter/material.dart';
import '../../models/pending_occurrence.dart';
import '../../services/moderation_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/moderation_card.dart'; // Import do seu novo widget
import 'moderation_detail_screen.dart';

class ModerationListScreen extends StatefulWidget {
  const ModerationListScreen({super.key});

  @override
  State<ModerationListScreen> createState() => _ModerationListScreenState();
}

class _ModerationListScreenState extends State<ModerationListScreen> {
  final ModerationService _moderationService = ModerationService();
  final AuthService _authService = AuthService();
  
  bool _isAdmin = false;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final userData = await _authService.getUserData();
    if (mounted) {
      setState(() {
        _isAdmin = userData?['role'] == 'admin';
        _checkingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (!_isAdmin) {
      return const Scaffold(
        body: Center(child: Text("Acesso negado. Apenas administradores.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Moderação (Pendentes)"),
        backgroundColor: Colors.orange[800],
        elevation: 0,
      ),
      body: StreamBuilder<List<PendingOccurrence>>(
        stream: _moderationService.getPendingOccurrences(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Erro ao carregar dados.\nVerifique sua conexão ou permissões."),
            );
          }

          final occurrences = snapshot.data ?? [];
          
          if (occurrences.isEmpty) {
            return const Center(
              child: Text("Nenhuma ocorrência aguardando revisão."),
            );
          }

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
    );
  }
}