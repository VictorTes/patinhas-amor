import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patinhas_amor/models/animal.dart';
import 'package:patinhas_amor/services/animal_service.dart';

class RegisterAnimalScreen extends StatefulWidget {
  final Animal? animal;

  const RegisterAnimalScreen({super.key, this.animal});

  @override
  State<RegisterAnimalScreen> createState() => _RegisterAnimalScreenState();
}

class _RegisterAnimalScreenState extends State<RegisterAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final AnimalService _animalService = AnimalService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _adopterNameController;
  late TextEditingController _adopterAddressController;
  late TextEditingController _adopterPhoneController;

  bool _isLoading = false;
  bool _submitSuccess = false;

  String? _selectedImagePath;
  String? _remoteImageUrl;

  String? _species;
  int? _age;
  AnimalStatus _status = AnimalStatus.underTreatment;
  String? _sex;
  String? _size;

  final List<String> _speciesOptions = ['Cachorro', 'Gato', 'Outro'];
  final List<int?> _ageOptions = [
    null,
    ...List.generate(20, (index) => index + 1)
  ];
  final List<String> _sexOptions = ['Macho', 'Fêmea'];
  final List<String> _sizeOptions = [
    'Pequeno',
    'Médio',
    'Grande',
    'Porte desconhecido'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.animal?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.animal?.description ?? '');
    _locationController =
        TextEditingController(text: widget.animal?.currentLocation ?? '');
    _adopterNameController =
        TextEditingController(text: widget.animal?.adopterName ?? '');
    _adopterAddressController =
        TextEditingController(text: widget.animal?.adopterAddress ?? '');
    _adopterPhoneController =
        TextEditingController(text: widget.animal?.adopterPhone ?? '');

    if (widget.animal != null) {
      _species = _speciesOptions.contains(widget.animal!.species)
          ? widget.animal!.species
          : null;
      _sex =
          _sexOptions.contains(widget.animal!.sex) ? widget.animal!.sex : null;
      _size = _sizeOptions.contains(widget.animal!.size)
          ? widget.animal!.size
          : null;

      _age = widget.animal!.age;
      _status = widget.animal!.status;
      _remoteImageUrl = widget.animal!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _adopterNameController.dispose();
    _adopterAddressController.dispose();
    _adopterPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(
        source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (image != null) setState(() => _selectedImagePath = image.path);
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Foto do Animal",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.orange),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }),
            ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.orange),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final isNew = widget.animal == null;
      String? finalImageUrl = _remoteImageUrl;

      if (_selectedImagePath != null) {
        finalImageUrl =
            await _animalService.uploadAnimalImage(File(_selectedImagePath!));
        if (finalImageUrl == null) throw Exception('Erro ao subir imagem.');
      }

      final animalData = Animal(
        id: widget.animal?.id,
        name: _nameController.text.trim(),
        species: _species ?? 'Outro',
        age: _age,
        description: _descriptionController.text.trim(),
        currentLocation: _locationController.text.trim(),
        status: _status,
        imageUrl: finalImageUrl,
        rescueDate: widget.animal?.rescueDate ?? DateTime.now(),
        sex: _sex,
        size: _size,
        adopterName:
            (_status == AnimalStatus.adopted || _status == AnimalStatus.missing)
                ? _adopterNameController.text
                : null,
        adopterAddress:
            (_status == AnimalStatus.adopted || _status == AnimalStatus.missing)
                ? _adopterAddressController.text
                : null,
        adopterPhone:
            (_status == AnimalStatus.adopted || _status == AnimalStatus.missing)
                ? _adopterPhoneController.text
                : null,
      );

      if (isNew) {
        // Cria o animal e gera o ID
        final createdAnimal = await _animalService.createAnimal(animalData);

        // Registra a atividade no mural
        final String targetId = createdAnimal.id ??
            DateTime.now().millisecondsSinceEpoch.toString();

        await FirebaseFirestore.instance.collection('activities').add({
          'type': 'animal',
          'title': 'Novo Animal Cadastrado',
          'description':
              'O(a) animal ${_nameController.text.trim()} foi cadastrado(a) no sistema.',
          'targetId': targetId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _animalService.updateAnimal(animalData);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _submitSuccess = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.animal == null
                  ? 'Cadastrado com sucesso!'
                  : 'Atualizado com sucesso!'),
              backgroundColor: Colors.green),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.animal != null;

    return Scaffold(
      appBar:
          AppBar(title: Text(isEditing ? 'Editar Animal' : 'Cadastrar Animal')),
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
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.pets),
                    border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Localização Atual (Onde ele está?)',
                  hintText: 'Ex: Lar Temporário, Clínica, Casa do Adotante',
                  prefixIcon: Icon(Icons.location_on, color: Colors.orange),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Informe onde o animal se encontra'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'Espécie',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder()),
                value: _speciesOptions.contains(_species) ? _species : null,
                items: _speciesOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _species = value),
                validator: (value) =>
                    value == null ? 'Selecione a espécie' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                    labelText: 'Idade aproximada',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder()),
                value: _age,
                items: _ageOptions
                    .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a == null ? 'Desconhecida' : '$a anos')))
                    .toList(),
                onChanged: (value) => setState(() => _age = value),
              ),
              const SizedBox(height: 28),
              _buildSectionTitle("Características"),
              _buildDropdownField('Sexo', Icons.wc, _sex, _sexOptions,
                  (v) => setState(() => _sex = v)),
              const SizedBox(height: 16),
              _buildDropdownField('Porte', Icons.straighten, _size,
                  _sizeOptions, (v) => setState(() => _size = v)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Descrição/História',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 28),
              _buildSectionTitle("Situação Atual"),
              DropdownButtonFormField<AnimalStatus>(
                decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.info_outline),
                    border: OutlineInputBorder()),
                value: _status,
                items: AnimalStatus.values
                    .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (value) => setState(() => _status = value!),
              ),
              if (_status == AnimalStatus.adopted ||
                  _status == AnimalStatus.missing) ...[
                const SizedBox(height: 24),
                _buildSectionTitle("Dados do Adotante / Contato"),
                TextFormField(
                    controller: _adopterNameController,
                    decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _adopterAddressController,
                    decoration: const InputDecoration(
                        labelText: 'Endereço',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _adopterPhoneController,
                    decoration: const InputDecoration(
                        labelText: 'Telefone de Contato',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone),
              ],
              const SizedBox(height: 40),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _submitSuccess ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? "SALVAR ALTERAÇÕES" : "CADASTRAR ANIMAL",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
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
      child: Stack(
        children: [
          GestureDetector(
            onTap: _showImageSourceOptions,
            child: Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!)),
              child: _selectedImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(_selectedImagePath!),
                          fit: BoxFit.cover))
                  : _remoteImageUrl != null && _remoteImageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(_remoteImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 40)))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(Icons.add_a_photo,
                                  size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Adicionar Foto do Animal',
                                  style: TextStyle(color: Colors.grey))
                            ]),
            ),
          ),
          if (_selectedImagePath != null ||
              (_remoteImageUrl != null && _remoteImageUrl!.isNotEmpty))
            Positioned(
              bottom: 12,
              right: 12,
              child: FloatingActionButton.small(
                onPressed: _showImageSourceOptions,
                backgroundColor: Colors.orange,
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, IconData icon, String? value,
      List<String> options, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder()),
      value: options.contains(value) ? value : null,
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange)));
  }
}
