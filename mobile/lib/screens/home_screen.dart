import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:patinhas_amor/screens/animals_list_screen.dart';
import 'package:patinhas_amor/screens/occurrences_list_screen.dart';
import 'package:patinhas_amor/screens/occurrences_map_screen.dart';
import 'package:patinhas_amor/screens/reports_screen.dart';
import 'package:patinhas_amor/widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const AppDrawer(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // Scroll mais fluido (estilo iOS)
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Builder(
          builder: (innerContext) => GestureDetector(
            onTap: () => Scaffold.of(innerContext).openDrawer(),
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 400),
              tween: Tween<double>(begin: 0.8, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(scale: value, child: child);
              },
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

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Container(
              key: ValueKey<String>(count), // Importante para o AnimatedSwitcher detectar mudança
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
        _buildAnimatedPress(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OccurrencesMapScreen()),
            );
          },
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[700]!],
              ),
              image: const DecorationImage(
                image: AssetImage('assets/images/map_static_preview.png'),
                fit: BoxFit.cover,
                opacity: 0.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 32, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "EXPLORAR MAPA",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
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
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ReportsScreen())),
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
    return _buildAnimatedPress(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
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
    );
  }

  // Widget auxiliar para animação de clique (escala)
  Widget _buildAnimatedPress({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      onTap: onTap,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        duration: const Duration(milliseconds: 100),
        builder: (context, double value, child) {
          return InkWell( // Adiciona o efeito visual de toque (Ripple)
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: child,
          );
        },
        child: child,
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade em desenvolvimento.')),
    );
  }
}