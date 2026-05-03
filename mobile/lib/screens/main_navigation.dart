import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'beranda_screen.dart';
import 'dashboard_screen.dart';
import 'status_screen.dart';
import 'darurat_screen.dart';
import 'edukasi_screen.dart';

// Notifier global untuk navigasi antar tab dari screen manapun
final navIndexNotifier = ValueNotifier<int>(0);

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  void refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    navIndexNotifier.addListener(_onNavChanged);
  }

  void _onNavChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    navIndexNotifier.removeListener(_onNavChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navIndexNotifier.value;
    final screens = [
      BerandaScreen(onRefresh: refresh),
      DashboardScreen(onRefresh: refresh),
      StatusScreen(onRefresh: refresh),
      const DaruratScreen(),
      const EdukasiScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => navIndexNotifier.value = i,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: AppTheme.textGrey,
          backgroundColor: Colors.white,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Status',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency_outlined),
              activeIcon: Icon(Icons.emergency),
              label: 'Darurat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Edukasi',
            ),
          ],
        ),
      ),
    );
  }
}