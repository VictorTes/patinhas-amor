import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; 
import '../models/campaign.dart';
import '../services/campaign_service.dart';

class CampaignFormScreen extends StatefulWidget {
  final CampaignModel? campaign;

  const CampaignFormScreen({super.key, this.campaign});

  @override
  State<CampaignFormScreen> createState() => _CampaignFormScreenState();
}

class _CampaignFormScreenState extends State<CampaignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CampaignService();
  final _picker = ImagePicker();

  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  CampaignType _selectedType = CampaignType.rifa;
  CampaignStatus _selectedStatus = CampaignStatus.ativa;
  
  File? _mainImage;
  File? _prizeImage;
  List<File> _receiptFiles = [];
  
  String? _prizeImageUrl;
  List<String> _existingReceiptUrls = [];

  final _goalController = TextEditingController();
  final _ticketValueController = TextEditingController();
  final _prizeController = TextEditingController();
  
  final _drawDateController = TextEditingController();
  DateTime? _selectedDrawDate;

  final _addressController = TextEditingController();
  final _itemsController = TextEditingController();

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

  @override
  void dispose() {
    // Limpeza dos controladores para evitar memory leak
    _titleController.dispose();
    _descController.dispose();
    _goalController.dispose();
    _ticketValueController.dispose();
    _prizeController.dispose();
    _drawDateController.dispose();
    _addressController.dispose();
    _itemsController.dispose();
    _totalCollectedController.dispose();
    super.dispose();
  }

  void _fillFields() {
    final c = widget.campaign!;
    _titleController.text = c.title;
    _descController.text = c.description;
    _selectedType = c.type;
    _selectedStatus = c.status;
    _goalController.text = c.goalValue?.toString() ?? '';
    _ticketValueController.text = c.ticketValue?.toString() ?? '';
    _prizeController.text = c.prize ?? '';
    _addressController.text = c.address ?? '';
    _itemsController.text = c.itemsForSale ?? '';
    _hasAccountability = c.hasAccountability;
    _totalCollectedController.text = c.totalCollected?.toString() ?? '';
    _expenses = List.from(c.expenses ?? []);
    _prizeImageUrl = c.prizeImageUrl;
    _existingReceiptUrls = List.from(c.receiptUrls ?? []);
    
    if (c.drawDate != null) {
      _selectedDrawDate = c.drawDate;
      _drawDateController.text = DateFormat('dd/MM/yyyy').format(c.drawDate!);
    }
  }

  Future<void> _selectDrawDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDrawDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('pt', 'BR'), // Agora funcionando com localizationsDelegates
    );

    if (picked != null && picked != _selectedDrawDate) {
      setState(() {
        _selectedDrawDate = picked;
        _drawDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Métodos de seleção de imagem permanecem iguais
  Future<void> _pickMainImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _mainImage = File(picked.path));
  }

  Future<void> _pickPrizeImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() {
      _prizeImage = File(picked.path);
      _prizeImageUrl = null;
    });
  }

  Future<void> _pickReceipts() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _receiptFiles.addAll(picked.map((e) => File(e.path))));
    }
  }

  void _addExpense() {
    setState(() => _expenses.add(ExpenseItem(description: '', value: 0.0)));
  }

  // Função auxiliar para converter texto em double de forma segura
  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    // Substitui vírgula por ponto antes de tentar converter
    return double.tryParse(value.replaceAll(',', '.'));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedCampaign = CampaignModel(
        id: widget.campaign?.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType,
        status: _selectedStatus,
        goalValue: _parseDouble(_goalController.text),
        ticketValue: _parseDouble(_ticketValueController.text),
        prize: _prizeController.text.trim(),
        drawDate: _selectedDrawDate,
        address: _addressController.text.trim(),
        itemsForSale: _itemsController.text.trim(),
        hasAccountability: _hasAccountability,
        totalCollected: _parseDouble(_totalCollectedController.text),
        expenses: _expenses,
        currentValue: widget.campaign?.currentValue ?? 0,
        imageUrl: widget.campaign?.imageUrl, 
        prizeImageUrl: _prizeImageUrl,
        receiptUrls: _existingReceiptUrls,
      );

      await _service.saveCampaign(
        updatedCampaign, 
        _mainImage, 
        _receiptFiles, 
        prizeImage: _prizeImage
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campanha salva com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Campanha' : 'Configurar Campanha'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Tipo e Status', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildTypeSelector(),
                const SizedBox(height: 10),
                _buildStatusSelector(),
                const SizedBox(height: 20),
                _buildImagePicker(),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController, 
                  decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descController, 
                  decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()), 
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                if (_selectedType == CampaignType.rifa) _buildRifaFields(),
                if (_selectedType == CampaignType.bazar) _buildBazarFields(),
                const SizedBox(height: 20),
                _buildAccountabilitySection(),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  child: Text(isEditing ? 'ATUALIZAR DADOS' : 'LANÇAR CAMPANHA'),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
    );
  }

  // Seletor de Tipo (Rifa ou Bazar)
  Widget _buildTypeSelector() {
    return SegmentedButton<CampaignType>(
      segments: const [
        ButtonSegment(value: CampaignType.rifa, label: Text('Rifa'), icon: Icon(Icons.confirmation_num)),
        ButtonSegment(value: CampaignType.bazar, label: Text('Bazar'), icon: Icon(Icons.store)),
      ],
      selected: {_selectedType},
      onSelectionChanged: (set) => setState(() => _selectedType = set.first),
    );
  }

  // Seletor de Status
  Widget _buildStatusSelector() {
    return SegmentedButton<CampaignStatus>(
      segments: const [
        ButtonSegment(value: CampaignStatus.ativa, label: Text('Ativa')),
        ButtonSegment(value: CampaignStatus.concluida, label: Text('Concluída')),
        ButtonSegment(value: CampaignStatus.cancelada, label: Text('Cancelada')),
      ],
      selected: {_selectedStatus},
      onSelectionChanged: (set) => setState(() => _selectedStatus = set.first),
    );
  }

  // Widget de seleção da imagem principal
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickMainImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[200], 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400)
        ),
        child: _mainImage != null 
          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_mainImage!, fit: BoxFit.cover))
          : widget.campaign?.imageUrl != null
            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(widget.campaign!.imageUrl!, fit: BoxFit.cover))
            : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40), Text('Foto da Campanha')]),
      ),
    );
  }

  // Campos específicos para RIFA
  Widget _buildRifaFields() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Informações da Rifa', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      TextFormField(controller: _prizeController, decoration: const InputDecoration(labelText: 'Nome do Prêmio', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      
      TextFormField(
        controller: _drawDateController,
        readOnly: true,
        onTap: _selectDrawDate,
        decoration: const InputDecoration(
          labelText: 'Data do Sorteio',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
          hintText: 'Selecione a data',
        ),
      ),
      const SizedBox(height: 10),
      
      Stack(
        children: [
          GestureDetector(
            onTap: _pickPrizeImage,
            child: Container(
              height: 120, width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200)
              ),
              child: _prizeImage != null 
                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_prizeImage!, fit: BoxFit.cover))
                : _prizeImageUrl != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(_prizeImageUrl!, fit: BoxFit.cover))
                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.card_giftcard, color: Colors.orange), SizedBox(width: 10), Text('Adicionar Foto do Prêmio')]),
            ),
          ),
          if (_prizeImage != null || _prizeImageUrl != null)
            Positioned(
              top: 5, right: 5,
              child: CircleAvatar(
                radius: 15, backgroundColor: Colors.red,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 15, color: Colors.white),
                  onPressed: () => setState(() { _prizeImage = null; _prizeImageUrl = null; }),
                ),
              ),
            )
        ],
      ),
      
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextFormField(controller: _goalController, decoration: const InputDecoration(labelText: 'Meta (R\$)', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
        const SizedBox(width: 10),
        Expanded(child: TextFormField(controller: _ticketValueController, decoration: const InputDecoration(labelText: 'Valor do Nº', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
      ]),
    ]);
  }

  // Campos específicos para BAZAR
  Widget _buildBazarFields() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Informações do Bazar', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Endereço Completo', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextFormField(controller: _itemsController, decoration: const InputDecoration(labelText: 'Principais itens à venda', border: OutlineInputBorder()), maxLines: 2),
    ]);
  }

  // Seção de Prestação de Contas
  Widget _buildAccountabilitySection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        CheckboxListTile(
          title: const Text('Habilitar Prestação de Contas', style: TextStyle(fontWeight: FontWeight.bold)),
          value: _hasAccountability,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _hasAccountability = v!),
        ),
        if (_hasAccountability) ...[
          const Divider(),
          TextFormField(
            controller: _totalCollectedController, 
            decoration: const InputDecoration(labelText: 'Total Arrecadado (R\$)'), 
            keyboardType: const TextInputType.numberWithOptions(decimal: true)
          ),
          const SizedBox(height: 15),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Despesas e Notas Fiscais', style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(onPressed: _addExpense, icon: const Icon(Icons.add_circle, color: Colors.green)),
          ]),
          ...List.generate(_expenses.length, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(children: [
              Expanded(child: TextFormField(
                initialValue: _expenses[index].description,
                decoration: const InputDecoration(hintText: 'Ex: Vacinas', border: OutlineInputBorder()),
                onChanged: (v) => _expenses[index] = ExpenseItem(description: v, value: _expenses[index].value),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 90, child: TextFormField(
                initialValue: _expenses[index].value > 0 ? _expenses[index].value.toString() : null,
                decoration: const InputDecoration(hintText: 'R\$', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => _expenses[index] = ExpenseItem(description: _expenses[index].description, value: _parseDouble(v) ?? 0),
              )),
              IconButton(onPressed: () => setState(() => _expenses.removeAt(index)), icon: const Icon(Icons.delete, color: Colors.red)),
            ]),
          )),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _pickReceipts, 
            icon: const Icon(Icons.receipt_long), 
            label: const Text('Anexar Novas Notas'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black87),
          ),
          
          if (_receiptFiles.isNotEmpty || _existingReceiptUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 70,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._receiptFiles.asMap().entries.map((e) => _buildThumb(File(e.value.path), () => setState(() => _receiptFiles.removeAt(e.key)))),
                    ..._existingReceiptUrls.asMap().entries.map((e) => _buildThumb(e.value, () => setState(() => _existingReceiptUrls.removeAt(e.key)))),
                  ],
                ),
              ),
            ),
        ]
      ]),
    );
  }

  // Miniaturas das imagens anexadas
  Widget _buildThumb(dynamic source, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: source is File 
              ? Image.file(source, width: 70, height: 70, fit: BoxFit.cover)
              : Image.network(source, width: 70, height: 70, fit: BoxFit.cover),
          ),
          Positioned(
            top: 0, right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  bool get isEditing => widget.campaign != null;
}