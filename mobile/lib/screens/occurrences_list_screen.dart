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

  // Filtro selecionado. Por padrão 'all'.
  dynamic _selectedFilter = 'all';

  // Opções de filtro mapeadas para o Enum que você já possui
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
      MaterialPageRoute(
        builder: (context) => const RegisterOccurrenceScreen(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Fundo levemente cinza para destacar os cards brancos
      appBar: AppBar(
        title: const Text(
          'Ocorrências',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToRegister,
        backgroundColor: Colors.orange[800],
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: const Text(
          'Nova Ocorrência',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Barra de Filtros (Chips)
          _buildFilterChips(),
          
          Expanded(
            child: StreamBuilder<List<Occurrence>>(
              // O service já filtra o que é vindo da Web (approved) e do App
              stream: _occurrenceService.getOccurrencesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorMessage(
                    message: 'Erro ao carregar dados do servidor.',
                    onRetry: () => setState(() {}),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Sincronizando...');
                }

                final allOccurrences = snapshot.data ?? [];
                
                // Filtro em tempo de execução no App 
                // Considera apenas itens cuja validação seja true, ou cujo campo seja nulo (criados pelo app móvel)
                final validOccurrences = allOccurrences.where((o) {
                  final isValidated = (o as dynamic).toJson()['isValidated'];
                  return isValidated == true || isValidated == null;
                }).toList();

                final filteredList = _selectedFilter == 'all'
                    ? validOccurrences
                    : validOccurrences.where((o) {
                        if (_selectedFilter is OccurrenceStatus) {
                          return o.status == _selectedFilter;
                        }
                        return false;
                      }).toList();

                // Ordena os itens pela data de criação (do mais recente para o mais antigo)
                filteredList.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

                if (filteredList.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  color: Colors.orange[800],
                  child: ListView.builder(
                    // O physics garante que o scroll funcione mesmo com poucos itens para o RefreshIndicator
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), 
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final occurrence = filteredList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OccurrenceCard(
                          occurrence: occurrence,
                          onTap: () => _navigateToDetails(occurrence),
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
                checkmarkColor: Colors.orange[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.orange[800] : Colors.black87,
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
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: constraints.maxHeight,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_turned_in_outlined, 
                size: 80, 
                color: Colors.grey[300]
              ),
              const SizedBox(height: 16),
              Text(
                _selectedFilter == 'all'
                    ? 'Nenhuma ocorrência encontrada.'
                    : 'Sem ocorrências para este status.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Arraste para baixo para atualizar.',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}