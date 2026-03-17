import 'package:flutter/material.dart';

import 'package:patinhas_amor/models/occurrence.dart';

/// Card widget displaying summary information about an occurrence.
///
/// Used in the occurrences list to show key details at a glance.
/// Tapping the card navigates to the occurrence details screen.
class OccurrenceCard extends StatelessWidget {
  /// The occurrence data to display
  final Occurrence occurrence;

  /// Callback function when the card is tapped
  final VoidCallback? onTap;

  /// Creates an OccurrenceCard widget.
  const OccurrenceCard({
    super.key,
    required this.occurrence,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Text(
          occurrence.type,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              occurrence.location,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              occurrence.status.label,
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(occurrence.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
}