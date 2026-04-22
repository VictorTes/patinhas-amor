import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // Controllers Gerais
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  CampaignType _selectedType = CampaignType.rifa;
  CampaignStatus _selectedStatus = CampaignStatus.ativa; // Novo: Status
  
  // Imagens
  File? _mainImage;
  File? _prizeImage; // Novo: Arquivo da imagem do prêmio
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
    _selectedStatus = c.status; // Carrega status atual
    _goalController.text = c.goalValue?.toString() ?? '';
    _ticketValueController.text = c.ticketValue?.toString() ?? '';
    _prizeController.text = c.prize ?? '';
    _addressController.text = c.address ?? '';
    _itemsController.text = c.itemsForSale ?? '';
    _hasAccountability = c.hasAccountability;
    _totalCollectedController.text = c.totalCollected?.toString() ?? '';
    _expenses = List.from(c.expenses ?? []);
  }

  Future<void> _pickMainImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _mainImage = File(picked.path));
  }

  // Novo: Método para escolher imagem do prêmio
  Future<void> _pickPrizeImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _prizeImage = File(picked.path));
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedCampaign = CampaignModel(
        id: widget.campaign?.id,
        title: _titleController.text,
        description: _descController.text,
        type: _selectedType,
        status: _selectedStatus, // Envia o status selecionado
        goalValue: double.tryParse(_goalController.text),
        ticketValue: double.tryParse(_ticketValueController.text),
        prize: _prizeController.text,
        address: _addressController.text,
        itemsForSale: _itemsController.text,
        hasAccountability: _hasAccountability,
        totalCollected: double.tryParse(_totalCollectedController.text),
        expenses: _expenses,
        currentValue: widget.campaign?.currentValue ?? 0,
        imageUrl: widget.campaign?.imageUrl, 
        prizeImageUrl: widget.campaign?.prizeImageUrl, // Preserva URL antiga se não mudar
        receiptUrls: widget.campaign?.receiptUrls,
      );

      // Chama o serviço passando a nova prizeImage se existir
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
                _buildStatusSelector(), // Novo: Seletor de Status
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

  // Novo: Seletor de Status da Campanha
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

  Widget _buildRifaFields() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Informações da Rifa', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      TextFormField(controller: _prizeController, decoration: const InputDecoration(labelText: 'Nome do Prêmio', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      
      // Novo: Picker para foto do prêmio
      GestureDetector(
        onTap: _pickPrizeImage,
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200)
          ),
          child: _prizeImage != null 
            ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_prizeImage!, fit: BoxFit.cover))
            : widget.campaign?.prizeImageUrl != null
              ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(widget.campaign!.prizeImageUrl!, fit: BoxFit.cover))
              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.card_giftcard, color: Colors.orange), SizedBox(width: 10), Text('Adicionar Foto do Prêmio')]),
        ),
      ),
      
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextFormField(controller: _goalController, decoration: const InputDecoration(labelText: 'Meta (R\$)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
        const SizedBox(width: 10),
        Expanded(child: TextFormField(controller: _ticketValueController, decoration: const InputDecoration(labelText: 'Valor do Nº', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
      ]),
    ]);
  }

  Widget _buildBazarFields() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Informações do Bazar', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Endereço Completo', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextFormField(controller: _itemsController, decoration: const InputDecoration(labelText: 'Principais itens à venda', border: OutlineInputBorder()), maxLines: 2),
    ]);
  }

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
          TextFormField(controller: _totalCollectedController, decoration: const InputDecoration(labelText: 'Total Arrecadado (R\$)'), keyboardType: TextInputType.number),
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
                keyboardType: TextInputType.number,
                onChanged: (v) => _expenses[index] = ExpenseItem(description: _expenses[index].description, value: double.tryParse(v) ?? 0),
              )),
              IconButton(onPressed: () => setState(() => _expenses.removeAt(index)), icon: const Icon(Icons.delete, color: Colors.red)),
            ]),
          )),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _pickReceipts, 
            icon: const Icon(Icons.receipt_long), 
            label: Text(_receiptFiles.isNotEmpty ? '${_receiptFiles.length} Novos Comprovantes' : 'Anexar Notas Fiscais'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black87),
          ),
          if (isEditing && (widget.campaign?.receiptUrls?.isNotEmpty ?? false))
             Padding(
               padding: const EdgeInsets.only(top: 8),
               child: Text('${widget.campaign!.receiptUrls!.length} notas já salvas no sistema', style: const TextStyle(fontSize: 12, color: Colors.blue)),
             )
        ]
      ]),
    );
  }

  bool get isEditing => widget.campaign != null;
}