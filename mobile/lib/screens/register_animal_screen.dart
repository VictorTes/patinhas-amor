import 'dart:io';
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
  final List<int?> _ageOptions = [null, ...List.generate(20, (index) => index + 1)];
  final List<String> _sexOptions = ['Macho', 'Fêmea'];
  final List<String> _sizeOptions = ['Pequeno', 'Médio', 'Grande', 'Porte desconhecido'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.animal?.name ?? '');
    _descriptionController = TextEditingController(text: widget.animal?.description ?? '');
    _adopterNameController = TextEditingController(text: widget.animal?.adopterName ?? '');
    _adopterAddressController = TextEditingController(text: widget.animal?.adopterAddress ?? '');
    _adopterPhoneController = TextEditingController(text: widget.animal?.adopterPhone ?? '');

    if (widget.animal != null) {
      // Travas de segurança para Dropdowns
      _species = _speciesOptions.contains(widget.animal!.species) ? widget.animal!.species : null;
      _sex = _sexOptions.contains(widget.animal!.sex) ? widget.animal!.sex : null;
      _size = _sizeOptions.contains(widget.animal!.size) ? widget.animal!.size : null;
      
      _age = widget.animal!.age;
      _status = widget.animal!.status;
      _remoteImageUrl = widget.animal!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _adopterNameController.dispose();
    _adopterAddressController.dispose();
    _adopterPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (image != null) setState(() => _selectedImagePath = image.path);
  }

  Future<void> _takePhoto() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (photo != null) setState(() => _selectedImagePath = photo.path);
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galeria'), onTap: () { Navigator.pop(context); _pickImage(); }),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Câmera'), onTap: () { Navigator.pop(context); _takePhoto(); }),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _remoteImageUrl;

      // Se o usuário selecionou uma imagem nova, faz o upload para o Cloudinary
      if (_selectedImagePath != null) {
        finalImageUrl = await _animalService.uploadAnimalImage(File(_selectedImagePath!));
        if (finalImageUrl == null) throw Exception('Erro ao subir imagem para o Cloudinary.');
      }

      final animalData = Animal(
        id: widget.animal?.id,
        name: _nameController.text.trim(),
        species: _species ?? 'Outro',
        age: _age,
        description: _descriptionController.text.trim(),
        status: _status,
        imageUrl: finalImageUrl,
        rescueDate: widget.animal?.rescueDate ?? DateTime.now(),
        sex: _sex,
        size: _size,
        adopterName: (_status == AnimalStatus.adopted || _status == AnimalStatus.missing) ? _adopterNameController.text : null,
        adopterAddress: (_status == AnimalStatus.adopted || _status == AnimalStatus.missing) ? _adopterAddressController.text : null,
        adopterPhone: (_status == AnimalStatus.adopted || _status == AnimalStatus.missing) ? _adopterPhoneController.text : null,
      );

      if (widget.animal == null) {
        await _animalService.createAnimal(animalData);
      } else {
        await _animalService.updateAnimal(animalData);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _submitSuccess = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.animal == null ? 'Cadastrado com sucesso!' : 'Atualizado com sucesso!'), backgroundColor: Colors.green),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao salvar: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.animal != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Animal' : 'Cadastrar Animal')),
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
                decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.pets), border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Espécie', prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
                value: _speciesOptions.contains(_species) ? _species : null,
                items: _speciesOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (value) => setState(() => _species = value),
                validator: (value) => value == null ? 'Selecione a espécie' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                decoration: const InputDecoration(labelText: 'Idade', prefixIcon: Icon(Icons.cake), border: OutlineInputBorder()),
                value: _age,
                items: _ageOptions.map((a) => DropdownMenuItem(value: a, child: Text(a == null ? 'Desconhecida' : '$a anos'))).toList(),
                onChanged: (value) => setState(() => _age = value),
              ),
              const SizedBox(height: 28),
              _buildSectionTitle("Características"),
              _buildDropdownField('Sexo', Icons.wc, _sex, _sexOptions, (v) => setState(() => _sex = v)),
              const SizedBox(height: 16),
              _buildDropdownField('Porte', Icons.straighten, _size, _sizeOptions, (v) => setState(() => _size = v)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição', prefixIcon: Icon(Icons.description), border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 28),
              _buildSectionTitle("Situação"),
              DropdownButtonFormField<AnimalStatus>(
                decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.info_outline), border: OutlineInputBorder()),
                value: _status,
                items: AnimalStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                onChanged: (value) => setState(() => _status = value!),
              ),
              if (_status == AnimalStatus.adopted || _status == AnimalStatus.missing) ...[
                const SizedBox(height: 16),
                TextFormField(controller: _adopterNameController, decoration: const InputDecoration(labelText: 'Nome do Contato', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextFormField(controller: _adopterAddressController, decoration: const InputDecoration(labelText: 'Endereço', prefixIcon: Icon(Icons.home), border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextFormField(controller: _adopterPhoneController, decoration: const InputDecoration(labelText: 'Telefone', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: _submitSuccess ? Colors.green : Colors.orange, foregroundColor: Colors.white),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(isEditing ? "Salvar Alterações" : "Cadastrar Animal"),
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
          width: 160, height: 160,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
          child: _selectedImagePath != null
              ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(_selectedImagePath!), fit: BoxFit.cover))
              : _remoteImageUrl != null && _remoteImageUrl!.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(_remoteImageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40)))
                  : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40), Text('Adicionar Foto')])),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, IconData icon, String? value, List<String> options, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
      value: options.contains(value) ? value : null,
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
  }
}