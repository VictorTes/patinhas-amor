import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pending_occurrence.dart';

class ModerationCard extends StatelessWidget {
  final PendingOccurrence occurrence;
  final VoidCallback onTap;

  const ModerationCard({
    super.key,
    required this.occurrence,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(occurrence.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            occurrence.imageUrl,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 70,
              height: 70,
              color: Colors.grey[200],
              child: const Icon(Icons.pets, color: Colors.grey),
            ),
          ),
        ),
        title: Text(
          occurrence.type,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(
              occurrence.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.orange),
        onTap: onTap,
      ),
    );
  }
}