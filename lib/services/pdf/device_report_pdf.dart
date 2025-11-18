import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DeviceReportPDF {
  static Future<Uint8List> generate({
    required String status,
    required List<Map<String, dynamic>> devices,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            "BÁO CÁO THIẾT BỊ",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 8),

          pw.Text("Trạng thái lọc: $status", style: pw.TextStyle(fontSize: 14)),

          pw.SizedBox(height: 20),

          _buildTable(devices),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTable(List<Map<String, dynamic>> devices) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _cell("Tên thiết bị", bold: true),
            _cell("Model", bold: true),
            _cell("Trạng thái", bold: true),
          ],
        ),

        ...devices.map((d) {
          return pw.TableRow(
            children: [_cell(d["name"]), _cell(d["model"]), _cell(d["status"])],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
