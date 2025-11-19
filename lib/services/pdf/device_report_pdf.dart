import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DeviceReportPDF {
  static Future<Uint8List> generate({
    required String status,
    required List<Map<String, dynamic>> devices,
  }) async {
    // --- Load font tiếng Việt từ assets ---
    final fontData = await rootBundle.load(
      'lib/fonts/Roboto-Italic-VariableFont_wdth,wght.ttf',
    );
    final ttf = pw.Font.ttf(fontData);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            "BÁO CÁO THIẾT BỊ",
            style: pw.TextStyle(
              font: ttf,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Text(
            "Trạng thái lọc: $status",
            style: pw.TextStyle(
              font: ttf,
              fontSize: 14,
            ),
          ),

          pw.SizedBox(height: 20),

          _buildTable(devices, ttf),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  /// Build table
  static pw.Widget _buildTable(
      List<Map<String, dynamic>> devices, pw.Font font) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _cell("Tên thiết bị", font, bold: true),
            _cell("Model", font, bold: true),
            _cell("Trạng thái", font, bold: true),
          ],
        ),

        // Data rows
        ...devices.map((d) {
          return pw.TableRow(
            children: [
              _cell(d["name"] ?? "", font),
              _cell(d["model"] ?? "", font),
              _cell(d["status"] ?? "", font),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Cell widget
  static pw.Widget _cell(String text, pw.Font font, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 12,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
