import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patinhas_amor/models/animal.dart';
import 'package:patinhas_amor/models/occurrence.dart';
// import 'package:patinhas_amor/models/campaign.dart'; // Descomente se tiver o model
import 'package:patinhas_amor/services/animal_service.dart';
import 'package:patinhas_amor/services/occurrence_service.dart';
// import 'package:patinhas_amor/services/campaign_service.dart'; // Descomente
import 'package:patinhas_amor/services/export_service.dart';
import 'package:patinhas_amor/widgets/loading_indicator.dart';

// ============================================================================
// 1. DICIONÁRIO DE DADOS (SCHEMA)
// ============================================================================
// Centraliza a configuração de todas as tabelas e campos disponíveis para exportação.
final Map<String, Map<String, String>> reportSchema = {
  'Animais': {
    'name': 'Nome',
    'species': 'Espécie',
    'sex': 'Sexo',
    'age': 'Idade (anos)',
    'size': 'Porte',
    'status': 'Status',
    'rescueDate': 'Data de Resgate',
    'currentLocation': 'Localização Atual',
    'description': 'Descrição',
    'adopterName': 'Nome do Adotante',
    'adopterPhone': 'Tel. do Adotante',
  },
  'Campanhas': {
    'title': 'Título',
    'type': 'Tipo',
    'status': 'Status',
    'goalValue': 'Meta (R\$)',
    'totalCollected': 'Arrecadado (R\$)',
    'ticketValue': 'Valor Bilhete (R\$)',
    'drawDate': 'Data do Sorteio',
    'winner': 'Ganhador',
    'createdAt': 'Data de Criação',
  },
  'Ocorrências': {
    'protocol': 'Protocolo',
    'type': 'Tipo',
    'status': 'Status App',
    'status_web': 'Status Web',
    'source': 'Origem',
    'location': 'Localização',
    'reporterName': 'Denunciante',
    'description': 'Descrição',
    'createdAt': 'Data de Abertura',
    'approvedAt': 'Data de Aprovação',
  },
};

