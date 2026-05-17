import 'package:flutter/material.dart';
import '../models/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'register_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthProvider();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await _auth.login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_auth.errorMessage ?? 'Login gagal. Silakan coba lagi.'),
          backgroundColor: AppTheme.statusBahaya,
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final ok = await _auth.loginWithGoogle();

    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_auth.errorMessage ?? 'Login Google gagal. Silakan coba lagi.'),
          backgroundColor: AppTheme.statusBahaya,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: ListenableBuilder(
                    listenable: _auth,
                    builder: (context, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_auth.errorMessage != null) ...[
                            ErrorBanner(message: _auth.errorMessage!),
                            const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 16),
                          AuthTextField(
                            label: 'Email',
                            hint: 'nama@email.com',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email wajib diisi';
                              if (!v.contains('@')) return 'Format email tidak valid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            label: 'Password',
                            hint: 'Masukkan password Anda',
                            controller: _passCtrl,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password wajib diisi';
                              if (v.length < 6) return 'Password minimal 6 karakter';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          AuthButton(
                            label: 'Masuk',
                            onPressed: _handleLogin,
                            isLoading: _auth.isLoading,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: Divider(color: AppTheme.textGrey.withValues(alpha: 0.3))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('atau', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                              ),
                              Expanded(child: Divider(color: AppTheme.textGrey.withValues(alpha: 0.3))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GoogleSignInButton(
                            onPressed: _handleGoogleLogin,
                            isLoading: _auth.isLoading,
                          ),
                          const SizedBox(height: 24),
                          _buildQuickLogin(),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Belum punya akun? ', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                ),
                                child: const Text('Daftar Sekarang',
                                    style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLogin() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_outlined, color: AppTheme.accentBlue, size: 16),
              const SizedBox(width: 6),
              Text(
                'DEMO LOGIN CEPAT',
                style: TextStyle(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.95),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildQuickLoginChip(
                  label: 'Admin BPBD',
                  icon: Icons.admin_panel_settings_outlined,
                  color: AppTheme.primaryBlue,
                  email: 'admin@ews.com',
                  pass: 'Admin123!',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickLoginChip(
                  label: 'User Warga',
                  icon: Icons.person_outline_outlined,
                  color: AppTheme.accentBlue,
                  email: 'user1@ews.com',
                  pass: 'User12345!',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLoginChip({
    required String label,
    required IconData icon,
    required Color color,
    required String email,
    required String pass,
  }) {
    return OutlinedButton.icon(
      onPressed: () async {
        setState(() {
          _emailCtrl.text = email;
          _passCtrl.text = pass;
        });
        await _handleLogin();
      },
      icon: Icon(icon, size: 15, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11.5,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.white,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.login_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Selamat Datang', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          const Text('EWS Flood Guard', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('Sistem Peringatan Dini Banjir Real-Time', 
            style: TextStyle(color: Colors.white60, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
