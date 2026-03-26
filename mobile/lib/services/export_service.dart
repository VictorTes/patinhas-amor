import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:patinhas_amor/models/animal.dart';
import 'package:patinhas_amor/models/occurrence.dart';

class ExportService {
  final _dateFormat = DateFormat('dd/MM/yyyy');

  /// Verifica saúde via texto da descrição
  String _checkHealthStatus(String description, String keyword) {
    if (description.toLowerCase().contains(keyword.toLowerCase())) {
      return 'Sim';
    }
    return 'Não';
  }

  // ==========================================
  // GERAÇÃO DE EXCEL (GENÉRICA PARA ANIMAIS)
  // ==========================================
  Future<void> generateAnimalsExcel({
    required List<Animal> animals,
    required String fileName,
    DateTime? start,
    DateTime? end,
  }) async {
    // Aplica filtro de data se fornecido
    List<Animal> data = _filterAnimalsByDate(animals, start, end);

    var excel = Excel.createExcel();
    Sheet sheetObject = excel[excel.getDefaultSheet()!];

    CellStyle headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Arial),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#FF9800'),
    );

    List<CellValue> headers = [
      TextCellValue('Nome'),
      TextCellValue('Espécie'),
      TextCellValue('Sexo'),
      TextCellValue('Porte'),
      TextCellValue('Status'),
      TextCellValue('Localização'),
      TextCellValue('Data Resgate'),
      TextCellValue('Vacinado?'),
      TextCellValue('Castrado?'),
      TextCellValue('Adotante'),
    ];

    sheetObject.appendRow(headers);

    for (int i = 0; i < headers.length; i++) {
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    for (var a in data) {
      sheetObject.appendRow([
        TextCellValue(a.name),
        TextCellValue(a.species),
        TextCellValue(a.sex ?? 'N/A'),
        TextCellValue(a.size ?? 'N/A'),
        TextCellValue(a.status.label),
        TextCellValue(a.currentLocation ?? 'ONG'),
        TextCellValue(a.rescueDate != null ? _dateFormat.format(a.rescueDate!) : 'S/D'),
        TextCellValue(_checkHealthStatus(a.description, 'vacinado')),
        TextCellValue(_checkHealthStatus(a.description, 'castrado')),
        TextCellValue(a.adopterName ?? '-'),
      ]);
    }

    for (int i = 0; i < headers.length; i++) {
      sheetObject.setColumnAutoFit(i);
    }

    final bytes = excel.save();
    if (bytes != null) await _saveAndShare(bytes, '$fileName.xlsx');
  }

  // ==========================================
  // GERAÇÃO DE PDF (GENÉRICA PARA ANIMAIS)
  // ==========================================
  Future<void> generateAnimalsPdf({
    required List<Animal> animals,
    required String title,
    required String fileName,
    DateTime? start,
    DateTime? end,
  }) async {
    List<Animal> data = _filterAnimalsByDate(animals, start, end);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          _buildPdfHeader(title, start, end),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
            headers: ['Nome', 'Especie', 'Sexo', 'Status', 'Data Resgate', 'Adotante'],
            data: data.map((a) => [
              a.name,
              a.species,
              a.sex ?? '-',
              a.status.label,
              a.rescueDate != null ? _dateFormat.format(a.rescueDate!) : '-',
              a.adopterName ?? '-',
            ]).toList(),
          ),
        ],
      ),
    );

    await _saveAndShare(await pdf.save(), '$fileName.pdf');
  }

  // ==========================================
  // GERAÇÃO DE EXCEL/PDF PARA OCORRÊNCIAS
  // ==========================================
  Future<void> generateOccurrencesReport({
    required List<Occurrence> occurrences,
    required String title,
    required String fileName,
    required bool isPdf,
    DateTime? start,
    DateTime? end,
  }) async {
    List<Occurrence> data = _filterOccurrencesByDate(occurrences, start, end);

    if (isPdf) {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          _buildPdfHeader(title, start, end),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
            headers: ['Tipo', 'Localizacao', 'Status', 'Data', 'Resolucao'],
            data: data.map((o) => [
              o.type, o.location, o.status.label,
              o.createdAt != null ? _dateFormat.format(o.createdAt!) : '-',
              o.resolutionDescription ?? 'Pendente',
            ]).toList(),
          ),
        ],
      ));
      await _saveAndShare(await pdf.save(), '$fileName.pdf');
    } else {
      var excel = Excel.createExcel();
      Sheet sheet = excel[excel.getDefaultSheet()!];
      sheet.appendRow([TextCellValue('Tipo'), TextCellValue('Localizacao'), TextCellValue('Status'), TextCellValue('Data'), TextCellValue('Resolucao')]);
      for (var o in data) {
        sheet.appendRow([
          TextCellValue(o.type), TextCellValue(o.location), TextCellValue(o.status.label),
          TextCellValue(o.createdAt != null ? _dateFormat.format(o.createdAt!) : '-'),
          TextCellValue(o.resolutionDescription ?? '-'),
        ]);
      }
      final bytes = excel.save();
      if (bytes != null) await _saveAndShare(bytes, '$fileName.xlsx');
    }
  }

  // ==========================================
  // MÉTODOS PRIVADOS DE SUPORTE
  // ==========================================

  List<Animal> _filterAnimalsByDate(List<Animal> list, DateTime? s, DateTime? e) {
    if (s == null || e == null) return list;
    return list.where((a) {
      if (a.rescueDate == null) return false;
      return a.rescueDate!.isAfter(s.subtract(const Duration(days: 1))) && 
             a.rescueDate!.isBefore(e.add(const Duration(days: 1)));
    }).toList();
  }

  List<Occurrence> _filterOccurrencesByDate(List<Occurrence> list, DateTime? s, DateTime? e) {
    if (s == null || e == null) return list;
    return list.where((o) {
      if (o.createdAt == null) return false;
      return o.createdAt!.isAfter(s.subtract(const Duration(days: 1))) && 
             o.createdAt!.isBefore(e.add(const Duration(days: 1)));
    }).toList();
  }

  pw.Widget _buildPdfHeader(String title, DateTime? s, DateTime? e) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        if (s != null && e != null)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Text("Periodo: ${_dateFormat.format(s)} - ${_dateFormat.format(e)}"),
          ),
        pw.SizedBox(height: 15),
      ]
    );
  }

  Future<void> _saveAndShare(List<int> bytes, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Relatorio Patinhas e Amor');
  }
}