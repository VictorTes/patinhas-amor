import 'package:flutter/material.dart';

import 'package:patinhas_amor/models/occurrence.dart';
import 'package:patinhas_amor/services/occurrence_service.dart';
import 'package:patinhas_amor/widgets/error_message.dart';
import 'package:patinhas_amor/widgets/loading_indicator.dart';
import 'package:patinhas_amor/widgets/occurrence_card.dart';
import 'package:patinhas_amor/screens/occurrence_details_screen.dart';

/// Screen displaying a list of occurrences reported by the public.
///
/// Each occurrence represents a report of animal abandonment or abuse.
/// NGO team members can tap on an occurrence to view details and update its status.
class OccurrencesListScreen extends StatefulWidget {
  /// Creates an OccurrencesListScreen widget.
  const OccurrencesListScreen({super.key});

  @override
  State<OccurrencesListScreen> createState() => _OccurrencesListScreenState();
}

class _OccurrencesListScreenState extends State<OccurrencesListScreen> {
  /// Service for fetching occurrence data
  final OccurrenceService _occurrenceService = OccurrenceService();

  /// List of all occurrences fetched from the API
  List<Occurrence> _allOccurrences = [];

  /// List of occurrences filtered by the selected status
  List<Occurrence> _filteredOccurrences = [];

  /// Current loading state
  bool _isLoading = true;

  /// Error message if fetching fails
  String? _errorMessage;

  /// Currently selected status filter ('all' or specific enum value)
  dynamic _selectedFilter = 'all';

  /// Available filter options
  final List<Map<String, dynamic>> _filterOptions = [
    {'value': 'all', 'label': 'Todas'},
    {'value': OccurrenceStatus.pending, 'label': 'Pendentes'},
    {'value': OccurrenceStatus.inProgress, 'label': 'Em Andamento'},
    {'value': OccurrenceStatus.resolved, 'label': 'Resolvidas'},
  ];

  @override
  void initState() {
    super.initState();
    _loadOccurrences();
  }

  /// Fetches occurrences from the API.
  Future<void> _loadOccurrences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final occurrences = await _occurrenceService.fetchOccurrences();
      setState(() {
        _allOccurrences = occurrences;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Não foi possível carregar as ocorrências.';
        _isLoading = false;
      });
    }
  }

  /// Applies the current filter to the occurrence list.
  void _applyFilter() {
    if (_selectedFilter == 'all') {
      _filteredOccurrences = List.from(_allOccurrences);
    } else {
      _filteredOccurrences = _allOccurrences
          .where((occurrence) => occurrence.status == _selectedFilter)
          .toList();
    }
  }

  /// Changes the current filter and updates the displayed list.
  void _onFilterChanged(dynamic filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  @override
  void dispose() {
    _occurrenceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ocorrências'),
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          // Occurrence list
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  /// Builds the filter chips section.
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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

  /// Builds the main body content based on the current state.
  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Carregando ocorrências...');
    }

    if (_errorMessage != null) {
      return ErrorMessage(
        message: _errorMessage!,
        onRetry: _loadOccurrences,
      );
    }

    if (_filteredOccurrences.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadOccurrences,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _filteredOccurrences.length,
        itemBuilder: (context, index) {
          final occurrence = _filteredOccurrences[index];
          return OccurrenceCard(
            occurrence: occurrence,
            onTap: () => _navigateToDetails(occurrence),
          );
        },
      ),
    );
  }

  /// Builds the empty state widget when no occurrences are found.
  Widget _buildEmptyState() {
    String message;
    if (_selectedFilter == 'all') {
      message = 'Nenhuma ocorrência registrada.';
    } else {
      message = 'Nenhuma ocorrência encontrada com este status.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_problem_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedFilter != 'all') ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _onFilterChanged('all'),
              child: const Text('Ver todas'),
            ),
          ],
        ],
      ),
    );
  }

  /// Navigates to the occurrence details screen.
  Future<void> _navigateToDetails(Occurrence occurrence) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OccurrenceDetailsScreen(occurrence: occurrence),
      ),
    );

    // Refresh the list if the occurrence was updated
    if (result == true) {
      _loadOccurrences();
    }
  }
}
