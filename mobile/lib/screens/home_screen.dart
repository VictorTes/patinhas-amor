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
              // Seção de Estatísticas em Tempo Real
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

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.orange[100],
          // Certifique-se que o caminho da imagem está correto no seu pubspec.yaml
          backgroundImage: const AssetImage('assets/images/logo.png'),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patinhas e Amor',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
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
          onPressed: () {}, // Aqui entrará a navegação de notificações futuramente
        )
      ],
    );
  }

  /// Widgets que buscam os dados reais do Firestore
  Widget _buildLiveSummarySection() {
    return Row(
      children: [
        _buildCounterStream(
          collection: 'occurrences',
          field: 'status',
          value: 'pending',
          label: 'Pendentes',
          color: Colors.redAccent,
        ),
        const SizedBox(width: 12),
        _buildCounterStream(
          collection: 'occurrences',
          field: 'status',
          value: 'in_progress',
          label: 'Em Aberto',
          color: Colors.blue,
        ),
        const SizedBox(width: 12),
        _buildCounterStream(
          collection: 'animals', // Nome da sua coleção de animais resgatados
          label: 'Resgatados',
          color: Colors.green,
          isTotalCount: true, // Para animais, buscamos o total geral
        ),
      ],
    );
  }

  /// Helper para criar um StreamBuilder que conta documentos
  Widget _buildCounterStream({
    required String collection,
    String? field,
    String? value,
    required String label,
    required Color color,
    bool isTotalCount = false,
  }) {
    Query query = FirebaseFirestore.instance.collection(collection);
    
    // Aplica o filtro (WHERE) se não for contagem total
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
            padding: const EdgeInsets.all(16),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
                // Aqui você pode colocar o seu widget de mapa real reduzido
                const Center(
                  child: Icon(Icons.map_outlined, size: 50, color: Colors.blueAccent),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    onPressed: () {}, // Abrir mapa em tela cheia
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
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const OccurrencesListScreen())),
        ),
        _buildMenuItem(
          context,
          'Animais',
          Icons.pets_outlined,
          Colors.green,
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AnimalsListScreen())),
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

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
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
      const SnackBar(content: Text('Funcionalidade em desenvolvimento para o TCC.')),
    );
  }
}