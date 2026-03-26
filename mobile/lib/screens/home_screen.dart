import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:patinhas_amor/screens/animals_list_screen.dart';
import 'package:patinhas_amor/screens/occurrences_list_screen.dart';
import 'package:patinhas_amor/screens/occurrences_map_screen.dart';
import 'package:patinhas_amor/screens/reports_screen.dart'; // Import da tela de relatórios
import 'package:patinhas_amor/widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildLiveSummarySection(),
              const SizedBox(height: 24),
              _buildMapPreview(context),
              const SizedBox(height: 32),
              _buildGridNavigation(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Cabeçalho com Logo clicável para abrir o Drawer
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Builder(
          builder: (innerContext) => GestureDetector(
            onTap: () => Scaffold.of(innerContext).openDrawer(),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange[100],
                  backgroundImage: const AssetImage('assets/images/logo.png'),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu, color: Colors.white, size: 12),
                ),
              ],
            ),
          ),
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
                  color: Colors.orange),
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
          onPressed: () => _showComingSoon(context),
        )
      ],
    );
  }

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
          String count = '00';
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
                      fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ocorrências em Tempo Real',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const OccurrencesMapScreen()),
            );
          },
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[400]!,
                  Colors.blue[700]!,
                ],
              ),
              image: const DecorationImage(
                image: AssetImage('assets/images/map_static_preview.png'),
                fit: BoxFit.cover,
                opacity: 0.4,
                colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(Icons.circle, size: 100, color: Colors.white10),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.map_outlined,
                            size: 32, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "EXPLORAR MAPA",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.blue[800],
                                  letterSpacing: 0.5),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios,
                                size: 12, color: Colors.blue[800]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
          () => Navigator.push(context,
              MaterialPageRoute(builder: (c) => const OccurrencesListScreen())),
        ),
        _buildMenuItem(
          context,
          'Animais',
          Icons.pets_outlined,
          Colors.green,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (c) => const AnimalsListScreen())),
        ),
        _buildMenuItem(
          context,
          'Relatórios',
          Icons.analytics_outlined,
          Colors.blueAccent,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (c) => const ReportsScreen())),
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

  Widget _buildMenuItem(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
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
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
        content: Text('Funcionalidade em desenvolvimento.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}