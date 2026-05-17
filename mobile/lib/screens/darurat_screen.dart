import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ews_appbar.dart';
import 'main_navigation.dart';

class DaruratScreen extends StatelessWidget {
  const DaruratScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EWSAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildServices(context),
            _buildBeforeCallingInfo(),
            _buildQuickFlow(),
            const SizedBox(height: 30), // Padding bawah
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kontak Darurat', 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Gunakan halaman ini saat situasi kritis. Pilih layanan yang tepat dan sampaikan informasi yang jelas agar bantuan datang lebih cepat.',
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.statusBahaya.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.statusBahaya.withAlpha(60)),
                ),
                child: Column(
                  children: [
                    Text('Prioritas saat\nstatus Bahaya',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.statusBahaya, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('Keselamatan jiwa\ndahulu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.statusBahaya, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _NavPill(label: 'Pantau Dashboard', onTap: () => navIndexNotifier.value = 1),
              _NavPill(label: 'Lihat Peta Sensor', onTap: () => navIndexNotifier.value = 2),
              _NavPill(label: 'Buka Panduan', onTap: () => navIndexNotifier.value = 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServices(BuildContext context) {
    final services = [
      _Service('Ambulans', '118', 'Prioritas', AppTheme.statusBahaya,
          'Pertolongan medis darurat untuk korban luka, sesak, atau kondisi gawat.',
          'Secepat mungkin sesuai antrian darurat',
          'Sampaikan kondisi pasien, usia, gejala utama, dan akses kendaraan.'),
      _Service('Basarnas', '115', 'Prioritas', AppTheme.statusSiaga,
          'Pencarian dan penyelamatan korban pada kondisi arus/akses berbahaya.',
          'Prioritas tinggi untuk kondisi kritis',
          'Hubungi jika ada korban terjebak, hanyut, atau butuh rescue segera.'),
      _Service('BPBD Kota Padang', '117', 'Prioritas', AppTheme.accentBlue,
          'Koordinasi tanggap bencana, evakuasi wilayah terdampak, dan aktivasi posko.',
          '± 5-15 menit (tergantung akses lapangan)',
          'Cocok dihubungi saat tinggi air naik cepat dan butuh koordinasi wilayah.'),
      _Service('Polisi', '110', 'Prioritas', const Color(0xFF7C3AED),
          'Pengamanan lokasi, pengaturan lalu lintas, dan dukungan evakuasi.',
          'Sesuai prioritas kejadian lapangan',
          'Hubungi jika perlu pengamanan area, rekayasa lalu lintas, atau dukungan keamanan.'),
      _Service('RS Umum Daerah', '119', 'Prioritas', const Color(0xFF0D9488),
          'Rujukan medis lanjutan dan penanganan kegawatdaruratan fasilitas kesehatan.',
          'Bergantung kapasitas rumah sakit',
          'Hubungi untuk koordinasi rujukan pasien banjir dan ketersediaan layanan.'),
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Layanan Darurat Prioritas', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Tekan tombol panggil sesuai kebutuhan utama yang sedang terjadi.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
          const SizedBox(height: 12),
          ...services.map((s) => _ServiceCard(service: s)),
        ],
      ),
    );
  }

  Widget _buildBeforeCallingInfo() {
    final tips = [
      'Sebutkan lokasi detail (alamat, patokan terdekat, atau titik Google Maps).',
      'Jelaskan kondisi saat ini: tinggi air, arus, akses jalan, dan cuaca.',
      'Informasikan jumlah warga terdampak dan kelompok rentan (anak/lansia/disabilitas).',
      'Sampaikan kebutuhan paling mendesak: evakuasi, medis, logistik, atau penyelamatan.',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informasi yang Harus Disiapkan Saat Menelepon',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.statusSiaga)),
          const SizedBox(height: 6),
          Text('Semakin jelas informasi yang kamu sampaikan, semakin cepat tim dapat menentukan tindakan.',
              style: TextStyle(color: AppTheme.statusSiaga, fontSize: 12)),
          const SizedBox(height: 12),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5, right: 10),
                  decoration: const BoxDecoration(color: AppTheme.accentBlue, shape: BoxShape.circle)),
              Expanded(child: Text(t, style: const TextStyle(fontSize: 13, height: 1.4))),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildQuickFlow() {
    final steps = [
      'Cek sensor paling berisiko di Dashboard/Peta.',
      'Hubungi layanan darurat yang paling relevan.',
      'Ikuti arahan petugas dan prioritaskan evakuasi aman.',
    ];

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alur Tindakan Cepat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: AppTheme.accentBlue.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text('${e.key + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentBlue, fontSize: 13))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, height: 1.4))),
            ]),
          )),
        ],
      ),
    );
  }
}

class _Service {
  final String name, phone, badge, focus, response, note;
  final Color color;
  const _Service(this.name, this.phone, this.badge, this.color, this.focus, this.response, this.note);
}

class _ServiceCard extends StatelessWidget {
  final _Service service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: service.color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: service.color.withAlpha(80)),
              ),
              child: Text(service.badge, style: TextStyle(color: service.color, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 4),
          const Text('Nomor Darurat', style: TextStyle(color: AppTheme.textGrey, fontSize: 11)),
          Text(service.phone, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Fokus layanan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textGrey)),
                Text(service.focus, style: const TextStyle(fontSize: 12)),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Estimasi respons', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textGrey)),
                Text(service.response, style: const TextStyle(fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog( // Menggunakan dialogCtx agar tidak konflik
                  title: Text('Hubungi ${service.name}'),
                  content: Text('Apakah Anda ingin menghubungi ${service.phone}?\n\n${service.note}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx), 
                      child: const Text('Batal')
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Logika panggil telepon (Gunakan url_launcher)
                        Navigator.pop(dialogCtx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: service.color, 
                        foregroundColor: Colors.white
                      ),
                      child: Text('Hubungi ${service.phone}'),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.phone, size: 16),
              label: Text('Hubungi ${service.phone}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: service.color,
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

class _NavPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFF8FAFC),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}