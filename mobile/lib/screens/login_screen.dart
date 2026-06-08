import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_provider.dart';
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

    final ok = await authProvider.login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;

    if (ok) {
      widget.onLoginSuccess?.call();
    }
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withAlpha(64),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),

        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Text(
            'EWS FLOOD GUARD',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Masuk Platform',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Akses dashboard monitoring banjir real-time.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalAuth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildLogoSection(),

                    const SizedBox(height: 30),

                    GoogleSignInButton(
                      onPressed: () async {
                        final ok = await globalAuth.loginWithGoogle();

                        if (!mounted) return;

                        if (ok) {
                          widget.onLoginSuccess?.call();
                        }
                      },
                      isLoading: globalAuth.isLoading,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ATAU',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    if (globalAuth.errorMessage != null)
                      ErrorBanner(message: globalAuth.errorMessage!),

                    AuthTextField(
                      label: 'EMAIL',
                      hint: 'nama@email.com',
                      controller: _emailCtrl,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) => v!.isEmpty ? 'Email wajib diisi' : null,
                    ),

                    const SizedBox(height: 18),

                    AuthTextField(
                      label: 'PASSWORD',
                      hint: '********',
                      controller: _passCtrl,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (v) =>
                          v!.isEmpty ? 'Password wajib diisi' : null,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Lupa Password?',
                          style: TextStyle(color: Color(0xFF2563EB)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: AuthButton(
                        label: 'Masuk',
                        onPressed: _handleLogin,
                        isLoading: globalAuth.isLoading,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun? ',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RegisterScreen(
                                  onLoginSuccess: widget.onLoginSuccess,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Daftar sekarang',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}