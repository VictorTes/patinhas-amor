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

  List<Animal> _allAnimals = [];
  List<Animal> _filteredAnimals = [];

  bool _isLoading = true;
  String? _errorMessage;

  dynamic _selectedFilter = 'all';

  final List<Map<String, dynamic>> _filterOptions = [
    {'value': 'all', 'label': 'Todos'},
    {'value': AnimalStatus.underTreatment, 'label': 'Em Tratamento'},
    {'value': AnimalStatus.availableForAdoption, 'label': 'Disponíveis'},
    {'value': AnimalStatus.adopted, 'label': 'Adotados'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final animals = await _animalService.fetchAnimals();

      setState(() {
        _allAnimals = animals;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Não foi possível carregar os animais.';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'all') {
      _filteredAnimals = List.from(_allAnimals);
    } else {
      _filteredAnimals = _allAnimals
          .where((animal) => animal.status == _selectedFilter)
          .toList();
    }
  }

  void _onFilterChanged(dynamic filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  @override
  void dispose() {
    _animalService.dispose();
    super.dispose();
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
            child: _buildBody(),
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
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Carregando animais...');
    }

    if (_errorMessage != null) {
      return ErrorMessage(
        message: _errorMessage!,
        onRetry: _loadAnimals,
      );
    }

    if (_filteredAnimals.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAnimals,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _filteredAnimals.length,
        itemBuilder: (context, index) {
          final animal = _filteredAnimals[index];

          return AnimalCard(
            animal: animal,
            onTap: () => _showAnimalDetails(animal),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;

    if (_selectedFilter == 'all') {
      message = 'Nenhum animal cadastrado.';
    } else {
      message = 'Nenhum animal encontrado com este status.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
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
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: animal.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                animal.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.pets, size: 60),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    animal.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(animal.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(animal.status),
                      style: TextStyle(
                        color: _getStatusColor(animal.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildDetailRow('Espécie', animal.species),

                  if (animal.age != null)
                    _buildDetailRow('Idade', '${animal.age} anos'),

                  const SizedBox(height: 16),

                  const Text(
                    'Descrição',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Color _getStatusColor(AnimalStatus status) {
    switch (status) {
      case AnimalStatus.underTreatment:
        return Colors.orange;

      case AnimalStatus.availableForAdoption:
        return Colors.green;

      case AnimalStatus.adopted:
        return Colors.blue;
    }
  }

  String _getStatusText(AnimalStatus status) {
    switch (status) {
      case AnimalStatus.underTreatment:
        return 'Em Tratamento';

      case AnimalStatus.availableForAdoption:
        return 'Disponível para Adoção';

      case AnimalStatus.adopted:
        return 'Adotado';
    }
  }

  Future<void> _navigateToRegisterAnimal(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterAnimalScreen(),
      ),
    );

    if (result == true) {
      _loadAnimals();
    }
  }
}