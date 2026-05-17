import 'package:flutter/material.dart';

class AdminThresholdScreen extends StatelessWidget {
  const AdminThresholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Konfigurasi Batas Tinggi Air (Ultrasonic)'),
          const SizedBox(height: 12),
          _buildFormInput('Level Normal Maksimal (cm)', '150'),
          _buildFormInput('Level Waspada Minimal (cm)', '151'),
          _buildFormInput('Level Waspada Maksimal (cm)', '250'),
          _buildFormInput('Level Bahaya Minimal (cm)', '251'),
          const SizedBox(height: 20),
          _buildSectionHeader('Konfigurasi Batas Intensitas Curah Hujan'),
          const SizedBox(height: 12),
          _buildFormInput('Hujan Ringan Maksimal (mm/jam)', '5'),
          _buildFormInput('Hujan Sedang Maksimal (mm/jam)', '20'),
          _buildFormInput('Hujan Lebat Minimal (mm/jam)', '21'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfigurasi ambang batas sukses diperbarui!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF), minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Simpan Perubahan Konfigurasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)));
  }

  Widget _buildFormInput(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        initialValue: value,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        ),
      ),
    );
  }
}