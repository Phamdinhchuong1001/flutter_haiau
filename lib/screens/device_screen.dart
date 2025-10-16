import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final List<Map<String, dynamic>> _devices = [
    {
      'code': 'TB001',
      'name': 'Máy đo áp suất',
      'lastCalibration': DateTime(2025, 8, 10),
      'nextCalibration': DateTime(2026, 8, 10),
    },
    {
      'code': 'TB002',
      'name': 'Cân điện tử',
      'lastCalibration': DateTime(2025, 7, 15),
      'nextCalibration': DateTime(2025, 10, 20),
    },
    {
      'code': 'TB003',
      'name': 'Máy quang phổ',
      'lastCalibration': DateTime(2024, 9, 10),
      'nextCalibration': DateTime(2025, 1, 5),
    },
  ];

  String _getStatus(DateTime nextCalibration) {
    final now = DateTime.now();
    final diff = nextCalibration.difference(now).inDays;

    if (diff < 0) return 'Hết hạn';
    if (diff <= 30) return 'Sắp tới hạn';
    return 'Hiệu chuẩn OK';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hết hạn':
        return Colors.red.shade100;
      case 'Sắp tới hạn':
        return Colors.yellow.shade100;
      default:
        return Colors.green.shade100;
    }
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'Hết hạn':
        return const Icon(Icons.circle, color: Colors.red, size: 14);
      case 'Sắp tới hạn':
        return const Icon(Icons.circle, color: Colors.orange, size: 14);
      default:
        return const Icon(Icons.circle, color: Colors.green, size: 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thiết bị'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateColor.resolveWith(
                  (states) => Colors.blue.shade50),
              columns: const [
                DataColumn(label: Text('Mã thiết bị')),
                DataColumn(label: Text('Tên thiết bị')),
                DataColumn(label: Text('Ngày hiệu chuẩn')),
                DataColumn(label: Text('Ngày tới hạn')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: _devices.map((device) {
                final status = _getStatus(device['nextCalibration']);
                final formatter = DateFormat('dd/MM/yyyy');
                return DataRow(
                  color: MaterialStateColor.resolveWith(
                      (states) => _getStatusColor(status)),
                  cells: [
                    DataCell(Text(device['code'])),
                    DataCell(Text(device['name'])),
                    DataCell(Text(formatter.format(device['lastCalibration']))),
                    DataCell(Text(formatter.format(device['nextCalibration']))),
                    DataCell(Row(
                      children: [
                        _getStatusIcon(status),
                        const SizedBox(width: 6),
                        Text(status,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
