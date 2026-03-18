import 'package:flutter/material.dart';
import 'package:patinhas_amor/models/animal.dart';
import 'package:patinhas_amor/services/animal_service.dart';
import 'package:patinhas_amor/widgets/animal_card.dart';
import 'package:patinhas_amor/widgets/error_message.dart';
import 'package:patinhas_amor/widgets/loading_indicator.dart';
import 'package:patinhas_amor/screens/register_animal_screen.dart';

class AnimalsListScreen extends StatefulWidget {
  const AnimalsListScreen({super.key});

  @override
  State<AnimalsListScreen> createState() => _AnimalsListScreenState();
}

class _AnimalsListScreenState extends State<AnimalsListScreen> {
  final AnimalService _animalService = AnimalService();
  dynamic _selectedFilter = 'all';

  final List<Map<String, dynamic>> _filterOptions = [
    {'value': 'all', 'label': 'Todos'},
    {'value': AnimalStatus.underTreatment, 'label': 'Em Tratamento'},
    {'value': AnimalStatus.availableForAdoption, 'label': 'Disponíveis'},
    {'value': AnimalStatus.adopted, 'label': 'Adotados'},
    {'value': AnimalStatus.missing, 'label': 'Desaparecidos'},
  ];

  void _onFilterChanged(dynamic filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animais Resgatados'),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            // Usamos StreamBuilder para atualizações em tempo real do Firebase
            child: StreamBuilder<List<Animal>>(
              stream: _animalService.getAnimalsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorMessage(
                    message: 'Erro ao carregar dados do Firebase.',
                    onRetry: () => setState(() {}),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Conectando ao Firebase...');
                }

                final allAnimals = snapshot.data ?? [];
                
                // Aplicamos o filtro localmente nos dados que vieram do Stream
                final filteredAnimals = _selectedFilter == 'all'
                    ? allAnimals
                    : allAnimals.where((a) => a.status == _selectedFilter).toList();

                if (filteredAnimals.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredAnimals.length,
                  itemBuilder: (context, index) {
                    final animal = filteredAnimals[index];
                    return AnimalCard(
                      animal: animal,
                      onTap: () => _showAnimalDetails(animal),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToRegisterAnimal(context),
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar'),
      ),
    );
  }

  // --- Widgets Auxiliares (Mantidos e adaptados do seu código original) ---

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((option) {
            final isSelected = _selectedFilter == option['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(option['label']),
                selected: isSelected,
                onSelected: (_) => _onFilterChanged(option['value']),
                selectedColor: Colors.orange.withOpacity(0.2),
                checkmarkColor: Colors.orange,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.orange : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = _selectedFilter == 'all'
        ? 'Nenhum animal cadastrado.'
        : 'Nenhum animal encontrado com este status.';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          if (_selectedFilter != 'all') ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _onFilterChanged('all'),
              child: const Text('Ver todos'),
            ),
          ],
        ],
      ),
    );
  }

  void _showAnimalDetails(Animal animal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: animal.imageUrl != null && animal.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                animal.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.broken_image, size: 60),
                              ),
                            )
                          : const Icon(Icons.pets, size: 60),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    animal.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(animal.status),
                  const SizedBox(height: 24),
                  _buildDetailRow('Espécie', animal.species),
                  if (animal.age != null) _buildDetailRow('Idade', '${animal.age} anos'),
                  
                  if (animal.status == AnimalStatus.adopted || animal.status == AnimalStatus.missing) ...[
                    const Divider(height: 32),
                    Text(
                      animal.status == AnimalStatus.missing ? 'Dono/Contato' : 'Adotante',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Nome', animal.adopterName ?? 'Não informado'),
                    _buildDetailRow('Telefone', animal.adopterPhone ?? 'Não informado'),
                  ],

                  const Divider(height: 32),
                  const Text('Descrição', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(animal.description),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(AnimalStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label, // Usando a extensão que criamos no Model
        style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getStatusColor(AnimalStatus status) {
    switch (status) {
      case AnimalStatus.underTreatment: return Colors.orange;
      case AnimalStatus.availableForAdoption: return Colors.green;
      case AnimalStatus.adopted: return Colors.blue;
      case AnimalStatus.missing: return Colors.red;
    }
  }

  void _navigateToRegisterAnimal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterAnimalScreen()),
    );
    // Nota: Com o StreamBuilder, você nem precisa checar o "result == true", 
    // a lista atualizará sozinha assim que o Firestore salvar!
  }
}