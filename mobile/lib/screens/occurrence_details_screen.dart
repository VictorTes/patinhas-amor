import 'package:flutter/material.dart';
import 'package:patinhas_amor/models/occurrence.dart';
import 'package:patinhas_amor/services/occurrence_service.dart';
import 'package:patinhas_amor/widgets/loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// Tenta abrir o local da ocorrência no aplicativo de mapas do dispositivo.
  Future<void> _openInMaps() async {
    if (_occurrence.latitude == null || _occurrence.longitude == null) {
      _showErrorSnackBar('Coordenadas geográficas não disponíveis.');
      return;
    }

    final Uri uri = Uri.parse(
      'geo:${_occurrence.latitude},${_occurrence.longitude}?q=${_occurrence.latitude},${_occurrence.longitude}',
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${_occurrence.latitude},${_occurrence.longitude}',
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Não foi possível abrir um aplicativo de mapas.');
      }
    }
  }

  Future<void> _updateStatus(OccurrenceStatus newStatus) async {
    if (_occurrence.id == null || _occurrence.status == newStatus) return;

    setState(() {
      _isLoading = true;
    });

    try {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Ocorrência'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Atualizando status...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SEÇÃO DE IMAGEM ---
                  if (_occurrence.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _occurrence.imageUrl!,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 250,
                            color: Colors.grey[200],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  _buildStatusBadge(),
                  const SizedBox(height: 24),

                  _buildDetailSection(
                    icon: Icons.report_problem,
                    title: 'Tipo de Ocorrência',
                    content: _occurrence.type,
                  ),
                  const SizedBox(height: 16),

                  // --- SEÇÃO DE LOCALIZAÇÃO COM BOTÃO MINI MAPA ABAIXO ---
                  _buildDetailSection(
                    icon: Icons.location_on,
                    title: 'Localização Relatada',
                    content: _occurrence.location,
                  ),
                  if (_occurrence.latitude != null) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 40), // Alinha com o texto da seção
                      child: InkWell(
                        onTap: _openInMaps,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_outlined, color: Colors.orange, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'ABRIR NO MAPA',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

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
                  _buildStatusDropdown(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // --- MÉTODOS AUXILIARES DE UI ---

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
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<OccurrenceStatus>(
      value: _occurrence.status,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: OccurrenceStatus.values.map((status) {
        return DropdownMenuItem<OccurrenceStatus>(
          value: status,
          child: Row(
            children: [
              CircleAvatar(radius: 6, backgroundColor: _getStatusColor(status)),
              const SizedBox(width: 12),
              Text(status.label, style: const TextStyle(fontSize: 16)),
            ],
          ),
        );
      }).toList(),
      onChanged: _isLoading ? null : (newStatus) {
        if (newStatus != null) _updateStatus(newStatus);
      },
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}