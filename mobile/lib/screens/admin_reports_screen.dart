import 'package:flutter/material.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: 'Semua Sensor',
                  decoration: const InputDecoration(labelText: 'Pilih Sensor', border: OutlineInputBorder()),
                  items: ['Semua Sensor', 'SNS-WL-01', 'SNS-RF-02'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) {},
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '2026-05-11 s.d 2026-05-17',
                  decoration: const InputDecoration(labelText: 'Rentang Tanggal Pencarian', suffixIcon: Icon(Icons.date_range), border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                  label: const Text('Unduh PDF', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.grid_on_outlined, size: 16, color: Colors.white),
                  label: const Text('Unduh Excel', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text('Tidak ada data logs pada rentang filter ini.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}