// ============================================================================
// 2. TELA PRINCIPAL: CONSTRUTOR DO RELATÓRIO
// ============================================================================
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _selectedDateRange;
  final DateFormat _df = DateFormat('dd/MM/yyyy');
  
  // Estado das seleções: Map<NomeDaTabela, ListaDeCamposSelecionados>
  final Map<String, List<String>> _selectedFields = {
    'Animais': [],
    'Campanhas': [],
    'Ocorrências': [],
  };

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.orange,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  void _toggleField(String table, String fieldKey, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedFields[table]!.add(fieldKey);
      } else {
        _selectedFields[table]!.remove(fieldKey);
      }
    });
  }

  void _generatePreview() {
    // Validação: Pelo menos uma tabela deve ter campos selecionados
    bool hasSelection = _selectedFields.values.any((fields) => fields.isNotEmpty);
    if (!hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um campo de uma tabela.'), backgroundColor: Colors.red),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPreviewScreen(
          selectedFields: _selectedFields,
          dateRange: _selectedDateRange,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportação de Dados'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: reportSchema.keys.map((tableName) {
                return _buildTableCard(tableName);
              }).toList(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.calendar_month, color: Colors.orange),
          title: Text(
            _selectedDateRange == null ? "Filtrar por Período (Opcional)" : "Período Selecionado",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            _selectedDateRange == null 
                ? "Todo o histórico" 
                : "${_df.format(_selectedDateRange!.start)} até ${_df.format(_selectedDateRange!.end)}",
          ),
          trailing: _selectedDateRange != null 
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red), 
                  onPressed: () => setState(() => _selectedDateRange = null))
              : const Icon(Icons.chevron_right),
          onTap: _selectDateRange,
        ),
      ),
    );
  }

  Widget _buildTableCard(String tableName) {
    final fields = reportSchema[tableName]!;
    final selectedCount = _selectedFields[tableName]!.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selectedCount > 0 ? Colors.orange : Colors.grey.shade300),
      ),
      child: ExpansionTile(
        title: Text(
          tableName,
          style: TextStyle(fontWeight: FontWeight.bold, color: selectedCount > 0 ? Colors.orange.shade900 : null),
        ),
        subtitle: Text('$selectedCount colunas selecionadas'),
        children: fields.entries.map((entry) {
          final isChecked = _selectedFields[tableName]!.contains(entry.key);
          return CheckboxListTile(
            title: Text(entry.value, style: const TextStyle(fontSize: 14)),
            value: isChecked,
            activeColor: Colors.orange,
            dense: true,
            onChanged: (bool? val) => _toggleField(tableName, entry.key, val ?? false),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _generatePreview,
          icon: const Icon(Icons.visibility),
          label: const Text('Gerar Pré-visualização', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade800,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. TELA DE PRÉ-VISUALIZAÇÃO (PIPELINE DE DADOS)
// ============================================================================
class ReportPreviewScreen extends StatefulWidget {
  final Map<String, List<String>> selectedFields;
  final DateTimeRange? dateRange;

  const ReportPreviewScreen({super.key, required this.selectedFields, this.dateRange});

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  final AnimalService _animalService = AnimalService();
  final OccurrenceService _occurrenceService = OccurrenceService();
  final ExportService _exportService = ExportService();
  // final CampaignService _campaignService = CampaignService(); // Descomente

  bool _isLoading = true;
  bool _isExporting = false;

  // Estrutura processada: Map<NomeDaTabela, ListaDeRegistrosMapeados>
  final Map<String, List<Map<String, dynamic>>> _processedData = {};

  @override
  void initState() {
    super.initState();
    _fetchAndTransformData();
  }

  Future<void> _fetchAndTransformData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Extração: Busca os dados brutos de cada coleção solicitada
      if (widget.selectedFields['Animais']!.isNotEmpty) {
        List<Animal> rawAnimals = await _animalService.fetchAnimals(); // Considere adicionar filtro de data direto na query do Firebase se possível
        _processedData['Animais'] = _transformData(rawAnimals, widget.selectedFields['Animais']!, 'rescueDate');
      }

      if (widget.selectedFields['Ocorrências']!.isNotEmpty) {
        List<Occurrence> rawOccurrences = await _occurrenceService.fetchOccurrences();
        _processedData['Ocorrências'] = _transformData(rawOccurrences, widget.selectedFields['Ocorrências']!, 'createdAt');
      }

      /* Descomente quando integrar Campaigns
      if (widget.selectedFields['Campanhas']!.isNotEmpty) {
        List<Campaign> rawCampaigns = await _campaignService.fetchCampaigns();
        _processedData['Campanhas'] = _transformData(rawCampaigns, widget.selectedFields['Campanhas']!, 'createdAt');
      }
      */

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar dados: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Transformação: Filtra por data e extrai apenas as chaves selecionadas
  List<Map<String, dynamic>> _transformData(List<dynamic> rawData, List<String> fields, String dateKey) {
    List<Map<String, dynamic>> result = [];
    
    for (var item in rawData) {
      // Nota: Assume que seus Models possuem um método toMap() ou toJson(). 
      // Caso contrário, você precisará criar um para transformar a instância em um Map.
      Map<String, dynamic> itemMap = item.toMap(); 

      // Filtro de Data (em memória)
      if (widget.dateRange != null && itemMap[dateKey] != null) {
        DateTime itemDate = (itemMap[dateKey] as DateTime); // Ajuste caso seja Timestamp do Firebase
        if (itemDate.isBefore(widget.dateRange!.start) || itemDate.isAfter(widget.dateRange!.end.add(const Duration(days: 1)))) {
          continue; // Pula este registro se estiver fora do período
        }
      }

      // Projeção: Mantém apenas os campos selecionados
      Map<String, dynamic> filteredItem = {};
      for (String field in fields) {
        filteredItem[field] = itemMap[field]?.toString() ?? '-';
      }
      result.add(filteredItem);
    }
    return result;
  }

  Future<void> _export(bool isPdf) async {
    setState(() => _isExporting = true);
    try {
      // Aqui você chamará seu ExportService.
      // Dica: Seu ExportService precisará ser ajustado para receber dados dinâmicos:
      // Map<String, List<Map<String, dynamic>>> em vez de List<Animal> fixos.
      if (isPdf) {
         // await _exportService.generateDynamicPdf(_processedData, widget.selectedFields, reportSchema);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Gerado com sucesso!')));
      } else {
         // await _exportService.generateDynamicExcel(_processedData, widget.selectedFields, reportSchema);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel Gerado com sucesso!')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pré-visualização'),
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: _processedData.keys.map((tableName) {
                  return _buildDataTablePreview(tableName, _processedData[tableName]!);
                }).toList(),
              ),
          if (_isExporting)
            Container(
              color: Colors.black45,
              child: const LoadingIndicator(message: "Gerando arquivos..."),
            )
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading || _isExporting ? null : () => _export(false),
                icon: const Icon(Icons.table_view),
                label: const Text('Baixar Excel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading || _isExporting ? null : () => _export(true),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Baixar PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTablePreview(String tableName, List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final fields = widget.selectedFields[tableName]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              '$tableName (${data.length} registros encontrados)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
              columns: fields.map((fieldKey) {
                // Pega o nome legível do esquema para o cabeçalho da tabela
                String headerLabel = reportSchema[tableName]![fieldKey] ?? fieldKey;
                return DataColumn(label: Text(headerLabel, style: const TextStyle(fontWeight: FontWeight.bold)));
              }).toList(),
              rows: data.take(10).map((row) { // .take(10) limita a preview a 10 linhas para performance
                return DataRow(
                  cells: fields.map((fieldKey) {
                    return DataCell(Text(row[fieldKey]?.toString() ?? ''));
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          if (data.length > 10)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Mostrando 10 de ${data.length} resultados...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            )
        ],
      ),
    );
  }
}