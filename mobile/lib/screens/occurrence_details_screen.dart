import 'package:flutter/material.dart';

import 'package:patinhas_amor/models/occurrence.dart';
import 'package:patinhas_amor/services/occurrence_service.dart';
import 'package:patinhas_amor/widgets/loading_indicator.dart';

/// Screen displaying detailed information about a specific occurrence.
///
/// Shows the full description, location, contact information, and status.
/// Provides actions to update the occurrence status.
class OccurrenceDetailsScreen extends StatefulWidget {
  /// The occurrence to display
  final Occurrence occurrence;

  /// Creates an OccurrenceDetailsScreen widget.
  const OccurrenceDetailsScreen({
    super.key,
    required this.occurrence,
  });

  @override
  State<OccurrenceDetailsScreen> createState() =>
    _OccurrenceDetailsScreenState();
}

class _OccurrenceDetailsScreenState extends State<OccurrenceDetailsScreen> {
  /// Service for updating occurrence data
  final OccurrenceService _occurrenceService = OccurrenceService();

  /// Current loading state
  bool _isLoading = false;

  /// Current occurrence data (may be updated)
  late Occurrence _occurrence;

  @override
  void initState() {
    super.initState();
    _occurrence = widget.occurrence;
  }

  /// Updates the occurrence status.
  Future<void> _updateStatus(OccurrenceStatus newStatus) async {
    if (_occurrence.status == newStatus) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _occurrenceService.updateOccurrenceStatus(
        _occurrence.id,
        newStatus.value,
      );

      setState(() {
        _occurrence = _occurrence.copyWith(status: newStatus);
        _isLoading = false;
      });

      if (mounted) {
        _showSuccessSnackBar('Status atualizado com sucesso!');
        // Return true to indicate the occurrence was updated
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao atualizar status: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Shows a success snackbar.
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows an error snackbar.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Returns the color associated with the occurrence status.
  Color _getStatusColor(OccurrenceStatus status) {
    switch (status) {
      case OccurrenceStatus.pending:
        return Colors.orange;
      case OccurrenceStatus.inProgress:
        return Colors.blue;
      case OccurrenceStatus.resolved:
        return Colors.green;
    }
  }

  /// Returns a user-friendly status text.
  String _getStatusText(OccurrenceStatus status) {
    return status.label;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Ocorrência'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Atualizando...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_occurrence.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(_occurrence.status),
                      style: TextStyle(
                        color: _getStatusColor(_occurrence.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Type
                  _buildDetailSection(
                    icon: Icons.report_problem,
                    title: 'Tipo',
                    content: _occurrence.type,
                  ),
                  const SizedBox(height: 16),
                  // Location
                  _buildDetailSection(
                    icon: Icons.location_on,
                    title: 'Localização',
                    content: _occurrence.location,
                  ),
                  const SizedBox(height: 16),
                  // Date
                  if (_occurrence.createdAt != null)
                    _buildDetailSection(
                      icon: Icons.calendar_today,
                      title: 'Data do Reporte',
                      content: _formatDate(_occurrence.createdAt!),
                    ),
                  const SizedBox(height: 24),
                  // Description
                  const Text(
                    'Descrição',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _occurrence.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Status update section
                  const Text(
                    'Atualizar Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusButtons(),
                ],
              ),
            ),
    );
  }

  /// Builds a detail section with icon, title, and content.
  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.orange,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the status update buttons.
  Widget _buildStatusButtons() {
    final statuses = [
      {
        'value': OccurrenceStatus.pending,
        'label': 'Pendente',
        'color': Colors.orange,
      },
      {
        'value': OccurrenceStatus.inProgress,
        'label': 'Em Andamento',
        'color': Colors.blue,
      },
      {
        'value': OccurrenceStatus.resolved,
        'label': 'Resolvida',
        'color': Colors.green,
      },
    ];

    return Column(
      children: statuses.map((status) {
        final statusValue = status['value'] as OccurrenceStatus;
        final isSelected = _occurrence.status == statusValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSelected
                  ? null
                  : () => _updateStatus(statusValue),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? (status['color'] as Color).withOpacity(0.1)
                    : Colors.white,
                foregroundColor: status['color'] as Color,
                side: BorderSide(
                  color: isSelected
                      ? (status['color'] as Color)
                      : Colors.grey[300]!,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(status['label'] as String),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Formats a date for display.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
