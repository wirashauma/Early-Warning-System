import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _auth = AuthProvider();
  String? _successMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleForgot() async {
    if (!_formKey.currentState!.validate()) return;
    final msg = await _auth.forgotPassword(_emailCtrl.text);
    if (!mounted) return;
    if (msg != null) {
      setState(() => _successMessage = msg);
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
                child: ListenableBuilder(
                  listenable: _auth,
                  builder: (context, _) {
                    if (_successMessage != null) return _buildSuccessState();
                    return _buildForm();
                  },
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
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
        ),
      ),
      child: Column(
        children: [
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.accentBlue, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.lock_reset, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          const Text('Lupa Password?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text(
            'Jangan khawatir! Masukkan email Anda\ndan kami akan kirimkan link reset password.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_auth.errorMessage != null) ...[
            ErrorBanner(message: _auth.errorMessage!),
            const SizedBox(height: 16),
          ],
          const Text(
            'Masukkan email yang terdaftar pada akun Anda. Kami akan mengirimkan instruksi untuk mereset password.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
          AuthButton(
            label: 'Kirim Link Reset Password',
            onPressed: _handleForgot,
            isLoading: _auth.isLoading,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Kembali ke Login'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.textGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.statusNormal.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined, color: AppTheme.statusNormal, size: 48),
        ),
        const SizedBox(height: 20),
        const Text('Email Terkirim!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SuccessBanner(message: _successMessage!),
        const SizedBox(height: 16),
        const Text(
          'Periksa inbox email Anda dan ikuti instruksi untuk mereset password. Jika tidak menerima email dalam 5 menit, cek folder spam Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 32),
        AuthButton(
          label: 'Kembali ke Login',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _successMessage = null;
            _auth.clearError();
          }),
          child: const Text('Kirim Ulang Email', style: TextStyle(color: AppTheme.accentBlue)),
        ),
      ],
    );
  }
}
