import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController positionController;
  late TextEditingController roleController;

  final Color primaryColor = const Color(0xFF005BFF);

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userData['name']);
    emailController = TextEditingController(text: widget.userData['email']);
    phoneController = TextEditingController(text: widget.userData['phone']);
    positionController = TextEditingController(
      text: widget.userData['position'],
    );
    roleController = TextEditingController(text: widget.userData['role']);
  }

  bool _hasChanged() {
    return nameController.text != widget.userData['name'] ||
        emailController.text != widget.userData['email'] ||
        phoneController.text != widget.userData['phone'] ||
        positionController.text != widget.userData['position'] ||
        roleController.text != widget.userData['role'];
  }

  Future<void> updateUser() async {
    if (!_hasChanged()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thay đổi thông tin trước khi cập nhật!'),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
          'name': nameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
          'position': positionController.text,
          'role': roleController.text,
        });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
      Navigator.pop(context); // Quay lại trang user_management_screen.dart
    }
  }

  Future<void> confirmDeleteUser() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa nhân viên này?"),
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa nhân viên!')));
        Navigator.pop(context); // Quay lại trang user_management_screen.dart
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          "Thông tin nhân viên",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const _ProfilePic(),
            Text(
              nameController.text,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const Divider(height: 32),
            _InfoItem(
              label: "Họ tên",
              controller: nameController,
              icon: Icons.person,
            ),
            _InfoItem(
              label: "Email",
              controller: emailController,
              icon: Icons.email,
            ),
            _InfoItem(
              label: "Số điện thoại",
              controller: phoneController,
              icon: Icons.phone,
            ),
            _InfoItem(
              label: "Chức vụ",
              controller: positionController,
              icon: Icons.work,
            ),
            _InfoItem(
              label: "Vai trò",
              controller: roleController,
              icon: Icons.admin_panel_settings,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text(
                      "Cập nhật",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: updateUser,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.delete),
                    label: const Text(
                      "Xóa",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: confirmDeleteUser,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ProfilePic extends StatelessWidget {
  const _ProfilePic();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(
            context,
          ).textTheme.bodyLarge!.color!.withOpacity(0.08),
        ),
      ),
      child: const CircleAvatar(
        radius: 50,
        backgroundColor: Color(0xFFE3F2FD),
        child: Icon(Icons.person, size: 50, color: Color(0xFF2196F3)),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  const _InfoItem({
    required this.label,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
          labelText: label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
