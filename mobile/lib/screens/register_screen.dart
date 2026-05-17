import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/auth_provider.dart';
import '../widgets/auth_widgets.dart';
import 'login_screen.dart';

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
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(_checkPasswordStrength);
  }

  void _checkPasswordStrength() {
    final p = _passCtrl.text;
    int strength = 0;
    if (p.length >= 6) strength++;
    if (p.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(p)) strength++;
    if (RegExp(r'[0-9]').hasMatch(p)) strength++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(p)) strength++;
    setState(() => _passwordStrength = strength);
  }

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
        const SnackBar(content: Text('Anda harus menyetujui syarat & ketentuan'), backgroundColor: AppTheme.statusBahaya),
      );
      return;
    }

    final ok = await _auth.register(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
      institution: _addressCtrl.text.isNotEmpty ? _addressCtrl.text : null,
    );

    if (!mounted) return;
    if (ok) {
      widget.onLoginSuccess?.call();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selamat datang, ${_auth.currentUser?.name ?? ''}! Akun berhasil dibuat.'),
          backgroundColor: AppTheme.statusNormal,
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
                          // Section: Data Pribadi
                          _sectionLabel('Data Pribadi'),
                          const SizedBox(height: 12),
                          AuthTextField(
                            label: 'Nama Lengkap',
                            hint: 'Masukkan nama lengkap Anda',
                            controller: _nameCtrl,
                            prefixIcon: Icons.person_outline,
                            validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),
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
                          const SizedBox(height: 14),
                          AuthTextField(
                            label: 'Nomor Telepon',
                            hint: '08xxxxxxxxxx',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Nomor telepon wajib diisi';
                              if (v.length < 10) return 'Nomor telepon minimal 10 digit';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            label: 'Alamat Tinggal (Opsional)',
                            hint: 'Kelurahan, Kecamatan, Kota',
                            controller: _addressCtrl,
                            prefixIcon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),

                          // Section: Keamanan
                          _sectionLabel('Keamanan Akun'),
                          const SizedBox(height: 12),
                          AuthTextField(
                            label: 'Password',
                            hint: 'Minimal 6 karakter',
                            controller: _passCtrl,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password wajib diisi';
                              if (v.length < 6) return 'Password minimal 6 karakter';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildPasswordStrengthBar(),
                          const SizedBox(height: 14),
                          AuthTextField(
                            label: 'Konfirmasi Password',
                            hint: 'Ulangi password Anda',
                            controller: _confirmPassCtrl,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                              if (v != _passCtrl.text) return 'Password tidak cocok';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Terms
                          _buildTermsCheckbox(),
                          const SizedBox(height: 24),

                          AuthButton(
                            label: 'Buat Akun',
                            onPressed: _handleRegister,
                            isLoading: _auth.isLoading,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Sudah punya akun? ', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => LoginScreen(onLoginSuccess: widget.onLoginSuccess)),
                                ),
                                child: const Text('Masuk',
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
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          const Text('Buat Akun Baru', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          const Text('Bergabung dengan EWS Flood Guard', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          // Progress steps
          _buildStepIndicator(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepDot('Data Pribadi', true),
        Container(width: 32, height: 2, color: Colors.white30),
        _stepDot('Keamanan', true),
        Container(width: 32, height: 2, color: Colors.white30),
        _stepDot('Selesai', false),
      ],
    );
  }

  Widget _stepDot(String label, bool active) {
    return Column(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white30,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: active ? Colors.white : Colors.white30, fontSize: 10)),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: AppTheme.accentBlue, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
      ],
    );
  }

  Widget _buildPasswordStrengthBar() {
    final labels = ['', 'Sangat Lemah', 'Lemah', 'Cukup', 'Kuat', 'Sangat Kuat'];
    final colors = [Colors.grey, AppTheme.statusBahaya, AppTheme.statusSiaga, AppTheme.statusWaspada, AppTheme.statusNormal, AppTheme.statusNormal];

    if (_passCtrl.text.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < _passwordStrength ? colors[_passwordStrength] : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )),
        ),
        const SizedBox(height: 4),
        Text(
          'Kekuatan: ${labels[_passwordStrength.clamp(0, 5)]}',
          style: TextStyle(fontSize: 11, color: colors[_passwordStrength.clamp(0, 5)]),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeTerms,
            onChanged: (v) => setState(() => _agreeTerms = v!),
            activeColor: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: const TextSpan(
              text: 'Saya menyetujui ',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
              children: [
                TextSpan(text: 'Syarat & Ketentuan', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w600)),
                TextSpan(text: ' dan '),
                TextSpan(text: 'Kebijakan Privasi', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w600)),
                TextSpan(text: ' EWS Flood Guard.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
