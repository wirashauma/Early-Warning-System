import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../localization/locale_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final titles = [
      context.t('adminDashboardTitle'),
      context.t('sensors'),
      context.t('alertsMenu'),
      context.t('reports'),
      context.t('users'),
    ];

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
              titles[_currentIndex],
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              context.t('appSubtitle'),
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Color(0xFF0066FF)),
            onSelected: (value) {
              context.read<LocaleProvider>().setLocale(Locale(value));
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'id',
                child: Text(context.t('indonesian')),
              ),
              PopupMenuItem(
                value: 'en',
                child: Text(context.t('english')),
              ),
            ],
          ),
        ],
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
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: context.t('dashboard'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.sensors),
              activeIcon: const Icon(Icons.sensors_outlined),
              label: context.t('sensors'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.campaign_outlined),
              activeIcon: const Icon(Icons.campaign),
              label: context.t('alertsMenu'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.analytics_outlined),
              activeIcon: const Icon(Icons.analytics),
              label: context.t('reports'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_alt_outlined),
              activeIcon: const Icon(Icons.people),
              label: context.t('users'),
            ),
          ],
        ),
      ),
    );
  }
}
