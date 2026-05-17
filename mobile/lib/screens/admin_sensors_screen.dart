import 'package:flutter/material.dart';

class AdminSensorsScreen extends StatelessWidget {
  const AdminSensorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> dummySensors = [
      {'code': 'SNS-WL-01', 'name': 'Sensor Tinggi Air Bendungan A', 'type': 'WATER_LEVEL', 'status': 'ONLINE'},
      {'code': 'SNS-RF-02', 'name': 'Sensor Curah Hujan Hulu Sungai', 'type': 'RAINFALL', 'status': 'ONLINE'},
      {'code': 'SNS-WL-03', 'name': 'Sensor Tinggi Air Pintu Air B', 'type': 'WATER_LEVEL', 'status': 'OFFLINE'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dummySensors.length,
        itemBuilder: (context, index) {
          final s = dummySensors[index];
          final isOnline = s['status'] == 'ONLINE';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['code']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0066FF), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('Tipe Perangkat: ${s['type']!}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(6)),
                  child: Text(s['status']!, style: TextStyle(color: isOnline ? const Color(0xFF10B981) : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0066FF),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {},
      ),
    );
  }
}