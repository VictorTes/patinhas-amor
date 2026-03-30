import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/pending_occurrence.dart';
import '../../services/moderation_service.dart';
import '../../widgets/role_guard.dart'; // Import para proteção

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

  // Função corrigida para abrir o GPS do celular nas coordenadas exatas
  Future<void> _openMap() async {
    final lat = widget.occurrence.latitude;
    final lng = widget.occurrence.longitude;
    
    // Tenta abrir no Google Maps (Android/iOS) ou Apple Maps (iOS)
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng");
    final Uri genericMapUrl = Uri.parse("geo:$lat,$lng?q=$lat,$lng");

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else if (await canLaunchUrl(genericMapUrl)) {
        await launchUrl(genericMapUrl);
      } else {
        throw 'Não foi possível abrir o mapa.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _handleAction(bool isApprove) async {
    // Confirmação para evitar cliques acidentais
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? "Aprovar Ocorrência?" : "Recusar Ocorrência?"),
        content: Text(isApprove 
          ? "A ocorrência ficará visível para todos os usuários." 
          : "Esta ocorrência será excluída permanentemente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(isApprove ? "Aprovar" : "Recusar", style: TextStyle(color: isApprove ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isApprove ? "Aprovada com sucesso!" : "Recusada com sucesso!")),
        );
      }
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
    return RoleGuard(
      // Proteção extra caso alguém tente forçar a rota
      fallback: const Scaffold(body: Center(child: Text("Acesso Negado"))),
      child: Scaffold(
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

                  // Dados do Relator
                  Card(
                    elevation: 0,
                    color: Colors.orange[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.orange.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Tipo: ${widget.occurrence.type}", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text("Reportado por: ${widget.occurrence.reporterName}"),
                          const SizedBox(height: 4),
                          Text("Telefone: ${widget.occurrence.reporterPhone}"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campos para o Admin Corrigir Textos
                  TextField(
                    controller: _descController, 
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Descrição (Você pode ajustar o texto)",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _locController, 
                    decoration: const InputDecoration(
                      labelText: "Referência de Localização",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botão de Mapa
                  ElevatedButton.icon(
                    onPressed: _openMap,
                    icon: const Icon(Icons.location_on),
                    label: const Text("Abrir no GPS (Ver local exato)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botões de Ação
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
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
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      ),
    );
  }
}