import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/auth_service.dart';
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
    final isLoggedIn = AuthService.instance.isLoggedIn;
    final user = AuthService.instance.currentUser;

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
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.textDark),
                onPressed: () {
                  // INI KUNCINYA: Navigasi ke halaman notifikasi
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotifikasiPage()),
                  );
                },
              ),
              // Badge Merah (Titik Notifikasi)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.statusBahaya,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        if (isLoggedIn)
          GestureDetector(
            onTap: () {
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
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
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
          )
        else
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    onLoginSuccess: () => onRefresh?.call(),
                  ),
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