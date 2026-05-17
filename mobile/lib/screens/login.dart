import 'package:flutter/material.dart';
import '../models/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.instance.login(email.text.trim(), password.text);

    setState(() {
      _isLoading = false;
    });

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Login gagal.')),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'LOGIN',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _handleLogin(context),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Belum punya akun? '),
                GestureDetector(
                  child: const Text(
                    'Register',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/register');
                  },
                )
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Quick Login (Dev):',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickLoginBtn(context, 'Admin 1', 'admin@ews.com', 'Admin123!'),
                _quickLoginBtn(context, 'Admin 2', 'admin2@ews.com', 'AdminOps123!'),
                _quickLoginBtn(context, 'User 1', 'user1@ews.com', 'User12345!'),
                _quickLoginBtn(context, 'User 2', 'user2@ews.com', 'User12345!'),
                _quickLoginBtn(context, 'User 3', 'user3@ews.com', 'User12345!'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickLoginBtn(BuildContext context, String label, String emailVal, String passVal) {
    return InkWell(
      onTap: _isLoading
          ? null
          : () {
              email.text = emailVal;
              password.text = passVal;
              _handleLogin(context);
            },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
