import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  final bool _agreeTerms = false;

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
        const SnackBar(
          content: Text('Anda harus menyetujui syarat & ketentuan'),
        ),
      );
      return;
    }
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
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
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithGoogle();
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
          content: Text(authProvider.errorMessage ?? 'Google sign-up gagal'),
          backgroundColor: AppTheme.statusBahaya,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildFormCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios, size: 14, color: Colors.black87),
        label: const Text(
          'Kembali',
          style: TextStyle(color: Colors.black87, fontSize: 14),
        ),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Logo gambar
            Image.asset('assets/images/logo.png', width: 60, height: 60),
            const SizedBox(height: 8),
            Text(
              'DAFTAR AKUN EWS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Daftar Akun Baru',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Lengkapi formulir di bawah untuk bergabung.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Error banner
            if (context.watch<AuthProvider>().errorMessage != null)
              ErrorBanner(message: context.watch<AuthProvider>().errorMessage!),

            // Google button
            GoogleSignInButton(
              onPressed: _handleGoogleRegister,
              isLoading: context.watch<AuthProvider>().isLoading,
            ),
            const SizedBox(height: 20),

            // Divider ATAU
            Row(
              children: [
                Expanded(
                  child: Divider(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ATAU',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Form fields
            AuthTextField(
              label: 'NAMA LENGKAP',
              hint: 'Nama lengkap',
              controller: _nameCtrl,
              prefixIcon: Icons.person_outline,
              validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'INSTANSI / ORGANISASI',
              hint: 'Contoh: BPBD Padang',
              controller: _addressCtrl,
              prefixIcon: Icons.business_outlined,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'EMAIL',
              hint: 'nama@email.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (v) => v!.contains('@') ? null : 'Email tidak valid',
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'PASSWORD',
              hint: 'Minimal 8 karakter',
              controller: _passCtrl,
              isPassword: true,
              prefixIcon: Icons.lock_outline,
              validator: (v) =>
                  v!.length < 6 ? 'Password terlalu pendek' : null,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'KONFIRMASI PASSWORD',
              hint: 'Ulangi password',
              controller: _confirmPassCtrl,
              isPassword: true,
              prefixIcon: Icons.lock_reset,
              validator: (v) =>
                  v != _passCtrl.text ? 'Password tidak cocok' : null,
            ),
            const SizedBox(height: 24),

            // Tombol Daftar
            AuthButton(
              label: 'Daftar',
              onPressed: _handleRegister,
              isLoading: context.watch<AuthProvider>().isLoading,
            ),
            const SizedBox(height: 16),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Sudah punya akun? ', style: TextStyle(color: Colors.grey)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Login di sini',
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}