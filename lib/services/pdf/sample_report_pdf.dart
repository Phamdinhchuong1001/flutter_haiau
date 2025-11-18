import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// SampleReportPDF.generate(samples)
/// - samples: List<Map<String,dynamic>> như bạn truyền từ Firestore
/// Trả về: Uint8List (dùng trực tiếp với Printing.layoutPdf)
class SampleReportPDF {
  static Future<Uint8List> generate(List<Map<String, dynamic>> samples) async {
    // Load font từ assets (đã khai báo trong pubspec.yaml)
    final fontData = await rootBundle.load(
      'lib/fonts/KFOmCnqEu92Fr1Mu4mxP.ttf',
    );
    final ttf = pw.Font.ttf(fontData);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            // Header
            pw.Text(
              'BÁO CÁO MẪU XÉT NGHIỆM',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),

            // Summary row (ví dụ tổng mẫu)
            pw.Text(
              'Tổng mẫu: ${samples.length}',
              style: pw.TextStyle(font: ttf),
            ),

            pw.SizedBox(height: 12),

            // Table header + rows
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _hdr('Mã mẫu', ttf),
                    _hdr('Khách hàng', ttf),
                    _hdr('Ngày nhận', ttf),
                    _hdr('Trạng thái', ttf),
                  ],
                ),
                // data rows
                ...samples.map((s) {
                  final sampleCode = (s['sampleCode'] ?? '').toString();
                  final customer = (s['customerName'] ?? '').toString();
                  final received = (s['receivedDate'] ?? '').toString();
                  final status = (s['status'] ?? '').toString();

                  return pw.TableRow(
                    children: [
                      _cell(sampleCode, ttf),
                      _cell(customer, ttf),
                      _cell(received, ttf),
                      _cell(status, ttf),
                    ],
                  );
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );

    final List<int> raw = await pdf.save();
    return Uint8List.fromList(raw);
  }

  static pw.Widget _hdr(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _cell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 11)),
    );
  }
}
