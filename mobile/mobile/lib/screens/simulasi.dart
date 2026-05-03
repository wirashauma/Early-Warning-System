import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class SimulasiPage extends StatefulWidget {
  const SimulasiPage({super.key});

  @override
  State<SimulasiPage> createState() => _SimulasiPageState();
}

class _SimulasiPageState extends State<SimulasiPage> {

  final AudioPlayer player = AudioPlayer();

  void playAlarm() async {
    await player.play(AssetSource('alarm.mp3'));
  }

  Widget alarm(String text){
    return Column(
      children: [

        ElevatedButton(
          onPressed: (){
            playAlarm();
          },

          child: SizedBox(
            width: 260,
            child: Center(child: Text(text)),
          ),
        ),

        const Icon(
          Icons.notifications_active,
          size:40,
          color: Colors.red,
        ),

        const SizedBox(height:25),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),

      child: Column(
        children: [

          const SizedBox(height:20),

          const Text(
            "HALAMAN SIMULASI ALARM",
            style: TextStyle(
              fontSize:12,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height:30),

          alarm("Alarm statistik air deras"),
          alarm("Alarm ketinggian air meningkat"),
          alarm("Alarm kelembaban tanah tidak normal"),
          alarm("Alarm durasi hujan meningkat"),
        ],
      ),
    );
  }
}