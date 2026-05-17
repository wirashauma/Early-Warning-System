import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_sensors_screen.dart';
import 'admin_thresholds_screen.dart';
import 'admin_alerts_screen.dart';
import 'admin_users_screen.dart';

class AdminNavigation extends StatefulWidget {
  const AdminNavigation({super.key});

  @override
  State<AdminNavigation> createState() => _AdminNavigationState();
}

class _AdminNavigationState extends State<AdminNavigation> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Dasbor Admin',
    'Manajemen Sensor IoT',
    'Ambang Batas (Threshold)',
    'Peringatan (Broadcast)',
    'Notifikasi & Inbox',
    'Laporan (Data Logs)',
    'Manajemen Pengguna'
  ];

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminSensorsScreen(),
    const AdminThresholdScreen(),
    const AdminAlertsScreen(),
    const AdminNotificationsScreen(), // FIX 1: Memanggil Class Inline di bawah
    const AdminReportsScreen(),       // FIX 2: Memanggil Class Inline di bawah
    const AdminUsersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0066FF)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titles[_currentIndex], style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold)),
            const Text('Early Warning System', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari sensor, notifikasi, atau laporan...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              readOnly: true,
              onTap: () {},
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
            onPressed: () => setState(() {}),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('2026/2027', style: TextStyle(color: Color(0xFF0369A1), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFF0066FF),
            child: Text('A', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF0066FF),
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF0052D4)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      // FIX 3: Mengganti .withOpacity ke .withValues standar Flutter 2026
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.waves, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Flood Guard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Dashboard Admin', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(0, Icons.dashboard_outlined, 'Dasbor'),
                    _buildDrawerItem(1, Icons.sensors, 'Sensor'),
                    _buildDrawerItem(2, Icons.tune, 'Ambang Batas'),
                    _buildDrawerItem(3, Icons.campaign_outlined, 'Peringatan'),
                    _buildDrawerItem(4, Icons.notifications_none, 'Notifikasi'),
                    _buildDrawerItem(5, Icons.analytics_outlined, 'Laporan'),
                    _buildDrawerItem(6, Icons.people_alt_outlined, 'Pengguna'),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white70),
                title: const Text('Keluar Aplikasi', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pushReplacementNamed(context, '/login'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: _screens[_currentIndex],
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return ListTile(
      selected: isSelected,
      // FIX 4: Mengganti .withOpacity ke .withValues standar Flutter 2026
      selectedTileColor: Colors.white.withValues(alpha: 0.15),
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context);
      },
    );
  }
}

// =========================================================================
// STUB WIDGETS (Bypass Sementara agar Kompilasi Bersih Tanpa Missing Class)
// =========================================================================

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Halaman Kotak Masuk Notifikasi Admin'));
  }
}

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Halaman Unduh Data Laporan Logs'));
  }
}