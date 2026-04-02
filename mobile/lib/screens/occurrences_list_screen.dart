import 'package:flutter/material.dart';
import 'package:patinhas_amor/models/occurrence.dart';
import 'package:patinhas_amor/services/occurrence_service.dart';
import 'package:patinhas_amor/widgets/error_message.dart';
import 'package:patinhas_amor/widgets/loading_indicator.dart';
import 'package:patinhas_amor/widgets/occurrence_card.dart';
import 'package:patinhas_amor/screens/occurrence_details_screen.dart';
import 'package:patinhas_amor/screens/register_occurrence_screen.dart';

class OccurrencesListScreen extends StatefulWidget {
  const OccurrencesListScreen({super.key});

  @override
  State<OccurrencesListScreen> createState() => _OccurrencesListScreenState();
}

class _OccurrencesListScreenState extends State<OccurrencesListScreen> {
  final OccurrenceService _occurrenceService = OccurrenceService();
  dynamic _selectedFilter = 'all';

  final List<Map<String, dynamic>> _filterOptions = [
    {'value': 'all', 'label': 'Todas'},
    {'value': OccurrenceStatus.pending, 'label': 'Pendentes'},
    {'value': OccurrenceStatus.inProgress, 'label': 'Em Andamento'},
    {'value': OccurrenceStatus.resolved, 'label': 'Resolvidas'},
  ];

  void _onFilterChanged(dynamic filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => const RegisterOccurrenceScreen(),
        transitionsBuilder: (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _navigateToDetails(Occurrence occurrence) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => OccurrenceDetailsScreen(occurrence: occurrence),
        transitionsBuilder: (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ocorrências', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToRegister,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: const Text(
          'Nova Ocorrência',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<List<Occurrence>>(
              stream: _occurrenceService.getOccurrencesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorMessage(
                    message: 'Erro ao carregar dados.',
                    onRetry: () => setState(() {}),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Sincronizando...');
                }

                final allOccurrences = snapshot.data ?? [];
                final filteredList = _selectedFilter == 'all'
                    ? allOccurrences
                    : allOccurrences.where((o) => o.status == _selectedFilter).toList();

                if (filteredList.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final occurrence = filteredList[index];
                      
                      return AnimatedOpacity(
                        duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 500)),
                        opacity: 1.0,
                        curve: Curves.easeIn,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OccurrenceCard(
                            occurrence: occurrence,
                            onTap: () => _navigateToDetails(occurrence),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option['value'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(option['label'] as String),
              selected: isSelected,
              onSelected: (_) => _onFilterChanged(option['value']),
              selectedColor: Colors.orange,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              elevation: isSelected ? 4 : 0,
              pressElevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'Nenhuma ocorrência encontrada.'
                : 'Sem ocorrências para este status.',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}