import 'package:flutter/material.dart';
import 'maps.dart';
import 'simulasi.dart';
import 'akun.dart';
import 'notifikasi.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  int index = 0;

  final pages = const [
    HomePage(),
    MapsPage(),
    SimulasiPage(),
    AkunPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("EWS Mobile"),
      ),

      body: pages[index],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,

        onTap: (i){
          setState(() {
            index = i;
          });
        },

        items: const [

          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home"
          ),

          BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: "Maps"
          ),

          BottomNavigationBarItem(
              icon: Icon(Icons.warning),
              label: "Simulasi"
          ),

          BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Akun"
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget statistik(String text){
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),

      child: Text(
        "- $text",
        style: const TextStyle(fontSize:18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              const Text(
                "Hi, User 👋",
                style: TextStyle(
                    fontSize:24,
                    fontWeight: FontWeight.bold
                ),
              ),

              IconButton(
                icon: const Icon(Icons.notifications),

                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotifikasiPage(),
                    ),
                  );
                },
              )
            ],
          ),

          const SizedBox(height:20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),

            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                statistik("STATISTIK AIR"),
                statistik("KETINGGIAN AIR"),
                statistik("KELEMBAPAN TANAH"),
                statistik("DURASI HUJAN"),

              ],
            ),
          )
        ],
      ),
    );
  }
}