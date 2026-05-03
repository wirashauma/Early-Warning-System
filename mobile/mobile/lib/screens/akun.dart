import 'package:flutter/material.dart';
import 'login.dart';

class AkunPage extends StatelessWidget {
  const AkunPage({super.key});

  Widget tombol(String text){
    return Container(
      width: 220,
      margin: const EdgeInsets.only(top:15),
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
      ),

      child: Center(child: Text(text)),
    );
  }

  void showSetting(BuildContext context){

    showModalBottomSheet(
      context: context,

      builder: (context){

        return ListTile(
          leading: const Icon(Icons.logout,color: Colors.red),
          title: const Text("Logout"),

          onTap: (){
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context)=> const LoginPage(),
              ),
              (route) => false,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),

      child: Column(
        children: [

          Align(
            alignment: Alignment.topRight,

            child: ElevatedButton(
              onPressed: (){
                showSetting(context);
              },

              child: const Text("SETTING"),
            ),
          ),

          const SizedBox(height:20),

          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person,size:50,color: Colors.white),
          ),

          const SizedBox(height:20),

          const Text(
            "Username",
            style: TextStyle(fontSize:18),
          ),

          const Text(
            "Alamat",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height:30),

          tombol("VERSI APLIKASI"),
          tombol("TENTANG DEV"),
        ],
      ),
    );
  }
}