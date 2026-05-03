import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ews_appbar.dart';

class DaruratScreen extends StatelessWidget {
  const DaruratScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EWSAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildEmergencyAlert(),
            _buildEmergencyActions(context),
            _buildBeforeCallingTips(),
            _buildSafetyGuide(),
            _buildEmergencyKit(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFFFF5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.statusBahaya, size: 20),
              const SizedBox(width: 8),
              const Text('TINDAKAN CEPAT', style: TextStyle(color: AppTheme.statusBahaya, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Emergency Action Section', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Tombol one-click call berikut memudahkan masyarakat menghubungi layanan darurat saat kondisi kritis.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyActions(BuildContext context) {
    final services = [
      _EmergencyService(
        name: 'BPBD Kota',
        subtitle: 'Nomor prioritas tanggap darurat',
        phone: '117',
        focus: 'Koordinasi kebencanaan wilayah',
        responseTime: 'Target respons 5-10 menit',
        note: 'Gunakan untuk laporan kejadian banjir skala lingkungan/kecamatan.',
        color: AppTheme.statusBahaya,
      ),
      _EmergencyService(
        name: 'Basarnas',
        subtitle: 'Nomor prioritas tanggap darurat',
        phone: '115',
        focus: 'Evakuasi & penyelamatan',
        responseTime: 'Target respons 10-20 menit',
        note: 'Hubungi saat ada korban terjebak atau butuh evakuasi air deras.',
        color: AppTheme.statusBahaya,
      ),
      _EmergencyService(
        name: 'Ambulans',
        subtitle: 'Nomor prioritas tanggap darurat',
        phone: '118',
        focus: 'Bantuan medis darurat',
        responseTime: 'Target respons 10-15 menit',
        note: 'Prioritaskan untuk kondisi medis kritis selama kejadian banjir.',
        color: AppTheme.statusBahaya,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: services.map((s) => _EmergencyCard(service: s)).toList(),
      ),
    );
  }

  Widget _buildBeforeCallingTips() {
    final tips = [
      'Sebutkan lokasi detail (alamat/patokan terdekat).',
      'Jelaskan kondisi air (tinggi, arus, akses jalan).',
      'Informasikan jumlah warga terdampak.',
      'Simpan daya baterai ponsel untuk komunikasi lanjutan.',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.statusWaspada.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates, color: AppTheme.statusWaspada, size: 18),
              const SizedBox(width: 8),
              const Text('Sebelum Menekan Tombol Darurat',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.statusWaspada)),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: AppTheme.statusWaspada.withAlpha(51), shape: BoxShape.circle),
                  child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.statusWaspada))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSafetyGuide() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FLOOD EDUCATION & FAQ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accentBlue, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Panduan Keselamatan dan Persiapan Darurat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Evacuation guide card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Panduan Evakuasi Saat Status Merah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                ...[
                  'Pantau notifikasi resmi dan ikuti instruksi petugas saat status merah aktif.',
                  'Matikan listrik utama rumah dan amankan dokumen penting ke tempat kedap air.',
                  'Bawa tas siaga, bantu lansia/anak, lalu bergerak ke titik evakuasi terdekat.',
                  'Tetap di jalur aman dan hindari menerobos arus banjir atau kabel listrik terbuka.',
                ].asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: AppTheme.accentBlue, borderRadius: BorderRadius.circular(6)),
                        child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, height: 1.4))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyKit() {
    final items = [
      'Dokumen penting (KTP, KK, surat berharga)',
      'Obat pribadi, P3K, dan masker',
      'Air minum, makanan siap saji, perlengkapan bayi',
      'Senter, powerbank, peluit, dan baterai cadangan',
      'Pakaian ganti dan perlengkapan kebersihan dasar',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daftar Barang Darurat Wajib', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(color: AppTheme.accentBlue, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 13, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _EmergencyService {
  final String name, subtitle, phone, focus, responseTime, note;
  final Color color;

  const _EmergencyService({
    required this.name,
    required this.subtitle,
    required this.phone,
    required this.focus,
    required this.responseTime,
    required this.note,
    required this.color,
  });
}

class _EmergencyCard extends StatelessWidget {
  final _EmergencyService service;

  const _EmergencyCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(service.subtitle, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fokus layanan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppTheme.textGrey)),
                          Text(service.focus, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimasi respons', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppTheme.textGrey)),
                          Text(service.responseTime, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Hubungi ${service.name}'),
                    content: Text('Apakah Anda ingin menghubungi ${service.phone}?\n\n${service.note}'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusBahaya, foregroundColor: Colors.white),
                        child: Text('Hubungi ${service.phone}'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.phone, size: 16),
              label: Text('Hubungi ${service.phone}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusBahaya,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(service.note, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }
}
