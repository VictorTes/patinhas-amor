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
      backgroundColor: const Color(0xFFF8F9FA),
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
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildLiveSummarySection(),
                const SizedBox(height: 24),
                _buildActiveCampaignsCard(context),
                const SizedBox(height: 24),
                _buildMapPreview(context),
                const SizedBox(height: 24),
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
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange.withOpacity(0.2), width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage('assets/images/logo.png'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu, color: Colors.white, size: 10),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patinhas e Amor',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436)),
            ),
            Text(
              'Painel Administrativo',
              style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const Spacer(),
        _buildNotificationIcon(),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: IconButton(
        icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF2D3436)),
        onPressed: () => _showComingSoon(context),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionCircle(Icons.pets_rounded, 'Novo Pet', Colors.green, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AnimalsListScreen()))),
        _buildActionCircle(Icons.notification_important_outlined, 'Nova Ocorr.', Colors.orange, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const OccurrencesListScreen()))),
        _buildActionCircle(Icons.analytics_outlined, 'Relatórios', Colors.blue, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ReportsScreen()))),
        _buildActionCircle(Icons.more_horiz, 'Mais', Colors.grey, 
          () => Scaffold.of(context).openDrawer()),
      ],
    );
  }

  Widget _buildActionCircle(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildActiveCampaignsCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaigns')
          .where('status', isEqualTo: 'ativa') // Ajustado para o campo 'status' do seu Firestore
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Erro ao carregar campanhas');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Nenhuma rifa ativa encontrada", 
              style: TextStyle(fontSize: 12, color: Colors.grey)),
            )
          );
        }

        var campaign = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        String title = campaign['title'] ?? 'Rifa Ativa';
        
        // Conversão de valores monetários baseada no seu Firestore
        double collected = double.tryParse(campaign['totalCollected']?.toString() ?? '0') ?? 0.0;
        double goal = double.tryParse(campaign['goalValue']?.toString() ?? '1') ?? 1.0;
        if (goal == 0) goal = 1.0;
        
        double progress = (collected / goal).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 20, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showComingSoon(context),
                    child: Text(
                      'Ver todas',
                      style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[100],
                  color: Colors.orange,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Arrecadado: R\$ ${collected.toStringAsFixed(2)}', 
                    style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)
                  ),
                  Text(
                    'Meta: R\$ ${goal.toStringAsFixed(2)}', 
                    style: const TextStyle(color: Color(0xFF2D3436), fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
          color: const Color(0xFFE74C3C),
          description: 'Denúncias',
        ),
        const SizedBox(width: 12),
        _buildCounterStream(
          collection: 'occurrences',
          field: 'status',
          value: 'in_progress',
          label: 'Em Curso',
          color: const Color(0xFF3498DB),
          description: 'Atendimentos',
        ),
        const SizedBox(width: 12),
        _buildCounterStream(
          collection: 'animals',
          label: 'Acolhidos',
          color: const Color(0xFF27AE60),
          isTotalCount: true,
          description: 'Na ONG',
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
          String count = snapshot.hasData ? snapshot.data!.docs.length.toString().padLeft(2, '0') : '--';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Text(
                  count,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                Text(description, style: TextStyle(fontSize: 8, color: Colors.grey[400])),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapPreview(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OccurrencesMapScreen())),
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)]),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: const Stack(
          children: [
            Positioned(right: -10, top: -10, child: Icon(Icons.map_rounded, size: 80, color: Colors.white10)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore_outlined, size: 26, color: Colors.white),
                  SizedBox(height: 6),
                  Text("EXPLORAR MAPA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridNavigation(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildMenuItem(context, 'Ocorrências', Icons.notification_important_outlined, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const OccurrencesListScreen()))),
        _buildMenuItem(context, 'Animais', Icons.pets_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AnimalsListScreen()))),
        _buildMenuItem(context, 'Relatórios', Icons.bar_chart_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ReportsScreen()))),
        _buildMenuItem(context, 'Campanhas', Icons.confirmation_number_outlined, Colors.redAccent, () => _showComingSoon(context)),
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
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3436))),
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