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
    
    // Pastikan metode forgotPassword sudah ada di AuthProvider Anda
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
      // Menambahkan AppBar untuk memudahkan navigasi kembali
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(), // Error "undefined_method" hilang
              Padding(
                padding: const EdgeInsets.all(24),
                child: ListenableBuilder(
                  listenable: _auth,
                  builder: (context, _) {
                    // Logika tampilan sukses atau form
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

  // --- HELPER METHODS (Pastikan berada di DALAM kelas State) ---

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue, 
              borderRadius: BorderRadius.circular(14)
            ),
            child: const Icon(Icons.lock_reset, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          const Text(
            'Lupa Password?', 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
          ),
          const SizedBox(height: 8),
          const Text(
            'Masukkan email Anda dan kami akan kirimkan link reset password.',
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
            'Alamat Email',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          AuthTextField(
            label: 'Email',
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
            label: 'Kirim Link Reset',
            onPressed: _handleForgot, // Memanggil fungsi _handleForgot
            isLoading: _auth.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, color: AppTheme.statusNormal, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Berhasil!', 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        Text(
          _successMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        const SizedBox(height: 24),
        AuthButton(
          label: 'Kembali ke Login',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}