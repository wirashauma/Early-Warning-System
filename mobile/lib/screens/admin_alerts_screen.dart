import 'package:flutter/material.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  String _selectedLevel = 'Waspada';
  bool _sendWA = true;
  bool _sendPush = true;
  bool _sendEmail = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Siarkan Peringatan Manual (Broadcast)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedLevel,
            decoration: const InputDecoration(labelText: 'Tingkat Bahaya', border: OutlineInputBorder()),
            items: ['Waspada', 'Bahaya', 'Evakuasi'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (val) => setState(() => _selectedLevel = val!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: 'Peringatan: Kenaikan volume air terdeteksi di pintu air hulu.',
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Pesan Peringatan', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(title: const Text('Kirim via WhatsApp Gateway', style: TextStyle(fontSize: 13)), value: _sendWA, onChanged: (v) => setState(() => _sendWA = v!)),
          CheckboxListTile(title: const Text('Kirim via Push Notification App', style: TextStyle(fontSize: 13)), value: _sendPush, onChanged: (v) => setState(() => _sendPush = v!)),
          CheckboxListTile(title: const Text('Kirim via Email Blast', style: TextStyle(fontSize: 13)), value: _sendEmail, onChanged: (v) => setState(() => _sendEmail = v!)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 45)),
            child: const Text('SIARKAN SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          const Text('Riwayat Broadcast Kebencanaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          _buildHistoryItem('Waspada', 'Pesan disiarkan ke semua warga sektor 1', '14 Mei 2026', Colors.orange),
          _buildHistoryItem('Evakuasi', 'Perintah evakuasi mandiri RT03/RW04', '11 Mei 2026', Colors.red),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String tag, String msg, String date, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.campaign, color: color),
        title: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text(date, style: const TextStyle(fontSize: 11)),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(tag, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
      ),
    );
  }
}