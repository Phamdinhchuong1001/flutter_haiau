import 'package:flutter/material.dart';
import 'package:flutter_haiau/services/auth_service.dart';
import 'package:flutter_haiau/screens/user_management_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'package:flutter_haiau/screens/device_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue.shade700,
        title: const Text(
          'Hải Âu Manager',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.lightBlue.shade700),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Hải Âu Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12), // Khoảng cách giữa chữ và logo
                  SizedBox(
                    height: 60,
                    child: Image.asset(
                      'assets/logokonen.png', // đường dẫn logo của bạn
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Bảng điều khiển'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.science),
              title: const Text('Quản lý mẫu'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Quản lý thiết bị'),
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeviceScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Nhân viên'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Báo cáo'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await _auth.signOut();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoCard(
              icon: Icons.science,
              title: 'Tổng Mẫu Thử',
              value: '0',
              color: Colors.blue.shade800,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.settings,
              title: 'Tổng Thiết Bị',
              value: '0',
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 12),

            // 🔥 Realtime tổng nhân viên
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildInfoCard(
                    icon: Icons.people,
                    title: 'Tổng Nhân Viên',
                    value: '...',
                    color: Colors.blue.shade400,
                  );
                }
                if (snapshot.hasError) {
                  return _buildInfoCard(
                    icon: Icons.people,
                    title: 'Tổng Nhân Viên',
                    value: 'Lỗi',
                    color: Colors.red.shade400,
                  );
                }

                final total = snapshot.data?.docs.length ?? 0;
                return _buildInfoCard(
                  icon: Icons.people,
                  title: 'Tổng Nhân Viên',
                  value: '$total',
                  color: Colors.blue.shade400,
                );
              },
            ),

            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.picture_as_pdf,
              title: 'Tổng Báo Cáo',
              value: '0',
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tính năng nhanh',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickButton(
                  context,
                  icon: Icons.add,
                  label: 'Thêm mẫu',
                  onTap: () {},
                ),
                _buildQuickButton(
                  context,
                  icon: Icons.fact_check,
                  label: 'Thiết bị',
                  onTap: () {},
                ),
                _buildQuickButton(
                  context,
                  icon: Icons.group,
                  label: 'Nhân viên',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickButton(
                  context,
                  icon: Icons.assignment,
                  label: 'Báo cáo',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 24,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.lightBlue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.lightBlue.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.lightBlue.shade700, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.lightBlue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
