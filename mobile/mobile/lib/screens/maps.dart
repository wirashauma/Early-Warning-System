import 'package:flutter/material.dart';

class MapsPage extends StatelessWidget {
  const MapsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),

      child: Column(
        children: [

          Container(
            height: 200,
            color: Colors.blue[50],

            child: const Center(
              child: Text("Maps User (Keberadaan User)"),
            ),
          ),

          const SizedBox(height:20),

          Container(
            height: 200,
            color: Colors.blue[50],

            child: const Center(
              child: Text("Jarak User Dengan Objek"),
            ),
          )
        ],
      ),
    );
  }
}