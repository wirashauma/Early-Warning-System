import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.login(_emailCtrl.text, _passCtrl.text);
    
    if (!mounted) return;
    if (ok) {
      // FIX UTAMA: Cukup panggil callback dari main.dart.
      // Hapus Navigator.pop dari sini agar tidak menabrak rute /home atau /admin.
      widget.onLoginSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalAuth = context.watch<AuthProvider>();

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
                  child: Column(
                    children: [
                      if (globalAuth.errorMessage != null)
                        ErrorBanner(message: globalAuth.errorMessage!),
                      AuthTextField(
                        label: 'Alamat Email',
                        hint: 'Masukkan email Anda',
                        controller: _emailCtrl,
                        prefixIcon: Icons.email_outlined,
                        validator: (v) => v!.isEmpty ? 'Email wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Password',
                        hint: 'Masukkan password Anda',
                        controller: _passCtrl,
                        isPassword: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (v) => v!.isEmpty ? 'Password wajib diisi' : null,
                      ),
                      
                      // Link Lupa Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          ),
                          child: const Text('Lupa Password?', style: TextStyle(color: AppTheme.accentBlue)),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      AuthButton(
                        label: 'Masuk',
                        onPressed: _handleLogin,
                        isLoading: globalAuth.isLoading,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppTheme.textGrey.withValues(alpha: 0.3))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('atau', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: AppTheme.textGrey.withValues(alpha: 0.3))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GoogleSignInButton(
                        onPressed: () async {
                          final ok = await globalAuth.loginWithGoogle();
                          if (!mounted) return;
                          if (ok) {
                            // FIX UTAMA: Hapus juga navigator.pop dari tombol Google
                            widget.onLoginSuccess?.call();
                          }
                        },
                        isLoading: globalAuth.isLoading,
                      ),
                      const SizedBox(height: 24),
                      _buildQuickLogin(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Belum punya akun? ', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RegisterScreen(onLoginSuccess: widget.onLoginSuccess)),
                            ),
                            child: const Text(
                              'Daftar Sekarang',
                              style: TextStyle(
                                color: AppTheme.primaryBlue, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 14
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
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
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
        ),
      ),
      child: const Column(
        children: [
          Icon(Icons.water_drop, color: Colors.white, size: 48),
          SizedBox(height: 16),
          Text('Login', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}