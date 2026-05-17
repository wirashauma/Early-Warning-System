import 'package:flutter/material.dart';
import '../models/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const RegisterScreen({super.key, this.onLoginSuccess});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  final _auth = AuthProvider();
  bool _agreeTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus menyetujui syarat & ketentuan')),
      );
      return;
    }
    final success = await _auth.register(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
      password: _passCtrl.text,
      address: _addressCtrl.text,
    );
    if (!mounted) return;
    if (success) {
      widget.onLoginSuccess?.call();
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi Berhasil!'),
          backgroundColor: AppTheme.statusNormal,
        ),
      );
    }
  }

  Future<void> _handleGoogleRegister() async {
    final success = await _auth.loginWithGoogle();
    if (!mounted) return;
    if (success) {
      widget.onLoginSuccess?.call();
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi & Login dengan Google Berhasil!'),
          backgroundColor: AppTheme.statusNormal,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_auth.errorMessage ?? 'Google sign-up gagal'),
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
                        children: [
                          if (_auth.errorMessage != null)
                            ErrorBanner(message: _auth.errorMessage!),
                          AuthTextField(
                            label: 'Nama Lengkap',
                            hint: 'Masukkan nama Anda',
                            controller: _nameCtrl,
                            prefixIcon: Icons.person_outline,
                            validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            label: 'Email',
                            hint: 'contoh@email.com',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (v) => v!.contains('@') ? null : 'Email tidak valid',
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            label: 'Nomor Telepon',
                            hint: '08xxxxxxxxxx',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                            validator: (v) => v!.length < 10 ? 'Nomor tidak valid' : null,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            label: 'Alamat (Opsional)',
                            hint: 'Masukkan alamat tinggal',
                            controller: _addressCtrl,
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            label: 'Password',
                            hint: 'Minimal 6 karakter',
                            controller: _passCtrl,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline,
                            validator: (v) => v!.length < 6 ? 'Password terlalu pendek' : null,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            label: 'Konfirmasi Password',
                            hint: 'Ulangi password Anda',
                            controller: _confirmPassCtrl,
                            isPassword: true,
                            prefixIcon: Icons.lock_reset,
                            validator: (v) => v != _passCtrl.text ? 'Password tidak cocok' : null,
                          ),
                          const SizedBox(height: 20),
                          _buildTermsCheckbox(),
                          const SizedBox(height: 24),
                          AuthButton(
                            label: 'Buat Akun',
                            onPressed: _handleRegister,
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
                            onPressed: _handleGoogleRegister,
                            isLoading: _auth.isLoading,
                          ),
                          const SizedBox(height: 24),
                          _buildFooter(),
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
        gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)]),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Icon(Icons.person_add_outlined, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text('Daftar Akun', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeTerms,
          onChanged: (v) { if(v != null) setState(() => _agreeTerms = v); },
        ),
        const Expanded(
          child: Text('Saya menyetujui Syarat & Ketentuan EWS Flood Guard', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Sudah punya akun? '),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text('Masuk', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}