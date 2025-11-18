import 'package:flutter/material.dart';
import 'sample_report_screen.dart';
import 'device_report_screen.dart';

class ReportMenuScreen extends StatelessWidget {
  const ReportMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Báo cáo")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.science),
            title: const Text("Báo cáo mẫu xét nghiệm"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SampleReportScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text("Báo cáo thiết bị"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceReportScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
