import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_haiau/models/sample_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_haiau/services/auth_service.dart';
import 'package:flutter_haiau/models/user_model.dart';

final FirebaseFunctions functions = FirebaseFunctions.instance;

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
  final Color primaryColor = const Color(0xFF005BFF);

  final List<SampleStatus> statusOptions = SampleStatus.values;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentSample = widget.sample;
    _selectedStatus = widget.sample.status;
  }

  bool _hasStatusChanged() {
    return _selectedStatus != widget.sample.status;
  }

  Future<void> updateSampleStatus() async {
    if (!_hasStatusChanged()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trạng thái chưa thay đổi!')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'id': _currentSample.id,
        'status': statusToString(_selectedStatus),
      };

      final HttpsCallable callable = functions.httpsCallable(
        'updateSampleStatus',
      );
      await callable.call(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cập nhật trạng thái thành công: ${statusToString(_selectedStatus)}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> confirmDeleteSample() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text(
          "Bạn có chắc muốn xóa mẫu ${_currentSample.sampleCode} của khách hàng ${_currentSample.customerName}?",
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

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        final data = {'id': _currentSample.id};

        final HttpsCallable callable = functions.httpsCallable('deleteSample');
        await callable.call(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa mẫu!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } on FirebaseFunctionsException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi xóa mẫu: ${e.message ?? 'Lỗi không xác định'}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SampleStatus status) {
    switch (status) {
      case SampleStatus.analyzing:
        return Colors.orange.shade700;
      case SampleStatus.completed:
        return Colors.green.shade700;
      case SampleStatus.resultReturned:
        return Colors.blue.shade700;
    }
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
              "Chi tiết Mẫu",
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
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
                        Icons.science,
                        size: 40,
                        color: Color(0xFF2196F3),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentSample.sampleCode,
                              style: Theme.of(context).textTheme.titleLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.black87,
                                  ),
                            ),
                            Text(
                              statusToString(_currentSample.status),
                              style: TextStyle(
                                color: _getStatusColor(_currentSample.status),
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

                _buildInfoCard("Tên Khách hàng", _currentSample.customerName),
                _buildInfoCard("Loại Mẫu", _currentSample.sampleType),
                _buildInfoCard("Ngày Nhận", _currentSample.receivedDate),
                _buildInfoCard(
                  "Thời gian tạo",
                  _currentSample.createdAt.toDate().toString(),
                ),
                const Divider(height: 30),
                if (isAdmin) ...[
                  Text(
                    "Cập nhật Trạng thái",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<SampleStatus>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.cached,
                        color: _getStatusColor(_selectedStatus),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    items: statusOptions.map((status) {
                      return DropdownMenuItem<SampleStatus>(
                        value: status,
                        child: Text(statusToString(status)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          icon: _isLoading
                              ? Container(
                                  width: 24,
                                  height: 24,
                                  padding: const EdgeInsets.all(2.0),
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Icon(Icons.save),

                          label: const Text(
                            "Cập nhật trạng thái",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isLoading ? null : updateSampleStatus,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          icon: const Icon(Icons.delete),
                          label: const Text(
                            "Xóa mẫu",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isLoading ? null : confirmDeleteSample,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
