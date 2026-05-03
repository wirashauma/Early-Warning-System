import 'package:flutter/material.dart';

class NotifikasiPage extends StatelessWidget {
  const NotifikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("Notifikasi"),
      ),

      body: ListView(
        children: const [

          ListTile(
            leading: Icon(Icons.warning, color: Colors.red),
            title: Text("Potensi Banjir"),
            subtitle: Text("Ketinggian air meningkat."),
          ),

          ListTile(
            leading: Icon(Icons.warning, color: Colors.orange),
            title: Text("Curah Hujan Tinggi"),
            subtitle: Text("Diprediksi hujan lebat."),
          ),

          ListTile(
            leading: Icon(Icons.warning, color: Colors.blue),
            title: Text("Kelembapan Tanah Tinggi"),
            subtitle: Text("Potensi longsor."),
          ),
        ],
      ),
    );
  }
}