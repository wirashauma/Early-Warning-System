import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/auth_service.dart';
import '../models/auth_provider.dart';
import '../models/admin_provider.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/notifikasi.dart'; // 1. PASTIKAN IMPORT INI ADA

class EWSAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onRefresh;

  const EWSAppBar({super.key, this.onRefresh});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final user = authProvider.currentUser;

    int unreadCount = 0;
    if (isLoggedIn && user != null) {
      final readAt = user.notificationReadAt;
      final readIds = user.readNotificationIds;
      unreadCount = adminProvider.alertHistory.where((a) {
        if (readIds.contains(a.id)) return false;
        final cutoff = readAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return a.sentAt.isAfter(cutoff);
      }).length;
    }

    return AppBar(
      title: const Text(
        'EWS Flood Guard',
        style: TextStyle(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        // 2. PERBAIKAN: Tombol Notifikasi dengan Navigasi
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.textDark,
                ),
                onPressed: () {
                  // INI KUNCINYA: Navigasi ke halaman notifikasi
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotifikasiPage(),
                    ),
                  ).then((_) => onRefresh?.call());
                },
              ),
              // Badge Merah Dinamis (Titik Notifikasi dengan Angka)
              if (unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.statusBahaya,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (isLoggedIn)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        onLogout: () {
                          onRefresh?.call();
                        },
                      ),
                    ),
                  ).then((_) => onRefresh?.call());
                } else if (val == 'logout') {
                  // perform logout
                  try {
                    // AuthService logout clears tokens and current user
                    AuthService.instance.logout();
                  } catch (_) {}
                  onRefresh?.call();
                  // Navigate to login screen
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'profile', child: Text('Profil')),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AppTheme.primaryBlue,
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user?.name.split(' ').first ?? 'Profil',
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LoginScreen(onLoginSuccess: () => onRefresh?.call()),
                ),
              ).then((_) => onRefresh?.call());
            },
            child: const Text(
              'Login',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
