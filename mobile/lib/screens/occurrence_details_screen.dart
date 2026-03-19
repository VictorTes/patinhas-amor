import 'package:flutter/material.dart';
import 'package:patinhas_amor/models/occurrence.dart';
import 'package:patinhas_amor/services/occurrence_service.dart';
import 'package:patinhas_amor/widgets/loading_indicator.dart';

/// Tela que exibe informações detalhadas de uma ocorrência específica.
class OccurrenceDetailsScreen extends StatefulWidget {
  final Occurrence occurrence;

  const OccurrenceDetailsScreen({
    super.key,
    required this.occurrence,
  });

  @override
  State<OccurrenceDetailsScreen> createState() =>
      _OccurrenceDetailsScreenState();
}

class _OccurrenceDetailsScreenState extends State<OccurrenceDetailsScreen> {
  final OccurrenceService _occurrenceService = OccurrenceService();

  bool _isLoading = false;
  late Occurrence _occurrence;

  @override
  void initState() {
    super.initState();
    _occurrence = widget.occurrence;
  }

  /// Atualiza o status da ocorrência no Firestore.
  Future<void> _updateStatus(OccurrenceStatus newStatus) async {
    // Se o ID for nulo ou o status for o mesmo, não faz nada
    if (_occurrence.id == null || _occurrence.status == newStatus) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Chama o service atualizado para o Firestore (passando String id)
      await _occurrenceService.updateOccurrenceStatus(
        _occurrence.id!,
        newStatus.value,
      );

      if (mounted) {
        setState(() {
          _occurrence = _occurrence.copyWith(status: newStatus);
          _isLoading = false;
        });
        _showSuccessSnackBar('Status atualizado para: ${newStatus.label}');
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Ocorrência'),
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Atualizando status...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge de Status Dinâmico
                  _buildStatusBadge(),
                  const SizedBox(height: 24),
                  
                  // Seção de Dados
                  _buildDetailSection(
                    icon: Icons.report_problem,
                    title: 'Tipo de Ocorrência',
                    content: _occurrence.type,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailSection(
                    icon: Icons.location_on,
                    title: 'Localização Relatada',
                    content: _occurrence.location,
                  ),
                  const SizedBox(height: 16),
                  if (_occurrence.createdAt != null)
                    _buildDetailSection(
                      icon: Icons.calendar_today,
                      title: 'Data do Registro',
                      content: _formatDate(_occurrence.createdAt!),
                    ),
                  
                  const SizedBox(height: 32),
                  const Text(
                    'Descrição do Relato',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _occurrence.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  const Text(
                    'Gerenciar Progresso',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor(_occurrence.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 8),
          Text(
            _occurrence.status.label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.orange, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButtons() {
    return Column(
      children: OccurrenceStatus.values.map((status) {
        final isSelected = _occurrence.status == status;
        final color = _getStatusColor(status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: isSelected || _isLoading ? null : () => _updateStatus(status),
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected ? color : Colors.transparent,
                foregroundColor: isSelected ? Colors.white : color,
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check_circle, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    status.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}