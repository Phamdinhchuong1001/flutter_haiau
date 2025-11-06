// user_detail_screen.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final bool isAdmin;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.userData,
    required this.isAdmin,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late TextEditingController fullnameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController positionController;
  late TextEditingController roleController;
  late TextEditingController birthDateController;

  final FirebaseFunctions functions = FirebaseFunctions.instance;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    fullnameController = TextEditingController(
      text: widget.userData['fullname'] ?? widget.userData['name'] ?? '',
    );
    emailController = TextEditingController(
      text: widget.userData['email'] ?? '',
    );
    phoneController = TextEditingController(
      text: widget.userData['phone'] ?? '',
    );
    positionController = TextEditingController(
      text: widget.userData['position'] ?? '',
    );
    roleController = TextEditingController(text: widget.userData['role'] ?? '');
    birthDateController = TextEditingController(
      text: widget.userData['birthDate'] ?? '',
    );
  }

  bool _hasChanged() {
    return fullnameController.text !=
            (widget.userData['fullname'] ?? widget.userData['name'] ?? '') ||
        emailController.text != (widget.userData['email'] ?? '') ||
        phoneController.text != (widget.userData['phone'] ?? '') ||
        positionController.text != (widget.userData['position'] ?? '') ||
        roleController.text != (widget.userData['role'] ?? '') ||
        birthDateController.text != (widget.userData['birthDate'] ?? '');
  }

  Future<void> _updateUser() async {
    if (!widget.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền cập nhật')),
      );
      return;
    }

    if (!_hasChanged()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thay đổi thông tin trước khi cập nhật'),
        ),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      final callable = functions.httpsCallable('updateUser');
      final payload = {
        'uid': widget.userId,
        'fullname': fullnameController.text.trim(),
        'birthDate': birthDateController.text.trim(),
        'position': positionController.text.trim(),
        'role': roleController.text.trim(),
      };

      final res = await callable(payload);
      final data = res.data;

      if (data != null && data['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
        Navigator.pop(context); // quay về sau khi cập nhật xong
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cập nhật lỗi: ${data?['message'] ?? 'Không xác định'}',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ updateUser error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _deleteUser() async {
    if (!widget.isAdmin) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bạn không có quyền xóa')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Xóa tài khoản sẽ xóa cả Authentication. Bạn có chắc không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => submitting = true);

    try {
      final callable = functions.httpsCallable('deleteUser');
      final res = await callable({'uid': widget.userId});

      final data = res.data;
      if (data != null && data['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa người dùng')));
        Navigator.pop(context); // Quay lại màn trước
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Xóa thất bại: ${data?['message'] ?? 'Lỗi không xác định'}',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ deleteUser error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xóa thất bại: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF005BFF);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Thông tin nhân viên'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(Icons.person, size: 40, color: Color(0xFF2196F3)),
            ),
            const SizedBox(height: 12),
            Text(
              fullnameController.text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _infoField('Họ tên', fullnameController, Icons.person),
            _infoField('Email', emailController, Icons.email, enabled: false),
            _infoField('Số điện thoại', phoneController, Icons.phone),
            _infoField('Chức vụ', positionController, Icons.work),
            _infoField('Vai trò', roleController, Icons.admin_panel_settings),
            _infoField('Ngày sinh', birthDateController, Icons.calendar_today),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isAdmin && !submitting
                        ? _updateUser
                        : null,
                    icon: const Icon(Icons.save),
                    label: Text(submitting ? 'Đang...' : 'Cập nhật'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isAdmin && !submitting
                        ? _deleteUser
                        : null,
                    icon: const Icon(Icons.delete),
                    label: const Text('Xóa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: ctrl,
        enabled:
            enabled &&
            widget.isAdmin, // only admin can edit (except email disabled)
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
      ),
    );
  }
}
