import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        final role = auth.userRole.toString().toUpperCase();
        final isAdmin = role == 'ADMIN' || role == 'SUPER_ADMIN' || role.contains('ADMIN');
        Navigator.pushReplacementNamed(context, isAdmin ? '/admin' : '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.water_drop, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('EWS Flood Guard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Sistem Peringatan Dini Banjir',
                style: TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
