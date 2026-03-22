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

  @override
  void dispose() {
    super.dispose();
  }

  void _onFilterChanged(dynamic filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  // MÉTODO PARA CONFIRMAR E EXCLUIR (Recuperado)
  void _confirmDelete(BuildContext context, Animal animal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Animal'),
        content: Text('Tem certeza que deseja remover "${animal.name}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); 
              Navigator.pop(context); 
              
              try {
                await _animalService.deleteAnimal(animal.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Animal removido com sucesso!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animais Resgatados'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<List<Animal>>(
              stream: _animalService.getAnimalsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorMessage(
                    message: 'Não foi possível conectar ao Firebase.\nVerifique sua internet.',
                    onRetry: () => setState(() {}),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Buscando animais...');
                }

                final allAnimals = snapshot.data ?? [];
                
                final filteredAnimals = _selectedFilter == 'all'
                    ? allAnimals
                    : allAnimals.where((a) => a.status == _selectedFilter).toList();

                if (filteredAnimals.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: filteredAnimals.length,
                    itemBuilder: (context, index) {
                      final animal = filteredAnimals[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnimalCard(
                          animal: animal,
                          onTap: () => _showAnimalDetails(animal),
                        ),
                      );
                    },
                  ),
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
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
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
                color: isSelected ? Colors.orange[800] : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: controller,
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToRegisterAnimal(context, animal: animal);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context, animal),
                    ),
                  ],
                ),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey[100],
                      child: animal.imageUrl != null && animal.imageUrl!.isNotEmpty
                          ? Image.network(
                              animal.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                            )
                          : const Icon(Icons.pets, size: 80, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        animal.name,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildStatusBadge(animal.status),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Espécie', animal.species),
                if (animal.sex != null) _buildDetailRow('Sexo', animal.sex!),
                if (animal.size != null) _buildDetailRow('Porte', animal.size!),
                if (animal.age != null) _buildDetailRow('Idade Estimada', '${animal.age} anos'),
                
                const Divider(height: 40),
                const Text('Descrição / História', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  animal.description.isEmpty ? 'Nenhuma descrição.' : animal.description,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
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
        border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
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

  void _navigateToRegisterAnimal(BuildContext context, {Animal? animal}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterAnimalScreen(animal: animal),
      ),
    );
  }
}