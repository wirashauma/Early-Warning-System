import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../models/auth_provider.dart';  
import '../theme/app_theme.dart';

// IMPOR RESMI SCREEN BAWAAN PROYEK ANDA
import 'beranda_screen.dart';
import 'dashboard_screen.dart';
import 'status_screen.dart';
import 'darurat_screen.dart';
import 'profile_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_sensors_screen.dart';
import 'admin_thresholds_screen.dart';
import 'admin_alerts_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';

final navIndexNotifier = ValueNotifier<int>(0);

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // State index internal untuk mengontrol ke-7 halaman menu Admin Mobile
  int _adminSelectedIndex = 0;

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
    final authProvider = context.watch<AuthProvider>();
    
    // DETEKSI ROLE SINKRON DATABASE POSTGRES (ADMIN / USER)
    final String roleField = authProvider.userRole.toString().toUpperCase();
    final bool isAdmin = roleField == 'ADMIN' || 
                         roleField == 'USERROLE.ADMIN' ||
                         roleField.contains('ADMIN');

    // =========================================================================
    // JALUR A: TAMPILAN MOBILE ADMIN (7 MENU UTAMA SESUAI STRUKTUR PROYEK ANDA)
    // =========================================================================
    if (isAdmin) {
      // 🎯 SOLUSI FIX UTAMA: Mengganti AdminThresholdsScreen menjadi AdminThresholdScreen (Tanpa huruf S)
      final List<Widget> adminPages = [
        const AdminDashboardScreen(),     // 1. Dasbor
        const AdminSensorsScreen(),       // 2. Sensor
        const AdminThresholdScreen(),      // 3. Ambang Batas (Sesuai nama kelas asli proyek Anda)
        const AdminAlertsScreen(),         // 4. Peringatan
        const AdminNotificationsScreen(), // 5. Notifikasi
        const AdminReportsScreen(),       // 6. Laporan
        const AdminUsersScreen(),         // 7. Pengguna
      ];

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A), // Warna biru navy admin operasional
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            _getAdminMenuTitle(_adminSelectedIndex),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // 🔵 SIDEBAR DRAWER INTERAKTIF MOBILE UNTUK MENAMPUNG KE-7 MENU UTAMA ADMIN
        drawer: Drawer(
          child: Container(
            color: const Color(0xFF1E3A8A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: Color(0xFF0F172A)),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Color(0xFF3B82F6),
                    child: Text('A', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  accountName: Text('Admin EWS', style: TextStyle(fontWeight: FontWeight.bold)),
                  accountEmail: Text('admin@ews.com', style: TextStyle(color: Colors.white70)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('SISTEM KENDALI UTAMA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                _buildDrawerItem(0, Icons.dashboard_outlined, 'Dasbor'),
                _buildDrawerItem(1, Icons.sensors, 'Sensor'),
                _buildDrawerItem(2, Icons.tune, 'Ambang Batas'),
                _buildDrawerItem(3, Icons.campaign_outlined, 'Peringatan'),
                _buildDrawerItem(4, Icons.mail_outline, 'Notifikasi'),
                _buildDrawerItem(5, Icons.analytics_outlined, 'Laporan'),
                _buildDrawerItem(6, Icons.account_circle_outlined, 'Pengguna'),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text('Logout', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    final authProvider = context.read<AuthProvider>();
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Apakah Anda yakin ingin keluar dari akun admin?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
                          ElevatedButton(
                            onPressed: () {
                              authProvider.logout();
                              Navigator.pop(dialogCtx);
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusBahaya, foregroundColor: Colors.white),
                            child: const Text('Keluar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        body: adminPages[_adminSelectedIndex],
      );
    }

    // =========================================================================
    // JALUR B: TAMPILAN MOBILE USER / WARGA UMUM (5 MENU TAB BAWAH ASLI)
    // =========================================================================
    final currentIndex = navIndexNotifier.value;
    final userScreens = [
      BerandaScreen(onRefresh: refresh),
      DashboardScreen(onRefresh: refresh),
      StatusScreen(onRefresh: refresh),
      const DaruratScreen(),
      ProfileScreen(onLogout: refresh),
    ];

    return Scaffold(
      body: userScreens[currentIndex],
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
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Peta'),
            BottomNavigationBarItem(icon: Icon(Icons.emergency_outlined), activeIcon: Icon(Icons.emergency), label: 'Darurat'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    final bool isSelected = _adminSelectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 20),
      title: Text(
        title, 
        style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white10,
      onTap: () {
        setState(() {
          _adminSelectedIndex = index;
        });
        Navigator.pop(context); // Tutup laci geser setelah item ditekan di HP
      },
    );
  }

  String _getAdminMenuTitle(int index) {
    switch (index) {
      case 0: return 'Dasbor Manajemen';
      case 1: return 'Daftar Infrastruktur Sensor';
      case 2: return 'Konfigurasi Ambang Batas';
      case 3: return 'Siaran Peringatan Darurat';
      case 4: return 'Notifikasi & Log Sistem';
      case 5: return 'Laporan Rekapitulasi Data';
      case 6: return 'Manajemen Akses Pengguna';
      default: return 'Admin Panel';
    }
  }
}