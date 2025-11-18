import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_haiau/models/sample_model.dart';
import 'package:flutter_haiau/models/user_model.dart';
import 'package:flutter_haiau/services/auth_service.dart';

class SampleDetailScreen extends StatefulWidget {
  final SampleModel sample;

  const SampleDetailScreen({super.key, required this.sample});

  @override
  State<SampleDetailScreen> createState() => _SampleDetailScreenState();
}

class _SampleDetailScreenState extends State<SampleDetailScreen> {
  late SampleModel _currentSample;
  late SampleStatus _selectedStatus;

  final AuthService _auth = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFunctions functions = FirebaseFunctions.instance;

  bool _submitting = false;
  final Color primaryColor = const Color(0xFF005BFF);

  @override
  void initState() {
    super.initState();
    _currentSample = widget.sample;
    _selectedStatus = widget.sample.status;
  }

  bool _hasStatusChanged() {
    return _selectedStatus != widget.sample.status;
  }

  // ------------------ UPDATE -------------------------
  Future<void> updateSampleStatus() async {
    if (!_hasStatusChanged()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thay đổi trạng thái trước khi cập nhật'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final callable = functions.httpsCallable('updateSampleStatus');

      await callable({
        'id': _currentSample.id,
        'status': statusToString(_selectedStatus),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ------------------ DELETE -------------------------
  Future<void> deleteSample() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa mẫu ${_currentSample.sampleCode}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _submitting = true);

    try {
      final callable = functions.httpsCallable('deleteSample');
      await callable({'id': _currentSample.id});

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa mẫu')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ------------------ UI FIELD -------------------------
  Widget _infoField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        enabled: false,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        controller: TextEditingController(text: value),
      ),
    );
  }

  Widget _statusDropdown(bool isAdmin) {
    final primaryColor = const Color(0xFF2196F3);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.science, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: isAdmin
                  ? DropdownButtonHideUnderline(
                      child: DropdownButton<SampleStatus>(
                        value: _selectedStatus,
                        isExpanded: true,
                        items: SampleStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              statusToString(status),
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedStatus = value!);
                        },
                      ),
                    )
                  : Text(
                      statusToString(_selectedStatus),
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ MAIN UI -------------------------
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _auth.streamUser(currentUser?.uid),
      builder: (context, snapshot) {
        final role = snapshot.data?.role ?? 'nhanvien';
        final bool isAdmin = role == 'admin';

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Chi tiết mẫu'),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          body: Container(
            color: const Color(0xFFF5F6FA),
            child: LayoutBuilder(
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
                              Icons.science,
                              size: 50,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _currentSample.sampleCode,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 32),

                          _infoField(
                            "Tên khách hàng",
                            _currentSample.customerName,
                            Icons.person,
                          ),
                          _infoField(
                            "Loại mẫu",
                            _currentSample.sampleType,
                            Icons.category,
                          ),
                          _infoField(
                            "Ngày nhận",
                            _currentSample.receivedDate,
                            Icons.date_range,
                          ),
                          _infoField(
                            "Thời gian tạo",
                            _currentSample.createdAt.toDate().toString(),
                            Icons.access_time,
                          ),

                          _statusDropdown(isAdmin),

                          const SizedBox(height: 24),

                          if (isAdmin)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: !_submitting
                                        ? updateSampleStatus
                                        : null,
                                    icon: const Icon(Icons.save),
                                    label: Text(
                                      _submitting ? 'Đang...' : 'Cập nhật',
                                    ),
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
                                    onPressed: !_submitting
                                        ? deleteSample
                                        : null,
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Xóa'),
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
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
