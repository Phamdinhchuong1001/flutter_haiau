import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF005BFF),
        centerTitle: true,
        title: const Text(
          'Quản lý nhân viên',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddUserDialog(),
              );
            },
          ),
        ],
      ),

      // ========== PHẦN THÂN ==========
      body: Column(
        children: [
          // 🔍 Ô tìm kiếm
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: SizedBox(
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, chức vụ, vai trò hoặc email...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),

          // ========== DANH SÁCH NHÂN VIÊN ==========
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('name', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có nhân viên nào.'));
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final position = (data['position'] ?? '')
                      .toString()
                      .toLowerCase();
                  final role = (data['role'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();

                  if (searchQuery.isEmpty) return true;

                  return name.contains(searchQuery) ||
                      position.contains(searchQuery) ||
                      role.contains(searchQuery) ||
                      email.contains(searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy nhân viên nào.'),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 1.5,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade600,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          data['name'] ?? 'Không có tên',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(data['position'] ?? 'Không có chức vụ'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserDetailScreen(
                                userId: user.id,
                                userData: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ========== DIALOG THÊM NHÂN VIÊN ==========
class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final positionController = TextEditingController();
  final roleController = TextEditingController();

  Future<void> addUser() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('users').add({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'position': positionController.text.trim(),
        'role': roleController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm nhân viên thành công!')),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Thêm nhân viên mới',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: _inputDecoration('Họ tên'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Nhập tên' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: _inputDecoration('Email'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Nhập email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: _inputDecoration('Số điện thoại'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: positionController,
                decoration: _inputDecoration('Chức vụ'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: roleController,
                decoration: _inputDecoration('Vai trò'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: addUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
