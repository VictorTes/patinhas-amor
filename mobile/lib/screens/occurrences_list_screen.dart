import 'package:flutter/material.dart';
import 'package:patinhas_amor/models/occurrence.dart';
import 'package:patinhas_amor/services/occurrence_service.dart';
import 'package:patinhas_amor/widgets/error_message.dart';
import 'package:patinhas_amor/widgets/loading_indicator.dart';
import 'package:patinhas_amor/widgets/occurrence_card.dart';
import 'package:patinhas_amor/screens/occurrence_details_screen.dart';

/// Tela que exibe a listagem de ocorrências em tempo real vindas do Firestore.
class OccurrencesListScreen extends StatefulWidget {
  const OccurrencesListScreen({super.key});

  @override
  State<OccurrencesListScreen> createState() => _OccurrencesListScreenState();
}

class _OccurrencesListScreenState extends State<OccurrencesListScreen> {
  final OccurrenceService _occurrenceService = OccurrenceService();

  /// Filtro selecionado atualmente ('all' ou OccurrenceStatus)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ocorrências'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chips de Filtro
          _buildFilterChips(),
          
          // Lista em Tempo Real com StreamBuilder
          Expanded(
            child: StreamBuilder<List<Occurrence>>(
              stream: _occurrenceService.getOccurrencesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorMessage(
                    message: 'Erro ao carcingar dados do Firebase.',
                    onRetry: () => setState(() {}),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Sincronizando...');
                }

                final allOccurrences = snapshot.data ?? [];
                
                // Aplica o filtro na lista que veio do Stream
                final filteredList = _selectedFilter == 'all'
                    ? allOccurrences
                    : allOccurrences
                        .where((o) => o.status == _selectedFilter)
                        .toList();

                if (filteredList.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
    // Nota: Não precisamos mais checar o 'result == true' e dar refresh,
    // pois o StreamBuilder atualiza a lista automaticamente quando o 
    // status muda no banco!
  }
}