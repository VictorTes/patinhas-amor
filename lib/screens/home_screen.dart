import 'package:flutter/material.dart';

import 'package:patinhas_amor/screens/animals_list_screen.dart';
import 'package:patinhas_amor/screens/occurrences_list_screen.dart';

/// Home screen for the Patinhas e Amor application.
///
/// This is the main entry point of the app, displaying the NGO logo
/// and navigation options to access occurrences and rescued animals.
class HomeScreen extends StatelessWidget {
  /// Creates a HomeScreen widget.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 0),
              // NGO Logo area with enhanced design
              _buildLogoSection(),
              const SizedBox(height: 40),
              // Welcome text section
              _buildWelcomeSection(),
              const SizedBox(height: 48),
              // Navigation cards
              _buildNavigationSection(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the logo section with icon and NGO name.
  Widget _buildLogoSection() {
    return Column(
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        // NGO Name
        const Text(
          'Patinhas e Amor',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        // Tagline
        Text(
          'Cuidando com amor',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Builds the welcome text section.
  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Bem-vindo!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sistema de Gerenciamento',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the navigation section with cards.
  Widget _buildNavigationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'Menu Principal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        // Occurrences Card
        _NavigationCard(
          icon: Icons.report_problem_outlined,
          title: 'Ocorrências',
          subtitle: 'Gerenciar denúncias de abandono e maus-tratos',
          color: Colors.orange,
          accentColor: Colors.orange[50]!,
          onTap: () => _navigateToOccurrences(context),
        ),
        const SizedBox(height: 16),
        // Animals Card
        _NavigationCard(
          icon: Icons.pets_outlined,
          title: 'Animais Resgatados',
          subtitle: 'Visualizar e cadastrar animais resgatados',
          color: Colors.green,
          accentColor: Colors.green[50]!,
          onTap: () => _navigateToAnimals(context),
        ),
      ],
    );
  }

  /// Navigates to the occurrences list screen.
  void _navigateToOccurrences(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OccurrencesListScreen(),
      ),
    );
  }

  /// Navigates to the animals list screen.
  void _navigateToAnimals(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnimalsListScreen(),
      ),
    );
  }
}

/// Reusable navigation card widget for the home screen.
class _NavigationCard extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Card title
  final String title;

  /// Card subtitle/description
  final String subtitle;

  /// Primary color for the card
  final Color color;

  /// Accent background color for the icon
  final Color accentColor;

  /// Callback when card is tapped
  final VoidCallback onTap;

  /// Creates a navigation card.
  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                accentColor.withOpacity(0.3),
              ],
            ),
          ),
          child: Row(
            children: [
              // Icon container with accent background
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
