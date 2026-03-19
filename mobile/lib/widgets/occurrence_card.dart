import 'package:flutter/material.dart';
import 'package:patinhas_amor/models/occurrence.dart';

/// Card que exibe informações resumidas de uma ocorrência, incluindo miniatura da imagem.
class OccurrenceCard extends StatelessWidget {
  final Occurrence occurrence;
  final VoidCallback? onTap;

  const OccurrenceCard({
    super.key,
    required this.occurrence,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: onTap,
        // --- MINIATURA À ESQUERDA ---
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildThumbnail(),
        ),
        // --- TÍTULO (TIPO DE OCORRÊNCIA) ---
        title: Text(
          occurrence.type,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        // --- SUBTÍTULO (LOCALIZAÇÃO E STATUS) ---
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              occurrence.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildStatusBadge(),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  /// Constrói a miniatura da imagem com tratamento de carregamento e erro.
  Widget _buildThumbnail() {
    if (occurrence.imageUrl != null && occurrence.imageUrl!.isNotEmpty) {
      return Image.network(
        occurrence.imageUrl!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        // Mostra um ícone de erro se a URL falhar
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        // Mostra um indicador de progresso enquanto a imagem baixa
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            color: Colors.grey[100],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }
    return _buildPlaceholder();
  }

  /// Ícone padrão caso a ocorrência não tenha imagem ou ocorra erro.
  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.orange.withOpacity(0.1),
      child: const Icon(Icons.pets, color: Colors.orange, size: 28),
    );
  }

  /// Badge colorido para indicar o status de forma visual.
  Widget _buildStatusBadge() {
    final color = _getStatusColor(occurrence.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        occurrence.status.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Retorna a cor associada ao status da ocorrência.
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
}