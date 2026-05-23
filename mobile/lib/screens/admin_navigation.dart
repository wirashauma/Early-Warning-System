import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_sensors_screen.dart';
import 'admin_alerts_screen.dart';
import 'admin_reports_screen.dart';
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
    'Sensor',
    'Peringatan',
    'Laporan',
    'Pengguna',
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const AdminDashboardScreen(),
      const AdminSensorsScreen(),
      const AdminAlertsScreen(),
      const AdminReportsScreen(),
      const AdminUsersScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0066FF)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_currentIndex],
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Early Warning System',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0066FF),
          unselectedItemColor: AppTheme.textGrey,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dasbor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sensors),
              activeIcon: Icon(Icons.sensors_outlined),
              label: 'Sensor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign),
              label: 'Peringatan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Laporan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people),
              label: 'Pengguna',
            ),
          ],
        ),
      ),
    );
  }
}
