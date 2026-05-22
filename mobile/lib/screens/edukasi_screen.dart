import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/ews_appbar.dart';
import 'main_navigation.dart';

class EdukasiScreen extends StatefulWidget {
  const EdukasiScreen({super.key});
  @override
  State<EdukasiScreen> createState() => _EdukasiScreenState();
}

class _EdukasiScreenState extends State<EdukasiScreen> {
  final Set<int> _expandedFaqs = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EWSAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildLevelGuides(),
            _buildChecklist(),
            _buildDosAndDonts(),
            _buildFAQ(),
            _buildQuickAccess(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PANDUAN USER',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.accentBlue,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pusat Panduan Kesiapsiagaan Banjir',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Informasi diringkas untuk orang awam: baca level notifikasi, ikuti 3 langkah utama, lalu cek daftar aman.',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Quick jump pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _JumpPill(label: 'Aksi Kuning'),
              _JumpPill(label: 'Aksi Oren'),
              _JumpPill(label: 'Aksi Merah'),
              _JumpPill(label: 'Checklist'),
              _JumpPill(label: 'FAQ'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RINGKAS 60 DETIK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Kalau dapat notifikasi:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Cek warna status (Kuning, Oren, Merah).',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                      const Text(
                        '2. Ikuti langkah pada kartu warna yang sama.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                      const Text(
                        '3. Prioritaskan keselamatan keluarga, bukan barang.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.accentBlue.withAlpha(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hubungan dengan Notifikasi Detail',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tombol Buka Tab Panduan pada detail notifikasi akan langsung membawa Anda ke bagian level yang sesuai.',
                        style: TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelGuides() {
    final levels = [
      _LevelGuide(
        color: AppTheme.statusWaspada,
        name: 'Kuning (Waspada)',
        desc: 'Air mulai naik. Ini momen terbaik untuk siap-siap tanpa panik.',
        dos: [
          'Pantau dashboard tiap 10-15 menit.',
          'Siapkan tas siaga (dokumen, obat, charger, air minum).',
          'Pastikan semua anggota keluarga tahu rute keluar rumah.',
        ],
        donts: [
          'Jangan menunggu status naik dulu baru mulai persiapan.',
          'Jangan abaikan notifikasi berulang dari area yang sama.',
        ],
      ),
      _LevelGuide(
        color: AppTheme.statusSiaga,
        name: 'Oren (Siaga)',
        desc: 'Risiko banjir makin tinggi. Fokus ke pra-evakuasi sekarang.',
        dos: [
          'Pindahkan barang berharga ke tempat lebih tinggi.',
          'Siapkan anak, lansia, dan anggota rentan untuk berangkat lebih dulu.',
          'Pastikan jalur evakuasi tidak terhalang.',
        ],
        donts: [
          'Jangan menunda keputusan sampai air masuk rumah.',
          'Jangan sebarkan kabar yang belum pasti.',
        ],
      ),
      _LevelGuide(
        color: AppTheme.statusBahaya,
        name: 'Merah (Bahaya)',
        desc: 'Kondisi kritis. Prioritas utama adalah menyelamatkan jiwa.',
        dos: [
          'Evakuasi segera ke lokasi aman resmi.',
          'Hubungi layanan darurat bila ada yang terjebak atau terluka.',
          'Ikuti instruksi petugas dan jangan menerobos arus air.',
        ],
        donts: [
          'Jangan menyelamatkan barang jika membahayakan diri.',
          'Jangan menunggu konfirmasi kedua bila situasi sudah jelas kritis.',
        ],
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panduan Per Level Notifikasi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Text(
            'Pilih level yang sama dengan notifikasi Anda.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...levels.map((l) => _LevelCard(level: l)),
        ],
      ),
    );
  }

  Widget _buildChecklist() {
    final items = [
      'Dokumen penting (KTP, KK, akta, surat berharga) dalam pelindung tahan air',
      'Obat rutin keluarga, P3K, masker, dan hand sanitizer',
      'Air minum, makanan siap saji, perlengkapan bayi/lansia',
      'Senter, peluit, power bank, baterai cadangan',
      'Pakaian ganti, selimut ringan, perlengkapan kebersihan',
      'Uang tunai secukupnya dan daftar kontak penting',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Checklist Tas Siaga 72 Jam',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Simpan perlengkapan ini di tempat yang mudah dijangkau.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.8,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '– ',
                          style: TextStyle(
                            color: AppTheme.accentBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 11, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDosAndDonts() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Do & Don\'t Saat Evakuasi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Text(
            'Petunjuk singkat ini membantu mengurangi risiko cedera saat proses penyelamatan.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.statusNormal.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.statusNormal.withAlpha(60),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yang Harus Dilakukan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.statusNormal,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...[
                        'Gunakan alas kaki anti-slip saat evakuasi.',
                        'Sampaikan lokasi dengan patokan jelas saat menghubungi darurat.',
                        'Bantu tetangga rentan jika kondisi memungkinkan.',
                        'Pantau pembaruan resmi secara berkala.',
                      ].map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '+ ',
                                style: TextStyle(
                                  color: AppTheme.statusNormal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.statusNormal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.statusBahaya.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.statusBahaya.withAlpha(60),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yang Harus Dihindari',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.statusBahaya,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...[
                        'Jangan melintasi arus banjir deras walau terlihat dangkal.',
                        'Jangan menyalakan listrik di area yang masih basah.',
                        'Jangan menunggu terlalu lama saat status sudah merah.',
                        'Jangan percaya hoaks atau informasi tanpa sumber resmi.',
                      ].map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✕ ',
                                style: TextStyle(
                                  color: AppTheme.statusBahaya,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.statusBahaya,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ() {
    final faqs = [
      {
        'q': 'Bagaimana cara membaca warna status di dashboard?',
        'a':
            'Hijau = Normal (aman), Kuning = Waspada (persiapkan diri), Oren = Siaga (siap evakuasi), Merah = Bahaya (evakuasi segera). Warna berubah otomatis berdasarkan data sensor.',
      },
      {
        'q': 'Kapan saya harus menghubungi kontak darurat?',
        'a':
            'Segera hubungi jika status sudah Oren atau Merah, ada anggota keluarga yang butuh bantuan evakuasi, atau ada orang terjebak/terluka di area terdampak.',
      },
      {
        'q': 'Apakah notifikasi selalu muncul otomatis?',
        'a':
            'Ya, sistem mengirim notifikasi otomatis ketika status sensor berubah ke Kuning, Oren, atau Merah. Pastikan notifikasi aplikasi diaktifkan di pengaturan ponsel Anda.',
      },
      {
        'q': 'Apa informasi minimum saat menelepon layanan darurat?',
        'a':
            'Lokasi (alamat/patokan), kondisi air saat ini, jumlah orang terdampak, dan kebutuhan utama (evakuasi/medis/logistik).',
      },
      {
        'q': 'Jika saya ragu harus evakuasi atau tidak, apa yang dilakukan?',
        'a':
            'Jangan tunggu sampai yakin. Jika status sudah Oren, mulailah bergerak. Lebih baik evakuasi lebih awal dan aman daripada terlambat. Prioritaskan keselamatan jiwa.',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FAQ Cepat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Text(
            'Pertanyaan umum yang paling sering muncul dari pengguna.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...faqs.asMap().entries.map((entry) {
            final i = entry.key;
            final faq = entry.value;
            final isExpanded = _expandedFaqs.contains(i);
            return GestureDetector(
              onTap: () => setState(
                () =>
                    isExpanded ? _expandedFaqs.remove(i) : _expandedFaqs.add(i),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              faq['q']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            isExpanded ? '∧' : 'v',
                            style: const TextStyle(
                              color: AppTheme.accentBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Text(
                          faq['a']!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textGrey,
                            height: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Akses Cepat Fitur User',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const Text(
            'Gunakan halaman terkait berikut untuk mengambil tindakan langsung.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => navIndexNotifier.value = 1,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Buka Dashboard'),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cek Notifikasi'),
              ),
              OutlinedButton(
                onPressed: () => navIndexNotifier.value = 2,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Lihat Peta Sensor'),
              ),
              OutlinedButton(
                onPressed: () => navIndexNotifier.value = 3,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Kontak Darurat'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelGuide {
  final Color color;
  final String name, desc;
  final List<String> dos, donts;
  const _LevelGuide({
    required this.color,
    required this.name,
    required this.desc,
    required this.dos,
    required this.donts,
  });
}

class _LevelCard extends StatelessWidget {
  final _LevelGuide level;
  const _LevelCard({required this.level});

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
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: level.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                level.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: level.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            level.desc,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LAKUKAN SEKARANG',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...level.dos.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.key + 1} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.accentBlue,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.value,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: AppTheme.accentBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HINDARI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...level.donts.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(top: 5, right: 6),
                              decoration: const BoxDecoration(
                                color: AppTheme.textGrey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                d,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: AppTheme.textGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JumpPill extends StatelessWidget {
  final String label;
  const _JumpPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
