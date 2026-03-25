import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:patinhas_amor/models/occurrence.dart';
import 'package:patinhas_amor/services/occurrence_service.dart';

class RegisterOccurrenceScreen extends StatefulWidget {
  final Occurrence? occurrence;

  const RegisterOccurrenceScreen({super.key, this.occurrence});

  @override
  State<RegisterOccurrenceScreen> createState() => _RegisterOccurrenceScreenState();
}

class _RegisterOccurrenceScreenState extends State<RegisterOccurrenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final OccurrenceService _occurrenceService = OccurrenceService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _typeController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  bool _isLoading = false;
  String? _selectedImagePath;
  String? _remoteImageUrl;
  OccurrenceStatus _status = OccurrenceStatus.pending;

  final List<String> _typeOptions = ['Abandono', 'Maus-tratos', 'Animal Ferido', 'Animal de Rua', 'Outro'];

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.occurrence?.type ?? '');
    _descriptionController = TextEditingController(text: widget.occurrence?.description ?? '');
    _locationController = TextEditingController(text: widget.occurrence?.location ?? '');
    _latController = TextEditingController(text: widget.occurrence?.latitude?.toString() ?? '');
    _lngController = TextEditingController(text: widget.occurrence?.longitude?.toString() ?? '');

    if (widget.occurrence != null) {
      _status = widget.occurrence!.status;
      _remoteImageUrl = widget.occurrence!.imageUrl;
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // --- VALIDAÇÕES DE REQUISITOS ---

  Future<bool> _checkRequirements() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _showErrorDialog("Sem Internet", "Você precisa de conexão para salvar ou ver o mapa.");
      return false;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog("GPS Desativado", "Por favor, ative o GPS do seu aparelho.");
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar("Permissão de localização negada.", Colors.red);
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog("Permissão Necessária", "Ative a localização nas configurações do sistema.");
      return false;
    }

    return true;
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }

  // --- LÓGICA DE LOCALIZAÇÃO ---

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      if (await _checkRequirements()) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _latController.text = position.latitude.toString();
          _lngController.text = position.longitude.toString();
        });
        _showSnackBar("Localização GPS capturada!", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Erro ao obter GPS: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openMapPicker() async {
    if (!await _checkRequirements()) return;

    // Tenta pegar a posição atual para centralizar o mapa caso não exista uma salva
    Position? currentPos;
    try {
      currentPos = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 5));
    } catch (_) {}

    double initialLat = double.tryParse(_latController.text) ?? currentPos?.latitude ?? -26.2300;
    double initialLng = double.tryParse(_lngController.text) ?? currentPos?.longitude ?? -51.0800;

    LatLng? selectedPoint = await showDialog<LatLng>(
      context: context,
      builder: (context) => _MapPickerDialog(
        initialCenter: LatLng(initialLat, initialLng),
        userRealLocation: currentPos != null ? LatLng(currentPos.latitude, currentPos.longitude) : null,
      ),
    );

    if (selectedPoint != null) {
      setState(() {
        _latController.text = selectedPoint.latitude.toString();
        _lngController.text = selectedPoint.longitude.toString();
      });
    }
  }

  void _showLocationOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Selecionar Localização", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.my_location, color: Colors.orange),
              title: const Text("Usar localização atual (GPS Rápido)"),
              onTap: () { Navigator.pop(context); _getCurrentLocation(); },
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.orange),
              title: const Text("Selecionar no Mapa (Visual)"),
              onTap: () { Navigator.pop(context); _openMapPicker(); },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // --- FORMULÁRIO ---

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (image != null) setState(() => _selectedImagePath = image.path);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await _checkRequirements()) return;
    
    if (_latController.text.isEmpty || _lngController.text.isEmpty) {
      _showSnackBar("A localização no mapa é obrigatória!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? finalImageUrl = _remoteImageUrl;
      if (_selectedImagePath != null) {
        finalImageUrl = await _occurrenceService.uploadOccurrenceImage(File(_selectedImagePath!));
      }

      final occurrenceData = Occurrence(
        id: widget.occurrence?.id,
        type: _typeController.text,
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        imageUrl: finalImageUrl,
        status: _status,
        latitude: double.tryParse(_latController.text),
        longitude: double.tryParse(_lngController.text),
        createdAt: widget.occurrence?.createdAt,
      );

      if (widget.occurrence == null) {
        await _occurrenceService.createOccurrence(occurrenceData);
      } else {
        await _occurrenceService.updateOccurrence(occurrenceData);
      }

      if (mounted) {
        _showSnackBar('Ocorrência salva com sucesso!', Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Erro ao salvar: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasLocation = _latController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.occurrence == null ? 'Nova Ocorrência' : 'Editar Ocorrência')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 32),
              const Text("Dados da Ocorrência", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipo', prefixIcon: Icon(Icons.report_problem), border: OutlineInputBorder()),
                value: _typeOptions.contains(_typeController.text) ? _typeController.text : null,
                items: _typeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _typeController.text = v!),
                validator: (v) => v == null ? 'Selecione o tipo' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Endereço Aproximado / Ponto de Ref.', prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Informe o local por escrito' : null,
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _isLoading ? null : _showLocationOptions,
                icon: Icon(hasLocation ? Icons.check_circle : Icons.add_location_alt),
                label: Text(hasLocation ? "COORDENADAS CAPTURADAS" : "DEFINIR NO MAPA (OBRIGATÓRIO)"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  foregroundColor: hasLocation ? Colors.green : Colors.orange,
                  side: BorderSide(color: hasLocation ? Colors.green : Colors.orange, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descrição da Situação', alignLabelWithHint: true, border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Descreva o que está acontecendo' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<OccurrenceStatus>(
                decoration: const InputDecoration(labelText: 'Status Atual', border: OutlineInputBorder()),
                value: _status,
                items: OccurrenceStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isLoading || !hasLocation) ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, 
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("SALVAR OCORRÊNCIA", style: TextStyle(fontWeight: FontWeight.bold)),
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
            onTap: () => _showImageSourceOptions(),
            child: Container(
              width: double.infinity, height: 220,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[300]!)),
              child: _selectedImagePath != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_selectedImagePath!), fit: BoxFit.cover))
                  : _remoteImageUrl != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(_remoteImageUrl!, fit: BoxFit.cover))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          Text('Foto da ocorrência', style: TextStyle(color: Colors.grey))
                        ]),
            ),
          ),
          if (_selectedImagePath != null || _remoteImageUrl != null)
            Positioned(bottom: 12, right: 12, child: FloatingActionButton.small(onPressed: _showImageSourceOptions, backgroundColor: Colors.orange, child: const Icon(Icons.edit, color: Colors.white))),
        ],
      ),
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_library, color: Colors.orange), title: const Text('Galeria'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
            ListTile(leading: const Icon(Icons.camera_alt, color: Colors.orange), title: const Text('Câmera'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
          ],
        ),
      ),
    );
  }
}

// --- DIÁLOGO DO MAPA ATUALIZADO ---

class _MapPickerDialog extends StatefulWidget {
  final LatLng initialCenter;
  final LatLng? userRealLocation; // Nova propriedade para o ponto azul
  
  const _MapPickerDialog({required this.initialCenter, this.userRealLocation});

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  late LatLng _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialCenter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Selecione o local no mapa"),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: widget.initialCenter,
                initialZoom: 15,
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture) {
                    setState(() => _selectedPoint = pos.center!);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.patinhas_amor.app',
                ),
                // Camada do Ponto Azul (Onde o usuário está agora)
                if (widget.userRealLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.userRealLocation!,
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // Ícone Vermelho (O "alvo" central que seleciona a posição)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 35),
                child: Icon(Icons.location_on, size: 45, color: Colors.red),
              ),
            ),
            // Botão flutuante para voltar a centralizar no usuário (opcional)
            if (widget.userRealLocation != null)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  onPressed: () {
                    // Aqui você precisaria de um MapController para mover o mapa programaticamente.
                    // Para simplificar, o ponto azul serve apenas como referência visual.
                  },
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedPoint), 
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
          child: const Text("Confirmar Local"),
        ),
      ],
    );
  }
}