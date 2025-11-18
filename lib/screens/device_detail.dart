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

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF2196F3)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ],
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
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Chi tiết thiết bị'),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          backgroundColor: const Color(0xFFF5F6FA),

          /// LAYOUT chính
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;

              return Center(
                child: Container(
                  width: isWide ? 700 : double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const CircleAvatar(
                          radius: 45,
                          backgroundColor: Color(0xFFE3F2FD),
                          child: Icon(
                            Icons.devices_other,
                            size: 50,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          _currentDevice.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          _currentDevice.deviceCode,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),

                        const Divider(height: 32),

                        _buildInfoField(
                          "Tên thiết bị",
                          _currentDevice.name,
                          Icons.label,
                        ),
                        _buildInfoField(
                          "Model / Serial",
                          _currentDevice.model,
                          Icons.qr_code_2,
                        ),
                        _buildInfoField(
                          "Hãng sản xuất",
                          _currentDevice.manufacturer,
                          Icons.factory,
                        ),
                        _buildInfoField(
                          "Ngày mua",
                          _currentDevice.purchaseDate.toDate().toString(),
                          Icons.calendar_month,
                        ),
                        _buildInfoField(
                          "Chu kỳ hiệu chuẩn (tháng)",
                          _currentDevice.calibrationCycle,
                          Icons.timer,
                        ),
                        _buildInfoField(
                          "Thời gian tạo",
                          _currentDevice.createdAt.toDate().toString(),
                          Icons.access_time,
                        ),

                        const SizedBox(height: 20),
                        const Divider(height: 20),

                        if (isAdmin) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Cập nhật trạng thái",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          /// DROPDOWN
                          Container(
                            height: 55,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cached,
                                  color: _getStatusColor(_selectedStatus),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<DeviceStatus>(
                                      value: _selectedStatus,
                                      isExpanded: true,
                                      items: statusOptions.map((s) {
                                        return DropdownMenuItem(
                                          value: s,
                                          child: Text(statusToString(s)),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedStatus = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : _updateDeviceStatus,
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
                                  label: const Text('Cập nhật trạng thái'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : _confirmDeleteDevice,
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Xóa thiết bị'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
