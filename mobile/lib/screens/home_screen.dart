import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:patinhas_amor/screens/animals_list_screen.dart';
import 'package:patinhas_amor/screens/occurrences_list_screen.dart';
import 'package:patinhas_amor/screens/occurrences_map_screen.dart';
import 'package:patinhas_amor/widgets/app_drawer.dart';
import 'package:patinhas_amor/screens/campaing_list_screen.dart'; // Importação do botão de campanhas

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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(context),
                const SizedBox(height: 30),
                _buildLiveSummarySection(),
                const SizedBox(height: 30),
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
    return SizedBox(
      height: 130,
      child: Row(
        children: [
          _buildCounterStream(
            collection: 'occurrences',
            field: 'status',
            value: 'pending',
            label: 'Pendentes',
            color: Colors.redAccent,
            description: 'Novas denúncias',
          ),
          const SizedBox(width: 12),
          _buildCounterStream(
            collection: 'occurrences',
            field: 'status',
            value: 'in_progress',
            label: 'Em Curso',
            color: Colors.blue,
            description: 'Sendo atendidas',
          ),
          const SizedBox(width: 12),
          _buildCounterStream(
            collection: 'animals',
            label: 'Acolhidos',
            color: Colors.green,
            isTotalCount: true,
            description: 'Total na ONG',
          ),
        ],
      ),
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
            count = snapshot.data!.docs.length.toString().padLeft(2, '0'); // Mantido o comportamento original
          }

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Text(
                    count,
                    key: ValueKey<String>(count),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GestureDetector(
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
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 32, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    "EXPLORAR MAPA",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
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
      childAspectRatio: 1.3,
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
          'Campanhas',
          Icons.confirmation_number_outlined, // Ícone atualizado para Campanhas
          Colors.deepOrange,
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CampanhasView())),
        ),
        _buildMenuItem(
          context,
          'Ajustes',
          Icons.settings_outlined,
          Colors.blueGrey,
          () => _showComingSoon(context),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.05)),
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
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade em desenvolvimento.')),
    );
  }
}