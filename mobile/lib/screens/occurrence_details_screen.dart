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
  State<OccurrenceDetailsScreen> createState() => _OccurrenceDetailsScreenState();
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
                pw.Text('OBSERVACAO E/OU RESOLUCAO:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
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
    final Uri uri = Uri.parse(
        'geo:${_occurrence.latitude},${_occurrence.longitude}?q=${_occurrence.latitude},${_occurrence.longitude}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showErrorSnackBar('Não foi possível abrir o mapa.');
    }
  }

  Future<void> _showResolutionDialog({bool isEditing = false}) async {
    _resolutionController.text = isEditing ? (_occurrence.resolutionDescription ?? '') : '';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEditing ? 'Editar Observação' : 'Adicionar Observação'),
        content: TextField(
          controller: _resolutionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Descreva os detalhes da visita ou resolução...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Dados atualizados com sucesso!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showErrorSnackBar('Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalhes', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _isLoading ? null : _generateAndPreviewReport,
            tooltip: 'Gerar PDF',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Processando...')
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_occurrence.imageUrl != null && _occurrence.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Hero(
                      tag: 'occ_image_${_occurrence.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          _occurrence.imageUrl!,
                          height: 280,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(),
                      Text(
                        _formatDate(_occurrence.createdAt ?? DateTime.now()),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(Icons.pets_outlined, 'Tipo de Ocorrência', _occurrence.type),
                  _buildDetailRow(Icons.location_on_outlined, 'Localização', _occurrence.location),
                  if (_occurrence.latitude != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 48, bottom: 20),
                      child: TextButton.icon(
                        onPressed: _openInMaps,
                        icon: const Icon(Icons.map_outlined, size: 20),
                        label: const Text('VER NO GOOGLE MAPS'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          backgroundColor: Colors.blue.withOpacity(0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  const Divider(height: 32),
                  const Text('Descrição da Denúncia',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTextCard(_occurrence.description),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Resolução / Observações',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      if (_occurrence.resolutionDescription != null &&
                          _occurrence.resolutionDescription!.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 22, color: Colors.green),
                          onPressed: () => _showResolutionDialog(isEditing: true),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_occurrence.resolutionDescription != null &&
                      _occurrence.resolutionDescription!.isNotEmpty)
                    _buildTextCard(_occurrence.resolutionDescription!, isSuccess: true)
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showResolutionDialog(),
                        icon: const Icon(Icons.add_comment_outlined),
                        label: const Text('ADICIONAR RELATO DE VISITA'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Atualizar Status',
                            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildStatusDropdown(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  // --- AUXILIARES ---
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSuccess ? Colors.green.withOpacity(0.2) : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor(_occurrence.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _occurrence.status.label.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<OccurrenceStatus>(
      value: _occurrence.status,
      icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.orange),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: OccurrenceStatus.values
          .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
          .toList(),
      onChanged: (val) {
        if (val == null || val == _occurrence.status) return;
        _updateStatus(val, resolution: _occurrence.resolutionDescription);
      },
    );
  }

  Color _getStatusColor(OccurrenceStatus s) {
    switch (s) {
      case OccurrenceStatus.pending:
        return Colors.orange[700]!;
      case OccurrenceStatus.inProgress:
        return Colors.blue[700]!;
      case OccurrenceStatus.resolved:
        return Colors.green[700]!;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} às ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _showErrorSnackBar(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
}