import 'package:flutter/material.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildInboxBadge('Total Inbox', '5', Colors.black87),
                const SizedBox(width: 8),
                _buildInboxBadge('Belum Dibaca', '5', Colors.red),
                const SizedBox(width: 8),
                _buildInboxBadge('Alert Aktif', '2', Colors.orange),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNotifyCard('Peringatan Kenaikan Debit Air', 'Status: Waspada\nSaluran: WhatsApp & Push', '17 Mei 2026, 14.20', Colors.orange),
                _buildNotifyCard('Notifikasi Penormalan Level Air', 'Status: Aman\nSaluran: Push Notification', '16 Mei 2026, 09.11', Colors.green),
                _buildNotifyCard('System Alert: Sensor Offline Detected', 'Perangkat SNS-WL-03 terputus', '15 Mei 2026, 23.45', Colors.redAccent),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInboxBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifyCard(String title, String body, String time, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 4, backgroundColor: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.3)),
                const SizedBox(height: 6),
                Text(time, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }
}