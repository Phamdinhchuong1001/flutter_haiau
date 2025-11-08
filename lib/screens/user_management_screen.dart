// user_management_screen.dart
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFunctions functions = FirebaseFunctions.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> users = [];
  String searchQuery = '';
  bool loading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initRoleAndLoad();
  }

  Future<void> _initRoleAndLoad() async {
    setState(() => loading = true);
    try {
      final user = auth.currentUser;
      if (user != null) {
        final idToken = await user.getIdTokenResult();
        isAdmin = (idToken.claims?['role'] == 'admin');
      } else {
        isAdmin = false;
      }
    } catch (e) {
      isAdmin = false;
    }
    await fetchUsers();
    setState(() => loading = false);
  }

  Future<void> fetchUsers() async {
    setState(() => loading = true);
    try {
      debugPrint('📡 Gửi request getUsers...');

      final callable = functions.httpsCallable('getUsers');
      final result = await callable();

      debugPrint('✅ Response từ getUsers: ${result.data}');

      final data = result.data;
      final rawList = (data['users'] as List<dynamic>? ?? []);

      if (rawList.isEmpty) {
        debugPrint('ℹ️ API trả về danh sách rỗng');
      }

      users = rawList.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);

        if (m['fullname'] != null && (m['name'] == null || m['name'] == '')) {
          m['name'] = m['fullname'];
        } else if (m['name'] != null &&
            (m['fullname'] == null || m['fullname'] == '')) {
          m['fullname'] = m['name'];
        }
        return m;
      }).toList();

      debugPrint('📊 Tổng số user nhận được: ${users.length}');
    } catch (e, st) {
      debugPrint('❌ API Error fetchUsers: $e');
      debugPrint('❗ StackTrace: $st');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lấy danh sách nhân viên thất bại: ${e.toString()}'),
        ),
      );
      users = [];
    } finally {
      setState(() => loading = false);
      debugPrint('🏁 Hoàn tất fetchUsers()');
    }
  }

  // Xoá user bằng Cloud Function deleteUser (chỉ admin gọi được)
  Future<void> deleteUser(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xoá tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      debugPrint('⚠️ Hủy xóa user với uid: $uid');
      return;
    }

    try {
      debugPrint('📡 Gửi request deleteUser với uid: $uid');
      final callable = functions.httpsCallable('deleteUser');
      final result = await callable({'uid': uid});
      debugPrint('✅ deleteUser thành công. Response: ${result.data}');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa thành công')));

      await fetchUsers();
    } catch (e, st) {
      debugPrint('❌ deleteUser error: $e');
      debugPrint('❗ StackTrace: $st');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xóa thất bại: ${e.toString()}')));
    }
  }

  // Open detail page and handle possible update -> refresh list after pop
  Future<void> openDetail(Map<String, dynamic> userData) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetailScreen(
          userId: userData['id'] ?? userData['uid'] ?? '',
          userData: userData,
          isAdmin: isAdmin,
        ),
      ),
    );
    await fetchUsers();
  }

  // show dialog to add user (calls registerUser cloud function)
  Future<void> showAddUserDialog() async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền thêm người dùng')),
      );
      return;
    }
    await showDialog(
      context: context,
      builder: (_) => AddUserDialog(onCreated: () => fetchUsers()),
    );
  }

  List<Map<String, dynamic>> _applySearch() {
    if (searchQuery.trim().isEmpty) return users;
    final q = searchQuery.toLowerCase();
    return users.where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      final role = (m['role'] ?? '').toString().toLowerCase();
      final email = (m['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || role.contains(q) || email.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applySearch();

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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchUsers,
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.white),
            onPressed: showAddUserDialog,
            tooltip: 'Thêm nhân viên',
          ),
        ],
      ),
      body: Column(
        children: [
          // search
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
                onChanged: (v) => setState(() => searchQuery = v),
              ),
            ),
          ),

          // body
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      users.isEmpty
                          ? 'Chưa có nhân viên nào.'
                          : 'Không tìm thấy nhân viên nào.',
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final data = filtered[idx];
                      final displayName =
                          (data['name'] ?? data['fullname'] ?? '').toString();
                      final email = (data['email'] ?? '').toString();
                      final role = (data['role'] ?? '').toString();

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
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            displayName.isNotEmpty
                                ? displayName
                                : 'Không có tên',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            role.isNotEmpty ? role : 'Không có chức vụ',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAdmin)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => deleteUser(
                                    data['id'] ?? data['uid'] ?? data['uid'],
                                  ),
                                ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          onTap: () => openDetail(data),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------- AddUserDialog (calls registerUser) ----------
class AddUserDialog extends StatefulWidget {
  final VoidCallback? onCreated;
  const AddUserDialog({super.key, this.onCreated});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFunctions functions = FirebaseFunctions.instance;

  final fullnameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final roleCtrl = TextEditingController();

  bool submitting = false;

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('⚠️ Form không hợp lệ – thiếu dữ liệu');
      return;
    }
    setState(() => submitting = true);

    final dataSend = {
      'fullname': fullnameCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'password': passwordCtrl.text.trim(),
    };

    try {
      debugPrint('📡 Gửi request registerUser với payload: $dataSend');
      final callable = functions.httpsCallable('registerUser');
      final res = await callable(dataSend);
      debugPrint('✅ Response registerUser: ${res.data}');

      final data = res.data;
      if (data != null && data['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo tài khoản thành công')),
        );
        widget.onCreated?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tạo tài khoản: ${data?['message'] ?? ''}'),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('❌ registerUser error: $e');
      debugPrint('❗ StackTrace: $st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tạo tài khoản: ${e.toString()}')),
      );
    } finally {
      setState(() => submitting = false);
    }
  }

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                controller: fullnameCtrl,
                decoration: _input('Họ và tên'),
                validator: (v) => v == null || v.isEmpty ? 'Nhập tên' : null,
              ),

              const SizedBox(height: 8),
              TextFormField(
                controller: emailCtrl,
                decoration: _input('Email'),
                validator: (v) => v == null || v.isEmpty ? 'Nhập email' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordCtrl,
                decoration: _input('Mật khẩu'),
                obscureText: true,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nhập mật khẩu' : null,
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
          onPressed: submitting ? null : submit,
          child: submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Thêm'),
        ),
      ],
    );
  }
}
