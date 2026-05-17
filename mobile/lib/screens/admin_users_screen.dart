import 'package:flutter/material.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> liveUsers = [
      {'name': 'Admin EWS', 'email': 'admin@ews.com', 'role': 'Admin', 'phone': '6281110000001'},
      {'name': 'Super Admin EWS', 'email': 'superadmin@ews.com', 'role': 'Admin', 'phone': '6281110000001'},
      {'name': 'Admin Operasional EWS', 'email': 'admin2@ews.com', 'role': 'Admin', 'phone': '6281110000002'},
      {'name': 'Petugas Lapangan EWS', 'email': 'officer@ews.com', 'role': 'User', 'phone': '6281110000006'},
      {'name': 'User Warga 1', 'email': 'user1@ews.com', 'role': 'User', 'phone': '6281110000003'},
      {'name': 'User Warga 2', 'email': 'user2@ews.com', 'role': 'User', 'phone': '6281110000004'},
      {'name': 'melon', 'email': 'melon@gmail.com', 'role': 'User', 'phone': '6285741234567'},
      {'name': 'Intani Permadani', 'email': 'intani@gmail.com', 'role': 'User', 'phone': '6289512345678'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildStatBadge('Total Akun', '16', Colors.black87),
                const SizedBox(width: 8),
                _buildStatBadge('Role Admin', '3', const Color(0xFF0066FF)),
                const SizedBox(width: 8),
                _buildStatBadge('Role User', '13', const Color(0xFF10B981)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(alignment: Alignment.centerLeft, child: Text('Daftar Akun Otorisasi Sistem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)))),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: liveUsers.length,
              itemBuilder: (context, index) {
                final u = liveUsers[index];
                final isAdmin = u['role'] == 'Admin';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(u['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: isAdmin ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                                  child: Text(u['role']!, style: TextStyle(color: isAdmin ? const Color(0xFF0066FF) : const Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(u['email']!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            Text('No. WA: ${u['phone']!}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 18), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), onPressed: () {}),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatBadge(String title, String value, Color txtColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: txtColor)),
          ],
        ),
      ),
    );
  }
}