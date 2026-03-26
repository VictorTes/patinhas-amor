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
    _animalService.dispose();
    super.dispose();
  }

  void _onFilterChanged(dynamic filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _confirmDelete(BuildContext context, Animal animal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Animal'),
        content: Text('Tem certeza que deseja remover "${animal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context); // Fecha o BottomSheet
              
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
                    message: 'Erro ao carregar dados do Firebase.',
                    onRetry: () => setState(() {}),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Carregando...');
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Nenhum animal encontrado.', style: TextStyle(color: Colors.grey[600])),
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
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(24),
              children: [
                // Barra de arraste
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                
                // Imagem Principal
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: animal.imageUrl != null && animal.imageUrl!.isNotEmpty
                        ? Image.network(animal.imageUrl!, fit: BoxFit.cover)
                        : Container(color: Colors.grey[200], child: const Icon(Icons.pets, size: 80, color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 20),

                // Nome e Ações
                Row(
                  children: [
                    Expanded(
                      child: Text(animal.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ),
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
                
                _buildStatusBadge(animal.status),
                const SizedBox(height: 24),

                // Seção: Onde o animal está?
                _buildInfoSection(
                  title: "Localização Atual",
                  icon: Icons.location_on,
                  content: animal.currentLocation ?? "Não informada",
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),

                // Seção: Características
                const Text("Características", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildFeatureChip(Icons.category, animal.species),
                    _buildFeatureChip(Icons.wc, animal.sex ?? "Não inf."),
                    _buildFeatureChip(Icons.straighten, animal.size ?? "Porte desconhecido"),
                    _buildFeatureChip(Icons.cake, animal.age != null ? "${animal.age} anos" : "Idade desconhecida"),
                  ],
                ),

                if (animal.status == AnimalStatus.adopted || animal.status == AnimalStatus.missing) ...[
                  const Divider(height: 40),
                  Text(
                    animal.status == AnimalStatus.missing ? 'Contato para Resgate' : 'Dados do Adotante',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Nome', animal.adopterName ?? 'Não informado'),
                  _buildDetailRow('Telefone', animal.adopterPhone ?? 'Não informado'),
                  _buildDetailRow('Endereço', animal.adopterAddress ?? 'Não informado'),
                ],

                const Divider(height: 40),
                const Text('Descrição / História', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  animal.description.isEmpty ? 'Nenhuma descrição fornecida.' : animal.description,
                  style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection({required String title, required IconData icon, required String content, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                Text(content, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AnimalStatus status) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
        ),
        child: Text(
          status.label.toUpperCase(),
          style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          Text(value, style: const TextStyle(color: Colors.black87)),
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

  void _navigateToRegisterAnimal(BuildContext context, {Animal? animal}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterAnimalScreen(animal: animal)),
    );
  }
}