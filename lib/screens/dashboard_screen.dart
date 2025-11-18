import 'package:flutter/material.dart';
import 'package:flutter_haiau/services/auth_service.dart';
import 'package:flutter_haiau/screens/user_management_screen.dart';
import 'package:flutter_haiau/screens/device_screen.dart';
import 'package:flutter_haiau/screens/sample_screen.dart';
import 'package:flutter_haiau/screens/report_menu_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _auth = AuthService();
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardContent(),
    const SampleScreen(),
    const DeviceScreen(),
    const UserManagementScreen(),
    const ReportMenuScreen(),
  ];

  void _onSelectPage(int index, {bool closeDrawer = false}) {
    final isWide = MediaQuery.of(context).size.width > 800;

    if (closeDrawer) Navigator.pop(context);

    if (isWide) {
      // Web: chỉ đổi nội dung
      setState(() => _selectedIndex = index);
    } else {
      // Mobile: mở trang riêng với AppBar riêng
      Widget? page;
      switch (index) {
        case 0:
          page = const DashboardScreen();
          break;
        case 1:
          page = const SampleScreen();
          break;
        case 2:
          page = const DeviceScreen();
          break;
        case 3:
          page = const UserManagementScreen();
          break;
        case 4:
          page = const ReportMenuScreen();
          break;
        default:
          page = null;
      }
      if (page != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: isWide
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF005BFF),
              title: const Text(
                'Hải Âu Manager',
                style: TextStyle(color: Colors.white),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      drawer: isWide ? null : _buildSidebar(isDrawer: true),
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) _buildSidebar(),
            Expanded(
              child: IndexedStack(index: _selectedIndex, children: _pages),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar({bool isDrawer = false}) {
    return Container(
      width: 250,
      color: const Color(0xFF005BFF),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF005BFF)),
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
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: Image.asset(
                    'assets/logokonen.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          _buildMenuItem(
            Icons.dashboard,
            'Bảng điều khiển',
            () => _onSelectPage(0, closeDrawer: isDrawer),
          ),
          _buildMenuItem(
            Icons.science,
            'Quản lý mẫu',
            () => _onSelectPage(1, closeDrawer: isDrawer),
          ),
          _buildMenuItem(
            Icons.settings,
            'Quản lý thiết bị',
            () => _onSelectPage(2, closeDrawer: isDrawer),
          ),
          _buildMenuItem(
            Icons.people,
            'Nhân viên',
            () => _onSelectPage(3, closeDrawer: isDrawer),
          ),
          _buildMenuItem(
            Icons.picture_as_pdf,
            'Báo cáo',
            () => _onSelectPage(4, closeDrawer: isDrawer),
          ),
          const Divider(color: Colors.white54),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: Color.fromARGB(255, 255, 17, 0),
                fontWeight: FontWeight.bold,
              ),
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
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan hệ thống',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              _SampleCard(),
              _DeviceCard(),
              _UserCard(),
              _InfoCard(
                icon: Icons.picture_as_pdf,
                title: 'Tổng Báo Cáo',
                value: '0',
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Tính năng nhanh',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickButton(
                icon: Icons.add,
                label: 'Thêm mẫu',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SampleScreen()),
                  );
                },
              ),
              _QuickButton(
                icon: Icons.science,
                label: 'Quản lý mẫu',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SampleScreen()),
                  );
                },
              ),
              _QuickButton(
                icon: Icons.fact_check,
                label: 'Thiết bị',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeviceScreen()),
                  );
                },
              ),
              _QuickButton(
                icon: Icons.group,
                label: 'Nhân viên',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserManagementScreen(),
                    ),
                  );
                },
              ),
              _QuickButton(
                icon: Icons.assignment,
                label: 'Báo cáo',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportMenuScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------- Các card thống kê Firestore ------------

class _SampleCard extends StatelessWidget {
  const _SampleCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('samples').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _InfoCard(
            icon: Icons.science,
            title: 'Tổng Mẫu Thử',
            value: '...',
            color: Colors.blue,
          );
        }
        final total = snapshot.data!.docs.length;
        return _InfoCard(
          icon: Icons.science,
          title: 'Tổng Mẫu Thử',
          value: '$total',
          color: Colors.blue,
        );
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('devices').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _InfoCard(
            icon: Icons.settings,
            title: 'Tổng Thiết Bị',
            value: '...',
            color: Colors.blue,
          );
        }
        final total = snapshot.data!.docs.length;
        return _InfoCard(
          icon: Icons.settings,
          title: 'Tổng Thiết Bị',
          value: '$total',
          color: Colors.blue,
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _InfoCard(
            icon: Icons.people,
            title: 'Tổng Nhân Viên',
            value: '...',
            color: Colors.blue,
          );
        }
        final total = snapshot.data!.docs.length;
        return _InfoCard(
          icon: Icons.people,
          title: 'Tổng Nhân Viên',
          value: '$total',
          color: Colors.blue,
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------- Nút tính năng nhanh --------------

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
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
