import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirm = TextEditingController();

  bool passValid = false;
  bool confirmValid = false;

  void checkPassword(){
    setState(() {
      passValid = password.text.length >= 6;
      confirmValid = confirm.text == password.text && confirm.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    password.addListener(checkPassword);
    confirm.addListener(checkPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("Register"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text("Username"),
            const SizedBox(height: 8),

            TextField(
              controller: username,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Password"),
            const SizedBox(height: 8),

            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: passValid
                    ? const Icon(Icons.check,color: Colors.blue)
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            const Text("Konfirmasi Password"),
            const SizedBox(height: 8),

            TextField(
              controller: confirm,
              obscureText: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: confirmValid
                    ? const Icon(Icons.check,color: Colors.blue)
                    : null,
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: SizedBox(
                width: 150,
                height: 50,

                child: ElevatedButton(
                  onPressed: (){

                    if(password.text != confirm.text){
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Password tidak sama"),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);
                  },

                  child: const Text("Daftar"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}