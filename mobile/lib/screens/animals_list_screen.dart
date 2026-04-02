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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir Animal'),
        content: Text('Tem certeza que deseja remover "${animal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context); // Fecha o BottomSheet se estiver aberto
              
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
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Animais Resgatados', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
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
                    message: 'Erro ao carregar dados.',
                    onRetry: () => setState(() {}),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Buscando amiguinhos...');
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filteredAnimals.length,
                    itemBuilder: (context, index) {
                      final animal = filteredAnimals[index];
                      // Usando o componente nativo de Opacidade para uma entrada suave
                      return AnimatedOpacity(
                        duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 500)),
                        opacity: 1.0,
                        curve: Curves.easeIn,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AnimalCard(
                            animal: animal,
                            onTap: () => _showAnimalDetails(animal),
                          ),
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
        elevation: 4,
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(option['label']),
              selected: isSelected,
              onSelected: (_) => _onFilterChanged(option['value']),
              selectedColor: Colors.orange,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              elevation: isSelected ? 4 : 0,
              pressElevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nenhum animal nesta categoria.',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 50, height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                
                // Hero nativo para transição de imagem (garanta que o AnimalCard tenha o mesmo Hero Tag)
                Hero(
                  tag: 'animal_image_${animal.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 1.5,
                      child: animal.imageUrl != null && animal.imageUrl!.isNotEmpty
                          ? Image.network(animal.imageUrl!, fit: BoxFit.cover)
                          : Container(color: Colors.grey[200], child: const Icon(Icons.pets, size: 80, color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(animal.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                    Row(
                      children: [
                        _buildCircleActionButton(
                          icon: Icons.edit_outlined, 
                          color: Colors.orange,
                          onPressed: () {
                            Navigator.pop(context);
                            _navigateToRegisterAnimal(context, animal: animal);
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildCircleActionButton(
                          icon: Icons.delete_outline, 
                          color: Colors.red,
                          onPressed: () => _confirmDelete(context, animal),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildStatusBadge(animal.status),
                const Divider(height: 48),

                _buildInfoSection(
                  title: "Localização",
                  icon: Icons.location_on_rounded,
                  content: animal.currentLocation ?? "Não informada",
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 24),

                const Text("Características", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: [
                    _buildFeatureChip(Icons.category_rounded, animal.species),
                    _buildFeatureChip(Icons.wc_rounded, animal.sex ?? "Não inf."),
                    _buildFeatureChip(Icons.straighten_rounded, animal.size ?? "Porte"),
                    _buildFeatureChip(Icons.cake_rounded, animal.age != null ? "${animal.age} anos" : "Idade"),
                  ],
                ),

                const SizedBox(height: 32),
                const Text('Descrição', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  animal.description.isEmpty ? 'Sem descrição.' : animal.description,
                  style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey[800]),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircleActionButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: color), onPressed: onPressed),
    );
  }

  Widget _buildInfoSection({required String title, required IconData icon, required String content, required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            Text(content, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AnimalStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
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
    // Usando PageRouteBuilder nativo para uma transição de Fade sem pacotes externos
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => RegisterAnimalScreen(animal: animal),
        transitionsBuilder: (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}