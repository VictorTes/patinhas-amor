import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart'; // Import necessário para o DateTimeRange
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ExportService {
  // ==========================================
  // GERAÇÃO DE EXCEL (DINÂMICO)
  // ==========================================
  Future<void> generateDynamicExcel({
    required Map<String, List<Map<String, dynamic>>> processedData,
    required Map<String, List<String>> selectedFields,
    required Map<String, Map<String, String>> schema,
  }) async {
    var excel = Excel.createExcel();
    
    String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    bool isFirstSheet = true;

    CellStyle headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Arial),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#FF9800'),
    );

    for (String tableName in processedData.keys) {
      List<Map<String, dynamic>> data = processedData[tableName]!;
      List<String> fields = selectedFields[tableName]!;
      
      if (data.isEmpty || fields.isEmpty) continue;

      String sheetName = tableName.replaceAll(RegExp(r'[^\w\s]+'), ''); 
      if (isFirstSheet) {
        excel.rename(defaultSheet, sheetName);
        isFirstSheet = false;
      }
      
      Sheet sheetObject = excel[sheetName];

      List<CellValue> headers = fields.map((field) {
        String headerLabel = schema[tableName]![field] ?? field;
        return TextCellValue(headerLabel);
      }).toList();
      
      sheetObject.appendRow(headers);

      for (int i = 0; i < headers.length; i++) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
      }

      for (var row in data) {
        List<CellValue> rowValues = fields.map((field) {
          return TextCellValue(row[field]?.toString() ?? '-');
        }).toList();
        sheetObject.appendRow(rowValues);
      }

      for (int i = 0; i < headers.length; i++) {
        sheetObject.setColumnAutoFit(i);
      }
    }

    final bytes = excel.save();
    if (bytes != null) {
      String fileName = 'Relatorio_Exportacao_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      await _saveAndShare(bytes, fileName);
    }
  }

  // ==========================================
  // GERAÇÃO DE PDF (DINÂMICO)
  // ==========================================
  Future<void> generateDynamicPdf({
    required Map<String, List<Map<String, dynamic>>> processedData,
    required Map<String, List<String>> selectedFields,
    required Map<String, Map<String, String>> schema,
    DateTimeRange? dateRange,
  }) async {
    final pdf = pw.Document();

    for (String tableName in processedData.keys) {
      List<Map<String, dynamic>> data = processedData[tableName]!;
      List<String> fields = selectedFields[tableName]!;
      
      if (data.isEmpty || fields.isEmpty) continue;

      List<String> headers = fields.map((field) => schema[tableName]![field] ?? field).toList();

      List<List<String>> tableData = data.map((row) {
        return fields.map((field) => row[field]?.toString() ?? '-').toList();
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape, 
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            _buildPdfHeader(
              "Relatório: $tableName", 
              dateRange?.start, 
              dateRange?.end
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              headers: headers,
              data: tableData,
            ),
          ],
        ),
      );
    }

    String fileName = 'Relatorio_Exportacao_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    await _saveAndShare(await pdf.save(), fileName);
  }

  pw.Widget _buildPdfHeader(String title, DateTime? s, DateTime? e) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (s != null && e != null)
            pw.Text(
              "Período: ${DateFormat('dd/MM/yyyy').format(s)} - ${DateFormat('dd/MM/yyyy').format(e)}", 
              style: const pw.TextStyle(fontSize: 10),
            ),
        ],
      ),
    );
  }

  Future<void> _saveAndShare(List<int> bytes, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Exportação de Dados - Patinhas de Amor');
  }
}