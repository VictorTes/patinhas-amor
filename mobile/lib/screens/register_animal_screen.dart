import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:patinhas_amor/models/animal.dart';
import 'package:patinhas_amor/services/animal_service.dart';
import 'package:patinhas_amor/widgets/loading_indicator.dart';

class RegisterAnimalScreen extends StatefulWidget {
  const RegisterAnimalScreen({super.key});

  @override
  State<RegisterAnimalScreen> createState() => _RegisterAnimalScreenState();
}

class _RegisterAnimalScreenState extends State<RegisterAnimalScreen> {
  final _formKey = GlobalKey<FormState>();

  final AnimalService _animalService = AnimalService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _submitSuccess = false;

  String? _selectedImagePath;

  String _name = '';
  String? _species;
  int? _age;
  String _description = '';
  AnimalStatus _status = AnimalStatus.underTreatment;

  String? _sex;
  String? _size;

  String? _adopterName;
  String? _adopterAddress;
  String? _adopterPhone;

  final List<String> _speciesOptions = ['Cachorro', 'Gato', 'Outro'];

  final List<int?> _ageOptions = [
    null,
    ...List.generate(20, (index) => index + 1),
  ];

  final List<String> _sexOptions = ['Macho', 'Fêmea'];

  final List<String> _sizeOptions = [
    'Pequeno',
    'Médio',
    'Grande',
    'Porte desconhecido'
  ];

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': AnimalStatus.underTreatment, 'label': 'Em Tratamento'},
    {
      'value': AnimalStatus.availableForAdoption,
      'label': 'Disponível para Adoção'
    },
    {'value': AnimalStatus.adopted, 'label': 'Adotado'},
  ];

  @override
  void dispose() {
    _animalService.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  Future<void> _takePhoto() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        _selectedImagePath = photo.path;
      });
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final animal = Animal(
        id: 0,
        name: _name,
        species: _species ?? '',
        age: _age,
        description: _description,
        status: _status,
        imageUrl: _selectedImagePath,
        rescueDate: DateTime.now(),
        sex: _sex,
        size: _size,
        adopterName: _status == AnimalStatus.adopted ? _adopterName : null,
        adopterAddress:
            _status == AnimalStatus.adopted ? _adopterAddress : null,
        adopterPhone: _status == AnimalStatus.adopted ? _adopterPhone : null,
      );

      await _animalService.createAnimal(animal);

      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _isLoading = false;
        _submitSuccess = true;
      });

      await Future.delayed(const Duration(milliseconds: 900));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao cadastrar animal: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Animal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 32),
              _buildSectionTitle("Informações Básicas"),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nome do Animal',
                  prefixIcon: Icon(Icons.pets),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o nome' : null,
                onSaved: (value) => _name = value!.trim(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Espécie',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                value: _species,
                items: _speciesOptions.map((species) {
                  return DropdownMenuItem(
                    value: species,
                    child: Text(species),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _species = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                  labelText: 'Idade',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                value: _age,
                items: _ageOptions.map((age) {
                  return DropdownMenuItem(
                    value: age,
                    child:
                        Text(age == null ? 'Idade desconhecida' : '$age anos'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _age = value),
              ),
              const SizedBox(height: 28),
              _buildSectionTitle("Características"),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Sexo',
                  prefixIcon: Icon(Icons.pets_outlined),
                  border: OutlineInputBorder(),
                ),
                value: _sex,
                items: _sexOptions.map((sex) {
                  return DropdownMenuItem(
                    value: sex,
                    child: Text(sex),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _sex = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Porte',
                  prefixIcon: Icon(Icons.straighten),
                  border: OutlineInputBorder(),
                ),
                value: _size,
                items: _sizeOptions.map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text(size),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _size = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: 28),
              _buildSectionTitle("Situação"),
              DropdownButtonFormField<AnimalStatus>(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                ),
                value: _status,
                items: _statusOptions.map((option) {
                  return DropdownMenuItem(
                    value: option['value'] as AnimalStatus,
                    child: Text(option['label']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _status = value!),
              ),
              if (_status == AnimalStatus.adopted) ...[
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nome do adotante',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => _adopterName = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    prefixIcon: Icon(Icons.home),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => _adopterAddress = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  onSaved: (value) => _adopterPhone = value,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _submitSuccess ? Colors.green : Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : _submitSuccess
                          ? const Icon(Icons.check)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.save),
                                SizedBox(width: 8),
                                Text("Cadastrar Animal"),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _showImageSourceOptions,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: _selectedImagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(_selectedImagePath!),
                    fit: BoxFit.cover,
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48),
                      SizedBox(height: 8),
                      Text('Adicionar Foto'),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
