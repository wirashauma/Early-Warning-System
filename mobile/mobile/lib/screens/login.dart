import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Text(
              "LOGIN",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: username,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: (){
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },

                child: const Text("Login"),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                const Text("Belum punya akun? "),

                GestureDetector(
                  child: const Text(
                    "Register",
                    style: TextStyle(color: Colors.blue),
                  ),

                  onTap: (){
                    Navigator.pushNamed(context, '/register');
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}