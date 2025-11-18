import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../services/pdf/sample_report_pdf.dart';

class SampleReportScreen extends StatefulWidget {
  const SampleReportScreen({super.key});

  @override
  State<SampleReportScreen> createState() => _SampleReportScreenState();
}

class _SampleReportScreenState extends State<SampleReportScreen> {
  DateTime? from;
  DateTime? to;
  String status = "Tất cả";

  final dateFormatter = DateFormat("dd/MM/yyyy");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Báo cáo mẫu"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterControls(),
          Expanded(child: _buildReportResults()),
        ],
      ),
    );
  }

  // ==============================================================
  //  FILTER UI
  // ==============================================================

  Widget _buildFilterControls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDate: from ?? DateTime.now(),
                    );
                    if (d != null) setState(() => from = d);
                  },
                  child: Text(
                    from == null ? "Từ ngày" : dateFormatter.format(from!),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDate: to ?? DateTime.now(),
                    );
                    if (d != null) setState(() => to = d);
                  },
                  child: Text(
                    to == null ? "Đến ngày" : dateFormatter.format(to!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          DropdownButton<String>(
            value: status,
            items: const [
              "Tất cả",
              "Đã trả kết quả",
              "Đang phân tích",
              "Hoàn thành",
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => status = v!),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  //  REPORT LIST
  // ==============================================================

  Widget _buildReportResults() {
    Query query = FirebaseFirestore.instance.collection('samples');

    if (status != "Tất cả") {
      query = query.where('status', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // Lọc theo ngày
        final filtered = docs.where((d) {
          final dateText = d['receivedDate']?.toString();
          DateTime? date;

          try {
            date = dateFormatter.parse(dateText ?? "");
          } catch (e) {
            return false;
          }

          if (from != null && date.isBefore(from!)) return false;
          if (to != null && date.isAfter(to!)) return false;

          return true;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text("Không có dữ liệu"));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final s = filtered[i];

            return ListTile(
              title: Text(s['sampleCode']),
              subtitle: Text("Khách hàng: ${s['customerName']}"),
              trailing: Text(s['status']),
            );
          },
        );
      },
    );
  }

  // ==============================================================
  //  EXPORT PDF
  // ==============================================================

  Future<void> _exportPdf() async {
    Query query = FirebaseFirestore.instance.collection('samples');

    if (status != "Tất cả") {
      query = query.where('status', isEqualTo: status);
    }

    final snapshot = await query.get();

    final filtered = snapshot.docs.where((d) {
      final dateText = d['receivedDate']?.toString();
      DateTime? date;

      try {
        date = dateFormatter.parse(dateText ?? "");
      } catch (e) {
        return false;
      }

      if (from != null && date.isBefore(from!)) return false;
      if (to != null && date.isAfter(to!)) return false;

      return true;
    }).toList();

    final data = filtered.map((e) => e.data() as Map<String, dynamic>).toList();

    final Uint8List pdfBytes = await SampleReportPDF.generate(data);

    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }
}
