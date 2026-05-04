import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patinhas_amor/models/animal.dart';
import 'package:patinhas_amor/models/occurrence.dart';
import 'package:patinhas_amor/models/campaign.dart';
import 'package:patinhas_amor/services/animal_service.dart';
import 'package:patinhas_amor/services/occurrence_service.dart';
import 'package:patinhas_amor/services/campaign_service.dart';
import 'package:patinhas_amor/services/export_service.dart';
import 'package:patinhas_amor/widgets/loading_indicator.dart';
import 'package:patinhas_amor/widgets/role_guard.dart'; // Import do seu Guard

// ============================================================================
// 1. DICIONÁRIO DE DADOS (SCHEMA)
// ============================================================================
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
        if (!_selectedFields[table]!.contains(fieldKey)) {
          _selectedFields[table]!.add(fieldKey);
        }
      } else {
        _selectedFields[table]!.remove(fieldKey);
      }
    });
  }

  void _toggleSelectAll(String tableName, bool shouldSelectAll) {
    setState(() {
      if (shouldSelectAll) {
        _selectedFields[tableName] = reportSchema[tableName]!.keys.toList();
      } else {
        _selectedFields[tableName] = [];
      }
    });
  }

  void _generatePreview() {
    bool hasSelection =
        _selectedFields.values.any((fields) => fields.isNotEmpty);
    if (!hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecione ao menos um campo de uma tabela.'),
            backgroundColor: Colors.red),
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
    return RoleGuard(
      requiredRole: 'admin',
      fallback: Scaffold(
        appBar: AppBar(
            title: const Text("Exportação"), backgroundColor: Colors.grey),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 70, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Acesso Restrito",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Text(
                  "Apenas administradores podem gerar relatórios e exportar dados do sistema.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("VOLTAR"),
              ),
            ],
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exportação de Dados'),
          backgroundColor: Colors.orange,
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
            _selectedDateRange == null
                ? "Filtrar por Período (Opcional)"
                : "Período Selecionado",
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
    final bool isAllSelected = selectedCount == fields.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: selectedCount > 0 ? Colors.orange : Colors.grey.shade300),
      ),
      child: ExpansionTile(
        title: Text(
          tableName,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selectedCount > 0 ? Colors.orange.shade900 : null),
        ),
        subtitle: Text('$selectedCount colunas selecionadas'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _toggleSelectAll(tableName, !isAllSelected),
                icon: Icon(
                  isAllSelected ? Icons.deselect : Icons.select_all,
                  size: 20,
                  color: Colors.orange.shade800,
                ),
                label: Text(
                  isAllSelected ? "Limpar Seleção" : "Selecionar Todas",
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          ...fields.entries.map((entry) {
            final isChecked = _selectedFields[tableName]!.contains(entry.key);
            return CheckboxListTile(
              title: Text(entry.value, style: const TextStyle(fontSize: 14)),
              value: isChecked,
              activeColor: Colors.orange,
              dense: true,
              onChanged: (bool? val) =>
                  _toggleField(tableName, entry.key, val ?? false),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _generatePreview,
          icon: const Icon(Icons.visibility),
          label: const Text('Gerar Pré-visualização',
              style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  const ReportPreviewScreen(
      {super.key, required this.selectedFields, this.dateRange});

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  final AnimalService _animalService = AnimalService();
  final OccurrenceService _occurrenceService = OccurrenceService();
  final ExportService _exportService = ExportService();
  final CampaignService _campaignService = CampaignService();

  bool _isLoading = true;
  bool _isExporting = false;

  final Map<String, List<Map<String, dynamic>>> _processedData = {};

  @override
  void initState() {
    super.initState();
    _fetchAndTransformData();
  }

  Future<void> _fetchAndTransformData() async {
    setState(() => _isLoading = true);
    try {
      if (widget.selectedFields['Animais']!.isNotEmpty) {
        List<Animal> rawAnimals = await _animalService.fetchAnimals();
        _processedData['Animais'] = _transformData(
            rawAnimals, widget.selectedFields['Animais']!, 'rescueDate');
      }

      if (widget.selectedFields['Ocorrências']!.isNotEmpty) {
        List<Occurrence> rawOccurrences =
            await _occurrenceService.fetchOccurrences();
        _processedData['Ocorrências'] = _transformData(
            rawOccurrences, widget.selectedFields['Ocorrências']!, 'createdAt');
      }

      if (widget.selectedFields['Campanhas']!.isNotEmpty) {
        List<CampaignModel> rawCampaigns =
            await _campaignService.fetchCampaigns();
        _processedData['Campanhas'] = _transformData(
            rawCampaigns, widget.selectedFields['Campanhas']!, 'createdAt');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao buscar dados: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _transformData(
      List<dynamic> rawData, List<String> fields, String dateKey) {
    List<Map<String, dynamic>> result = [];

    for (var item in rawData) {
      Map<String, dynamic> itemMap = item.toMap();

      if (widget.dateRange != null && itemMap[dateKey] != null) {
        DateTime itemDate;
        if (itemMap[dateKey] is Timestamp) {
          itemDate = (itemMap[dateKey] as Timestamp).toDate();
        } else {
          itemDate = (itemMap[dateKey] as DateTime);
        }

        if (itemDate.isBefore(widget.dateRange!.start) ||
            itemDate
                .isAfter(widget.dateRange!.end.add(const Duration(days: 1)))) {
          continue;
        }
      }

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
      final Map<String, Map<String, String>> currentSchema = {
        'Animais': reportSchema['Animais']!,
        'Campanhas': reportSchema['Campanhas']!,
        'Ocorrências': reportSchema['Ocorrências']!,
      };

      if (isPdf) {
        await _exportService.generateDynamicPdf(
            processedData: _processedData,
            selectedFields: widget.selectedFields,
            schema: currentSchema,
            dateRange: widget.dateRange);
      } else {
        await _exportService.generateDynamicExcel(
            processedData: _processedData,
            selectedFields: widget.selectedFields,
            schema: currentSchema);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
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
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _processedData.keys.map((tableName) {
                    return _buildDataTablePreview(
                        tableName, _processedData[tableName]!);
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
                onPressed:
                    _isLoading || _isExporting ? null : () => _export(false),
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
                onPressed:
                    _isLoading || _isExporting ? null : () => _export(true),
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

  Widget _buildDataTablePreview(
      String tableName, List<Map<String, dynamic>> data) {
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              '$tableName (${data.length} registros encontrados)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
              columns: fields.map((fieldKey) {
                String headerLabel =
                    reportSchema[tableName]![fieldKey] ?? fieldKey;
                return DataColumn(
                    label: Text(headerLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold)));
              }).toList(),
              rows: data.take(10).map((row) {
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
