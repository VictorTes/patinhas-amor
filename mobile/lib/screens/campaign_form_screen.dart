import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';

class CampaignFormScreen extends StatefulWidget {
  final CampaignModel? campaign; // Se vier preenchido, é modo edição

  const CampaignFormScreen({super.key, this.campaign});

  @override
  State<CampaignFormScreen> createState() => _CampaignFormScreenState();
}

class _CampaignFormScreenState extends State<CampaignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CampaignService();
  final _picker = ImagePicker();

  bool _isLoading = false;

  // Controllers Gerais
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  CampaignType _selectedType = CampaignType.rifa;
  
  // Imagens
  File? _mainImage;
  List<File> _receiptFiles = [];

  // Controllers Rifa
  final _goalController = TextEditingController();
  final _ticketValueController = TextEditingController();
  final _prizeController = TextEditingController();

  // Controllers Bazar
  final _addressController = TextEditingController();
  final _itemsController = TextEditingController();

  // Prestação de Contas
  bool _hasAccountability = false;
  final _totalCollectedController = TextEditingController();
  List<ExpenseItem> _expenses = [];

  @override
  void initState() {
    super.initState();
    if (widget.campaign != null) {
      _fillFields();
    }
  }

  void _fillFields() {
    final c = widget.campaign!;
    _titleController.text = c.title;
    _descController.text = c.description;
    _selectedType = c.type;
    _goalController.text = c.goalValue?.toString() ?? '';
    _ticketValueController.text = c.ticketValue?.toString() ?? '';
    _prizeController.text = c.prize ?? '';
    _addressController.text = c.address ?? '';
    _itemsController.text = c.itemsForSale ?? '';
    _hasAccountability = c.hasAccountability;
    _totalCollectedController.text = c.totalCollected?.toString() ?? '';
    _expenses = List.from(c.expenses ?? []);
  }

  // Seleção de Imagens
  Future<void> _pickMainImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _mainImage = File(picked.path));
  }

  Future<void> _pickReceipts() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _receiptFiles.addAll(picked.map((e) => File(e.path))));
    }
  }

  // Gestão de Despesas
  void _addExpense() {
    setState(() => _expenses.add(ExpenseItem(description: '', value: 0.0)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newCampaign = CampaignModel(
        title: _titleController.text,
        description: _descController.text,
        type: _selectedType,
        status: CampaignStatus.ativa,
        goalValue: double.tryParse(_goalController.text),
        ticketValue: double.tryParse(_ticketValueController.text),
        prize: _prizeController.text,
        address: _addressController.text,
        itemsForSale: _itemsController.text,
        hasAccountability: _hasAccountability,
        totalCollected: double.tryParse(_totalCollectedController.text),
        expenses: _expenses,
        currentValue: 0, // Inicia zerado
      );

      await _service.saveCampaign(newCampaign, _mainImage, _receiptFiles);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Campanha')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTypeSelector(),
                const SizedBox(height: 20),
                _buildImagePicker(),
                const SizedBox(height: 20),
                TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título')),
                const SizedBox(height: 10),
                TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Descrição'), maxLines: 2),
                
                const SizedBox(height: 20),
                if (_selectedType == CampaignType.rifa) _buildRifaFields(),
                if (_selectedType == CampaignType.bazar) _buildBazarFields(),
                
                const SizedBox(height: 20),
                _buildAccountabilitySection(),
                
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text('SALVAR CAMPANHA'),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTypeSelector() {
    return SegmentedButton<CampaignType>(
      segments: const [
        ButtonSegment(value: CampaignType.rifa, label: Text('Rifa'), icon: Icon(Icons.confirmation_num)),
        ButtonSegment(value: CampaignType.bazar, label: Text('Bazar'), icon: Icon(Icons.store)),
        ButtonSegment(value: CampaignType.outro, label: Text('Outro'), icon: Icon(Icons.more_horiz)),
      ],
      selected: {_selectedType},
      onSelectionChanged: (set) => setState(() => _selectedType = set.first),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickMainImage,
      child: Container(
        height: 150,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
        child: _mainImage == null 
          ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40), Text('Foto da Campanha')])
          : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_mainImage!, fit: BoxFit.cover)),
      ),
    );
  }

  Widget _buildRifaFields() {
    return Column(children: [
      TextFormField(controller: _prizeController, decoration: const InputDecoration(labelText: 'Prêmio')),
      Row(children: [
        Expanded(child: TextFormField(controller: _goalController, decoration: const InputDecoration(labelText: 'Meta (R\$)'), keyboardType: TextInputType.number)),
        const SizedBox(width: 10),
        Expanded(child: TextFormField(controller: _ticketValueController, decoration: const InputDecoration(labelText: 'Valor do Nº'), keyboardType: TextInputType.number)),
      ]),
    ]);
  }

  Widget _buildBazarFields() {
    return Column(children: [
      TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Endereço')),
      TextFormField(controller: _itemsController, decoration: const InputDecoration(labelText: 'Itens à venda')),
    ]);
  }

  Widget _buildAccountabilitySection() {
    return Column(children: [
      CheckboxListTile(
        title: const Text('Prestação de Contas'),
        value: _hasAccountability,
        onChanged: (v) => setState(() => _hasAccountability = v!),
      ),
      if (_hasAccountability) ...[
        TextFormField(controller: _totalCollectedController, decoration: const InputDecoration(labelText: 'Total Arrecadado'), keyboardType: TextInputType.number),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Despesas/Notas', style: TextStyle(fontWeight: FontWeight.bold)),
          IconButton(onPressed: _addExpense, icon: const Icon(Icons.add_circle)),
        ]),
        ...List.generate(_expenses.length, (index) => Row(children: [
          Expanded(child: TextFormField(
            decoration: const InputDecoration(hintText: 'Descrição'),
            onChanged: (v) => _expenses[index] = ExpenseItem(description: v, value: _expenses[index].value),
          )),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: TextFormField(
            decoration: const InputDecoration(hintText: 'R\$'),
            keyboardType: TextInputType.number,
            onChanged: (v) => _expenses[index] = ExpenseItem(description: _expenses[index].description, value: double.tryParse(v) ?? 0),
          )),
        ])),
        const SizedBox(height: 10),
        TextButton.icon(onPressed: _pickReceipts, icon: const Icon(Icons.receipt_long), label: Text('${_receiptFiles.length} Comprovantes Selecionados')),
      ]
    ]);
  }
}