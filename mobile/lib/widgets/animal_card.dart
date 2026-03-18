import 'package:flutter/material.dart';

import 'package:patinhas_amor/models/animal.dart';

/// Card widget displaying information about a rescued animal.
///
/// Used in the animals list to show the animal's photo, name,
/// species, and current status.
class AnimalCard extends StatelessWidget {
  /// The animal data to display
  final Animal animal;

  /// Callback function when the card is tapped
  final VoidCallback? onTap;

  /// Creates an AnimalCard widget.
  const AnimalCard({
    super.key,
    required this.animal,
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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animal image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: animal.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          animal.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.pets,
                              size: 40,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.pets,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(width: 16),

              // Animal info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      animal.species,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(animal.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        animal.status.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(animal.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the color associated with the animal status.
  Color _getStatusColor(AnimalStatus status) {
  switch (status) {
    case AnimalStatus.underTreatment:
      return Colors.orange;
    case AnimalStatus.availableForAdoption:
      return Colors.green;
    case AnimalStatus.adopted:
      return Colors.blue;
    case AnimalStatus.missing: // Adicione este caso
      return Colors.red; 
  }
}
}