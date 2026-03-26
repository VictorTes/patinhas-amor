import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patinhas_amor/models/animal.dart';
import 'package:patinhas_amor/models/occurrence.dart';
import 'package:patinhas_amor/services/animal_service.dart';
import 'package:patinhas_amor/services/occurrence_service.dart'; 
import 'package:patinhas_amor/services/export_service.dart';
import 'package:patinhas_amor/widgets/loading_indicator.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  final ExportService _exportService = ExportService();
  final AnimalService _animalService = AnimalService();
  final OccurrenceService _occurrenceService = OccurrenceService();

  late TabController _tabController;
  DateTimeRange? _selectedDateRange;
  bool _isExporting = false;
  final DateFormat _df = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  // --- LÓGICA DE EXPORTAÇÃO DE ANIMAIS (CORRIGIDA) ---
  Future<void> _exportAnimals({required String type, required bool isPdf}) async {
    setState(() => _isExporting = true);
    try {
      List<Animal> animals = await _animalService.fetchAnimals();
      
      // Filtros corrigidos: Comparando DIRETAMENTE com o Enum!
      if (type == 'na_ong') {
        // Na ONG = Não está adotado e não está desaparecido
        animals = animals.where((a) => 
          a.status != AnimalStatus.adopted && 
          a.status != AnimalStatus.missing
        ).toList();
      } else if (type == 'adotados') {
        animals = animals.where((a) => a.status == AnimalStatus.adopted).toList();
      } else if (type == 'desaparecidos') {
        animals = animals.where((a) => a.status == AnimalStatus.missing).toList();
      } else if (type == 'disponiveis') {
        animals = animals.where((a) => a.status == AnimalStatus.availableForAdoption).toList();
      }

      final String title = "Relatório de Animais - ${type.replaceAll('_', ' ').toUpperCase()}";
      final String fileName = "relatorio_animais_$type";

      if (isPdf) {
        await _exportService.generateAnimalsPdf(
          animals: animals, 
          title: title, 
          fileName: fileName, 
          start: _selectedDateRange?.start, 
          end: _selectedDateRange?.end
        );
      } else {
        await _exportService.generateAnimalsExcel(
          animals: animals, 
          fileName: fileName,
          start: _selectedDateRange?.start, 
          end: _selectedDateRange?.end
        );
      }
    } catch (e) {
      _showError("Erro ao exportar animais: $e");
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // --- LÓGICA DE EXPORTAÇÃO DE OCORRÊNCIAS (AJUSTADA) ---
  Future<void> _exportOccurrences({required bool concluded, required bool isPdf}) async {
    setState(() => _isExporting = true);
    try {
      List<Occurrence> data = await _occurrenceService.fetchOccurrences();
      
      if (concluded) {
        // Considerando que o Enum ou a propriedade de string se chame 'resolved'
        data = data.where((o) => o.status.name == 'resolved').toList();
      } else {
        // Considerando 'pending' e 'inProgress' (camelCase, que é o padrão do Dart para enums)
        data = data.where((o) => 
          o.status.name == 'pending' || 
          o.status.name == 'inProgress' ||
          o.status.name == 'in_progress' // Garantia caso esteja usando uma string bruta
        ).toList();
      }

      final String title = concluded ? "Ocorrências Concluídas" : "Ocorrências em Aberto";
      final String fileName = concluded ? "ocorrencias_concluidas" : "ocorrencias_ativas";

      await _exportService.generateOccurrencesReport(
        occurrences: data,
        title: title,
        fileName: fileName,
        isPdf: isPdf,
        start: _selectedDateRange?.start,
        end: _selectedDateRange?.end,
      );
    } catch (e) {
      _showError("Erro ao exportar ocorrências: $e");
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios Oficiais'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Animais", icon: Icon(Icons.pets)),
            Tab(text: "Ocorrências", icon: Icon(Icons.warning_amber_rounded)),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildDateSelector(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAnimalsTab(),
                    _buildOccurrencesTab(),
                  ],
                ),
              ),
            ],
          ),
          if (_isExporting) 
            Container(
              color: Colors.black26,
              child: const LoadingIndicator(message: "Gerando arquivo e preparando compartilhamento..."),
            ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: ListTile(
          leading: const Icon(Icons.calendar_month, color: Colors.orange),
          title: Text(
            _selectedDateRange == null ? "Filtrar por Período" : "Período Ativo",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            _selectedDateRange == null 
                ? "Todos os registros (sem filtro)" 
                : "${_df.format(_selectedDateRange!.start)} até ${_df.format(_selectedDateRange!.end)}",
          ),
          trailing: _selectedDateRange != null 
              ? IconButton(
                  icon: const Icon(Icons.highlight_off, color: Colors.red), 
                  onPressed: () => setState(() => _selectedDateRange = null))
              : const Icon(Icons.chevron_right),
          onTap: _selectDateRange,
        ),
      ),
    );
  }

  Widget _buildAnimalsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReportSection("Todos os Animais na ONG", "na_ong"),
        _buildReportSection("Animais Adotados", "adotados"),
        _buildReportSection("Animais Desaparecidos", "desaparecidos"),
        _buildReportSection("Animais Disponíveis", "disponiveis"),
      ],
    );
  }

  Widget _buildOccurrencesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOccurrenceSection("Ocorrências em Andamento / Pendentes", false),
        _buildOccurrenceSection("Ocorrências Finalizadas", true),
      ],
    );
  }

  Widget _buildReportSection(String label, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildActionBtn("Excel", Icons.table_view, Colors.green, () => _exportAnimals(type: type, isPdf: false))),
                const SizedBox(width: 12),
                Expanded(child: _buildActionBtn("PDF", Icons.picture_as_pdf, Colors.red, () => _exportAnimals(type: type, isPdf: true))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccurrenceSection(String label, bool concluded) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildActionBtn("Excel", Icons.table_view, Colors.green, () => _exportOccurrences(concluded: concluded, isPdf: false))),
                const SizedBox(width: 12),
                Expanded(child: _buildActionBtn("PDF", Icons.picture_as_pdf, Colors.red, () => _exportOccurrences(concluded: concluded, isPdf: true))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: _isExporting ? null : onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}