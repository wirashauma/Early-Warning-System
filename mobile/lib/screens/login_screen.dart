import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/auth_provider.dart';
import '../widgets/auth_widgets.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

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
  final _auth = AuthProvider();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _auth.login(_emailCtrl.text, _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      widget.onLoginSuccess?.call();
      Navigator.pop(context, true);
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
                          AuthTextField(
                            label: 'Alamat Email',
                            hint: 'contoh@email.com',
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
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(() => _rememberMe = v!),
                                      activeColor: AppTheme.primaryBlue,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Ingat saya', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                                },
                                child: const Text('Lupa password?', style: TextStyle(color: AppTheme.accentBlue, fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          AuthButton(
                            label: 'Masuk',
                            onPressed: _handleLogin,
                            isLoading: _auth.isLoading,
                          ),
                          const SizedBox(height: 16),
                          const DividerWithText(text: 'atau'),
                          const SizedBox(height: 16),
                          // Demo quick login
                          _buildDemoLogin(),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Belum punya akun? ', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => RegisterScreen(onLoginSuccess: widget.onLoginSuccess)),
                                ),
                                child: const Text('Daftar Sekarang',
                                    style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ],
                          ),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
        ),
      ),
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Selamat Datang Kembali', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Masuk ke akun EWS Flood Guard Anda', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDemoLogin() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.accentBlue, size: 16),
              SizedBox(width: 6),
              Text('Akun Demo', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          _demoBtn('Login sebagai Admin', 'admin@ewsfloodguard.id', 'admin123'),
          const SizedBox(height: 8),
          _demoBtn('Login sebagai User', 'wira@gmail.com', 'wira123'),
        ],
      ),
    );
  }

  Widget _demoBtn(String label, String email, String pass) {
    return GestureDetector(
      onTap: () {
        _emailCtrl.text = email;
        _passCtrl.text = pass;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline, size: 16, color: AppTheme.textGrey),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textGrey),
          ],
        ),
      ),
    );
  }
}
