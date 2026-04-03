import 'package:flutter/material.dart';
import 'package:patinhas_amor/models/occurrence.dart';
import 'package:patinhas_amor/services/occurrence_service.dart';
import 'package:patinhas_amor/widgets/error_message.dart';
import 'package:patinhas_amor/widgets/loading_indicator.dart';
import 'package:patinhas_amor/widgets/occurrence_card.dart';
import 'package:patinhas_amor/screens/occurrence_details_screen.dart';
// ADICIONE ESTA IMPORTAÇÃO:
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

  // MÉTODO PARA NAVEGAR PARA O CADASTRO
  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterOccurrenceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ocorrências'),
        elevation: 0,
      ),
      // --- ADICIONADO O BOTÃO FLUTUANTE ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToRegister,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: const Text('Nova Ocorrência', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    message: 'Erro ao carregar dados do Firebase.',
                    onRetry: () => setState(() {}),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Sincronizando...');
                }

                final allOccurrences = snapshot.data ?? [];
                
                final filteredList = _selectedFilter == 'all'
                    ? allOccurrences
                    : allOccurrences
                        .where((o) => o.status == _selectedFilter)
                        .toList();

                if (filteredList.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80), // Padding extra no fundo para o FAB não cobrir o último item
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final occurrence = filteredList[index];
                    return OccurrenceCard(
                      occurrence: occurrence,
                      onTap: () => _navigateToDetails(occurrence),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ... (Restante dos seus métodos _buildFilterChips, _buildEmptyState e _navigateToDetails permanecem iguais)
  
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((option) {
            final isSelected = _selectedFilter == option['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(option['label'] as String),
                selected: isSelected,
                onSelected: (_) => _onFilterChanged(option['value']),
                selectedColor: Colors.orange.withOpacity(0.2),
                checkmarkColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.orange : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, 
                  size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all'
                  ? 'Nenhuma ocorrência encontrada.'
                  : 'Sem ocorrências para este status.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(Occurrence occurrence) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OccurrenceDetailsScreen(occurrence: occurrence),
      ),
    );
  }
}