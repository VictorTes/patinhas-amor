import 'package:flutter/material.dart';
import 'package:patinhas_amor/models/occurrence.dart';
import 'package:patinhas_amor/services/occurrence_service.dart';
import 'package:patinhas_amor/widgets/loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

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
  final TextEditingController _resolutionController = TextEditingController();

  bool _isLoading = false;
  late Occurrence _occurrence;

  @override
  void initState() {
    super.initState();
    _occurrence = widget.occurrence;
  }

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE PDF ---
  Future<void> _generateAndPreviewReport() async {
    setState(() => _isLoading = true);
    final pdf = pw.Document();
    pw.MemoryImage? profileImage;

    if (_occurrence.imageUrl != null && _occurrence.imageUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(_occurrence.imageUrl!));
        if (response.statusCode == 200) {
          profileImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        debugPrint("Erro imagem PDF: $e");
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PATINHAS AMOR - RELATORIO',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatDate(_occurrence.createdAt ?? DateTime.now())),
                ],
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 15),
              if (profileImage != null)
                pw.Center(
                  child: pw.Container(
                    height: 200,
                    width: 350,
                    margin: const pw.EdgeInsets.only(bottom: 20),
                    child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                  ),
                ),
              pw.Text('INFORMACOES GERAIS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('ID: ${_occurrence.id}'),
              pw.Text('Tipo: ${_occurrence.type}'),
              pw.Text('Localizacao: ${_occurrence.location}'),
              pw.Text('Status: ${_occurrence.status.label}'),
              pw.SizedBox(height: 20),
              pw.Text('DESCRICAO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Paragraph(text: _occurrence.description),
              if (_occurrence.resolutionDescription != null && _occurrence.resolutionDescription!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text('OBSERVACAO E/OU RESOLUCAO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                pw.Paragraph(text: _occurrence.resolutionDescription!),
              ],
            ],
          );
        },
      ),
    );

    setState(() => _isLoading = false);
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // --- MÉTODOS DE AÇÃO ---
  Future<void> _openInMaps() async {
    if (_occurrence.latitude == null || _occurrence.longitude == null) return;
    final Uri uri = Uri.parse('geo:${_occurrence.latitude},${_occurrence.longitude}?q=${_occurrence.latitude},${_occurrence.longitude}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showErrorSnackBar('Não foi possível abrir o mapa.');
    }
  }

  Future<void> _showResolutionDialog({bool isEditing = false}) async {
    if (isEditing) {
      _resolutionController.text = _occurrence.resolutionDescription ?? '';
    } else {
      _resolutionController.clear();
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Observação' : 'Adicionar Observação'),
        content: TextField(
          controller: _resolutionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Descreva os detalhes da visita ou resolução...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final text = _resolutionController.text.trim();
              Navigator.pop(context);
              _updateStatus(
                _occurrence.status,
                resolution: text.isEmpty ? null : text,
              );
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(OccurrenceStatus newStatus, {String? resolution}) async {
    setState(() => _isLoading = true);
    try {
      // CORREÇÃO: Passando newStatus diretamente, sem o .value
      await _occurrenceService.updateOccurrenceStatus(
        _occurrence.id!,
        newStatus,
        resolutionDescription: resolution,
      );
      
      if (mounted) {
        setState(() {
          _occurrence = _occurrence.copyWith(
            status: newStatus,
            resolutionDescription: resolution,
          );
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados atualizados com sucesso!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showErrorSnackBar('Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Ocorrência'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isLoading ? null : _generateAndPreviewReport,
            tooltip: 'Gerar PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Processando...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_occurrence.imageUrl != null && _occurrence.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _occurrence.imageUrl!, 
                        height: 250, 
                        width: double.infinity, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildStatusBadge(),
                  const SizedBox(height: 24),
                  _buildDetailRow(Icons.pets, 'Tipo', _occurrence.type),
                  _buildDetailRow(Icons.location_on, 'Localização', _occurrence.location),
                  if (_occurrence.latitude != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 40, bottom: 16),
                      child: OutlinedButton.icon(
                        onPressed: _openInMaps, 
                        icon: const Icon(Icons.map), 
                        label: const Text('VER NO GOOGLE MAPS'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                      ),
                    ),
                  _buildDetailRow(Icons.event, 'Data do Registro', _formatDate(_occurrence.createdAt ?? DateTime.now())),
                  const Divider(height: 40),
                  const Text('Descrição da Denúncia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTextCard(_occurrence.description),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Observação e/ou Resolução', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)
                      ),
                      if (_occurrence.resolutionDescription != null && _occurrence.resolutionDescription!.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.green),
                          onPressed: () => _showResolutionDialog(isEditing: true),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_occurrence.resolutionDescription != null && _occurrence.resolutionDescription!.isNotEmpty)
                    _buildTextCard(_occurrence.resolutionDescription!, isSuccess: true)
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showResolutionDialog(),
                        icon: const Icon(Icons.add_comment),
                        label: const Text('ADICIONAR OBSERVAÇÃO / RELATO'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                  const Divider(),
                  const Text('Alterar Status da Ocorrência', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildStatusDropdown(),
                ],
              ),
            ),
    );
  }

  // --- AUXILIARES ---
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  value, 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  softWrap: true,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextCard(String text, {bool isSuccess = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSuccess ? Colors.green.withOpacity(0.2) : Colors.grey[300]!),
      ),
      child: Text(text, style: const TextStyle(fontSize: 15)),
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor(_occurrence.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
      child: Text(_occurrence.status.label.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<OccurrenceStatus>(
      value: _occurrence.status,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
        filled: true, 
        fillColor: Colors.white,
      ),
      items: OccurrenceStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
      onChanged: (val) {
        if (val == null || val == _occurrence.status) return;
        _updateStatus(val, resolution: _occurrence.resolutionDescription);
      },
    );
  }

  Color _getStatusColor(OccurrenceStatus s) {
    if (s == OccurrenceStatus.pending) return Colors.orange;
    if (s == OccurrenceStatus.inProgress) return Colors.blue;
    return Colors.green;
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _showErrorSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
}