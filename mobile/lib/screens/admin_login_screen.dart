import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Dibutuhkan untuk context.read
import '../localization/app_localizations.dart';
import '../models/auth_provider.dart'; 
import '../models/admin_provider.dart'; 

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  // 1. Deklarasikan Controller dan State Variables di sini
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // 2. Fungsi login dimasukkan ke dalam lingkup State agar bisa mengakses setState dan context
  Future<void> _handleAdminLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = context.t('emailPasswordRequired');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        final adminProvider = context.read<AdminProvider>();
        final userId = authProvider.currentUser?.id ?? '';

        await adminProvider.checkAdminRole(userId);

        if (!mounted) return;

        if (adminProvider.isAdmin) {
          Navigator.pushReplacementNamed(
            context,
            '/admin',
          );
        } else {
          setState(() {
            _errorMessage = context.t('notAdminError');
          });
          authProvider.logout();
        }
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Login gagal';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 3. Jangan lupa bersihkan controller saat widget dihancurkan
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('adminLoginTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: context.t('email')),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: context.t('password')),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleAdminLogin, // Fungsi dipanggil di sini
                    child: Text(context.t('loginButton')),
                  ),
          ],
        ),
      ),
    );
  }
}