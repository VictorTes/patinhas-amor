import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/pending_occurrence.dart';
import '../../services/moderation_service.dart';
import '../../widgets/role_guard.dart';

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

  Future<void> _openMap() async {
    final lat = widget.occurrence.latitude;
    final lng = widget.occurrence.longitude;
    
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? "Aprovar Ocorrência?" : "Recusar Ocorrência?"),
        content: Text(isApprove 
          ? "A ocorrência será movida para a lista pública e ficará visível para todos." 
          : "Esta ocorrência será marcada como rejeitada na triagem."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(
              isApprove ? "Aprovar" : "Recusar", 
              style: TextStyle(color: isApprove ? Colors.green : Colors.red, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      if (isApprove) {
        await _service.approveOccurrence(
          widget.occurrence.id, 
          {
            'description': _descController.text,
            'location': _locController.text,
            'type': widget.occurrence.type,
            'protocol': widget.occurrence.id,
            'source': widget.occurrence.source,
            'status_web': 'approved',
            'isValidated': true,
            'submittedAt': widget.occurrence.submittedAt,
            'userAgent': widget.occurrence.userAgent,
            'accessCode': widget.occurrence.accessCode, // ADICIONADO: Salvando o código de acesso
          },
          widget.occurrence 
        );
      } else {
        await _service.rejectOccurrence(widget.occurrence.id);
      }

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApprove ? "Aprovada e publicada com sucesso!" : "Ocorrência recusada."),
            backgroundColor: isApprove ? Colors.green : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      fallback: const Scaffold(body: Center(child: Text("Acesso Negado"))),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Moderação de Relato"),
          backgroundColor: Colors.orange[800],
          elevation: 0,
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.occurrence.imageUrl,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            Container(
                              height: 250,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported, size: 50),
                            ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            "${widget.occurrence.source.toUpperCase()} / ${widget.occurrence.statusWeb.toUpperCase()}", 
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(widget.occurrence.type, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                              const Icon(Icons.info_outline, color: Colors.orange),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text("Protocolo: ${widget.occurrence.id}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text("Reportado por: ${widget.occurrence.reporterName}", style: const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text("Telefone: ${widget.occurrence.reporterPhone}"),
                          if (widget.occurrence.submittedAt.isNotEmpty) ...[
                             const SizedBox(height: 4),
                             Text("Data Web: ${widget.occurrence.submittedAt}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ]
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text("REVISÃO DE DADOS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _descController, 
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Descrição (Ajuste se necessário)",
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

                  ElevatedButton.icon(
                    onPressed: _openMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text("VER LOCALIZAÇÃO NO GPS"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _handleAction(false),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text("RECUSAR"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _handleAction(true),
                          icon: const Icon(Icons.publish),
                          label: const Text("APROVAR"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
      ),
    );
  }
}