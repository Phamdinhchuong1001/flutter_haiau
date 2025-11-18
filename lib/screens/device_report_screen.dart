import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import '../../services/pdf/device_report_pdf.dart';

class DeviceReportScreen extends StatefulWidget {
  const DeviceReportScreen({super.key});

  @override
  State<DeviceReportScreen> createState() => _DeviceReportScreenState();
}

class _DeviceReportScreenState extends State<DeviceReportScreen> {
  String status = "Tất cả";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Báo cáo thiết bị"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPDF,
          ),
        ],
      ),

      body: Column(
        children: [
          _buildFilter(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // ------------------------ FILTER ------------------------
  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: DropdownButton<String>(
        value: status,
        items: [
          "Tất cả",
          "Đang hoạt động",
          "Hư hỏng",
          "Đang hiệu chuẩn",
          "Ngừng sử dụng",
        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => status = v!),
      ),
    );
  }

  // ------------------------ LIST ------------------------
  Widget _buildList() {
    Query query = FirebaseFirestore.instance.collection('devices');

    if (status != "Tất cả") {
      query = query.where('status', isEqualTo: status);
    }

    return StreamBuilder(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView(
          children: docs.map((d) {
            return ListTile(
              title: Text(d['name']),
              subtitle: Text("Model: ${d['model']}"),
              trailing: Text(d['status']),
            );
          }).toList(),
        );
      },
    );
  }

  // ------------------------ EXPORT PDF ------------------------
  Future<void> _exportPDF() async {
    Query query = FirebaseFirestore.instance.collection('devices');

    if (status != "Tất cả") {
      query = query.where('status', isEqualTo: status);
    }

    final snap = await query.get();

    final deviceList = snap.docs
        .map(
          (d) => {
            "name": d['name'],
            "model": d['model'],
            "status": d['status'],
          },
        )
        .toList();

    final pdf = await DeviceReportPDF.generate(
      status: status,
      devices: deviceList,
    );

    await Printing.layoutPdf(onLayout: (format) => pdf);
  }
}
