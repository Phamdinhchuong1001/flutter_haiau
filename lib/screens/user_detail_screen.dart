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

  Future<void> updateUser() async {
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
  }

  Future<void> deleteUser() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa nhân viên!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin nhân viên'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Họ tên'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
            TextField(
              controller: positionController,
              decoration: const InputDecoration(labelText: 'Chức vụ'),
            ),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(labelText: 'Vai trò'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: updateUser,
              icon: const Icon(Icons.save),
              label: const Text('Cập nhật'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: deleteUser,
              icon: const Icon(Icons.delete),
              label: const Text('Xóa nhân viên'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
