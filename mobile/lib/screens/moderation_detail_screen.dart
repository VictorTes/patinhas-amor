import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/pending_occurrence.dart';
import '../../services/moderation_service.dart';

class ModerationDetailScreen extends StatefulWidget {
  final PendingOccurrence occurrence;
  const ModerationDetailScreen({super.key, required this.occurrence});

  @override
  State<ModerationDetailScreen> createState() => _ModerationDetailScreenState();
}

class _ModerationDetailScreenState extends State<ModerationDetailScreen> {
  late TextEditingController _descController;
  late TextEditingController _locController;
  final ModerationService _service = ModerationService();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.occurrence.description);
    _locController = TextEditingController(text: widget.occurrence.location);
  }

  @override
  void dispose() {
    _descController.dispose();
    _locController.dispose();
    super.dispose();
  }

  // Função para abrir o aplicativo de mapas do celular
  Future<void> _openMap() async {
    final lat = widget.occurrence.latitude;
    final lng = widget.occurrence.longitude;
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o mapa.')),
        );
      }
    }
  }

  Future<void> _handleAction(bool isApprove) async {
    setState(() => _isLoading = true);
    try {
      if (isApprove) {
        await _service.approveOccurrence(widget.occurrence.id, {
          'description': _descController.text,
          'location': _locController.text,
        });
      } else {
        await _service.rejectOccurrence(widget.occurrence.id);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes da Ocorrência"),
        backgroundColor: Colors.orange[800],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagem da Ocorrência
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.occurrence.imageUrl,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50),
                      ),
                  ),
                ),
                const SizedBox(height: 20),

                // Card de Informações do Relator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tipo: ${widget.occurrence.type}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text("Reportado por: ${widget.occurrence.reporterName}"),
                      Text("Telefone: ${widget.occurrence.reporterPhone}"),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Campos Editáveis
                TextField(
                  controller: _descController, 
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Descrição (Editável)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _locController, 
                  decoration: const InputDecoration(
                    labelText: "Localização de Referência (Editável)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Botão de Mapa
                OutlinedButton.icon(
                  onPressed: _openMap,
                  icon: const Icon(Icons.map),
                  label: const Text("Ver Coordenadas no Mapa"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 30),

                // Botões de Ação
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _handleAction(false),
                        icon: const Icon(Icons.close),
                        label: const Text("Recusar"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _handleAction(true),
                        icon: const Icon(Icons.check),
                        label: const Text("Aprovar"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
    );
  }
}