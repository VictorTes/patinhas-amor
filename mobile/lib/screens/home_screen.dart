import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:patinhas_amor/screens/animals_list_screen.dart';
import 'package:patinhas_amor/screens/occurrences_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 24),
              // Dashboard com contadores e legendas
              _buildLiveSummarySection(),
              const SizedBox(height: 24),
              _buildMapPreview(),
              const SizedBox(height: 32),
              _buildGridNavigation(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Cabeçalho com Logo e Nome da ONG
  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.orange[100],
          backgroundImage: const AssetImage('assets/images/logo.png'),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patinhas e Amor',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: Colors.orange
              ),
            ),
            Text(
              'Painel Administrativo',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.grey),
          onPressed: () {
            // Futura implementação de notificações
          },
        )
      ],
    );
  }

  /// Seção de Estatísticas com legendas explicativas
  Widget _buildLiveSummarySection() {
    return Row(
      children: [
        _buildCounterStream(
          collection: 'occurrences',
          field: 'status',
          value: 'pending',
          label: 'Pendentes',
          color: Colors.redAccent,
          description: 'Novas denúncias',
        ),
        const SizedBox(width: 10),
        _buildCounterStream(
          collection: 'occurrences',
          field: 'status',
          value: 'in_progress',
          label: 'Em Curso',
          color: Colors.blue,
          description: 'Sendo atendidas',
        ),
        const SizedBox(width: 10),
        _buildCounterStream(
          collection: 'animals',
          label: 'Acolhidos',
          color: Colors.green,
          isTotalCount: true,
          description: 'Total na ONG',
        ),
      ],
    );
  }

  /// Helper para criar um StreamBuilder que conta documentos com legenda
  Widget _buildCounterStream({
    required String collection,
    String? field,
    String? value,
    required String label,
    required Color color,
    required String description,
    bool isTotalCount = false,
  }) {
    Query query = FirebaseFirestore.instance.collection(collection);
    
    if (!isTotalCount && field != null && value != null) {
      query = query.where(field, isEqualTo: value);
    }

    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          String count = '...';
          if (snapshot.hasData) {
            count = snapshot.data!.docs.length.toString().padLeft(2, '0');
          }

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: color
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.black87
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9, 
                    color: Colors.grey[500], 
                    fontStyle: FontStyle.italic
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Preview do Mapa (Visualização rápida)
  Widget _buildMapPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mapa de Ocorrências',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 160,
            width: double.infinity,
            color: Colors.blue[50],
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.map_outlined, size: 50, color: Colors.blueAccent),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      // Sugestão: Navegar para uma tela de mapa em tela cheia
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.fullscreen, color: Colors.blueAccent),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Menu de navegação em Grid
  Widget _buildGridNavigation(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMenuItem(
          context,
          'Ocorrências',
          Icons.notification_important_outlined,
          Colors.orange,
          () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (c) => const OccurrencesListScreen())
          ),
        ),
        _buildMenuItem(
          context,
          'Animais',
          Icons.pets_outlined,
          Colors.green,
          () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (c) => const AnimalsListScreen())
          ),
        ),
        _buildMenuItem(
          context,
          'Relatórios',
          Icons.analytics_outlined,
          Colors.blueAccent,
          () => _showComingSoon(context), 
        ),
        _buildMenuItem(
          context,
          'Configurações',
          Icons.settings_outlined,
          Colors.blueGrey,
          () => _showComingSoon(context),
        ),
      ],
    );
  }

  /// Botão do Menu Principal
  Widget _buildMenuItem(
    BuildContext context, 
    String title, 
    IconData icon, 
    Color color, 
    VoidCallback onTap
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento para o TCC.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}