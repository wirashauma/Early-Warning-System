import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;

      final auth = context.read<AuthProvider>();

      if (auth.isLoggedIn) {
        final role = auth.userRole.toString().toUpperCase();

        final isAdmin =
            role == 'ADMIN' || role == 'SUPER_ADMIN' || role.contains('ADMIN');

        Navigator.pushReplacementNamed(context, isAdmin ? '/admin' : '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  Widget _animatedDot(int index) {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, child) {
        double value = ((_dotController.value * 3) - index).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 12 + (value * 4),
          height: 12 + (value * 4),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.4 + (value * 0.6)) * 255 ~/ 1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withAlpha((value * 0.8) * 255 ~/ 1),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.network(
            'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?auto=format&fit=crop&w=1400&q=80',
            fit: BoxFit.cover,
          ),

          // Overlay lebih terang
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withAlpha(140),
            ),
          ),

          // Gradient Glow
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.15),
                radius: 0.9,
                colors: [Colors.blue.withAlpha(77), Colors.transparent],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF60A5FA).withAlpha(179),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Nama Aplikasi
                    const Text(
                      'EWS Flood Guard',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    const Text(
                      'Sistem Peringatan Dini Banjir',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 90),

                    // Animated White Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _animatedDot(0),
                        _animatedDot(1),
                        _animatedDot(2),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}