import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_haiau/models/device_model.dart';
import 'package:flutter_haiau/services/auth_service.dart';
import 'package:flutter_haiau/models/user_model.dart';

final FirebaseFunctions functions = FirebaseFunctions.instanceFor(
  region: 'asia-southeast1',
);

class DeviceDetailScreen extends StatefulWidget {
  final DeviceModel device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late DeviceModel _currentDevice;
  late DeviceStatus _selectedStatus;

  final AuthService _auth = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final Color primaryColor = const Color(0xFF005BFF);

  final List<DeviceStatus> statusOptions = DeviceStatus.values;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDevice = widget.device;
    _selectedStatus = widget.device.status;
  }

  bool _hasStatusChanged() {
    return _selectedStatus != widget.device.status;
  }

  Color _getStatusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.active:
        return Colors.green.shade700;
      case DeviceStatus.broken:
        return Colors.red.shade700;
      case DeviceStatus.calibrating:
        return Colors.orange.shade700;
      case DeviceStatus.outOfService:
        return Colors.grey.shade700;
    }
  }

  Future<void> _updateDeviceStatus() async {
    if (!_hasStatusChanged()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trạng thái chưa thay đổi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'id': _currentDevice.id,
        'status': statusToString(_selectedStatus),
      };

      print('[API] Gọi updateDeviceStatus → $data');

      final result = await functions
          .httpsCallable('updateDeviceStatus')
          .call(data);

      print('[API] Kết quả updateDeviceStatus → ${result.data}');

      if (mounted) {
        setState(() {
          _currentDevice = _currentDevice.copyWith(status: _selectedStatus);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cập nhật trạng thái thành công: ${statusToString(_selectedStatus)}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      print('[API ERROR] updateDeviceStatus → $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật trạng thái: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteDevice() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text(
          "Bạn có chắc muốn xóa thiết bị ${_currentDevice.deviceCode} - ${_currentDevice.name}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Xác nhận",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final data = {'id': _currentDevice.id};

      print('[API] Gọi deleteDevice → $data');

      final result = await functions.httpsCallable('deleteDevice').call(data);

      print('[API] Kết quả deleteDevice → ${result.data}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa thiết bị!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('[API ERROR] deleteDevice → $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xóa thiết bị: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoCard(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _auth.streamUser(currentUser?.uid),
      builder: (context, snapshot) {
        final userRole = snapshot.data?.role ?? 'nhanvien';
        final bool isAdmin = (userRole == 'admin');

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            centerTitle: true,
            elevation: 0,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            title: const Text(
              "Chi tiết thiết bị",
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.devices_other,
                        size: 40,
                        color: Color(0xFF2196F3),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentDevice.deviceCode,
                              style: Theme.of(context).textTheme.titleLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.black87,
                                  ),
                            ),
                            Text(
                              statusToString(_currentDevice.status),
                              style: TextStyle(
                                color: _getStatusColor(_currentDevice.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _buildInfoCard("Tên thiết bị", _currentDevice.name),
                _buildInfoCard("Model / Serial", _currentDevice.model),
                _buildInfoCard("Hãng sản xuất", _currentDevice.manufacturer),
                _buildInfoCard(
                  "Ngày mua",
                  _currentDevice.purchaseDate.toDate().toString(),
                ),

                _buildInfoCard(
                  "Chu kỳ hiệu chuẩn (tháng)",
                  _currentDevice.calibrationCycle,
                ),
                _buildInfoCard(
                  "Thời gian tạo",
                  _currentDevice.createdAt.toDate().toString(),
                ),

                const Divider(height: 30),

                if (isAdmin) ...[
                  Text(
                    "Cập nhật Trạng thái",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<DeviceStatus>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.cached,
                        color: _getStatusColor(_selectedStatus),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(statusToString(status)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStatus = value!);
                    },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: const Text("Cập nhật trạng thái"),
                          onPressed: _isLoading ? null : _updateDeviceStatus,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.delete),
                          label: const Text("Xóa thiết bị"),
                          onPressed: _isLoading ? null : _confirmDeleteDevice,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
