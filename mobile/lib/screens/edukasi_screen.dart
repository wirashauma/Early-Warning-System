import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';
import '../widgets/ews_appbar.dart';

class EdukasiScreen extends StatefulWidget {
  const EdukasiScreen({super.key});

  @override
  State<EdukasiScreen> createState() => _EdukasiScreenState();
}

class _EdukasiScreenState extends State<EdukasiScreen> {
  final List<int> _expandedFaqs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EWSAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFloodTypes(),
            const SizedBox(height: 24),
            _buildFAQ(),
            const SizedBox(height: 24),
            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FLOOD EDUCATION & FAQ', style: TextStyle(fontSize: 11, color: Colors.white70, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Edukasi & Panduan\nPenanggulangan Banjir', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3)),
          const SizedBox(height: 8),
          const Text(
            'Pelajari cara memahami sistem peringatan dini, mempersiapkan diri menghadapi banjir, dan langkah tepat saat darurat.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Cara kerja sistem', 'Panduan darurat', 'FAQ', 'Tips aman'].map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 11)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloodTypes() {
    final topics = [
      _EduTopic(
        icon: Icons.sensors,
        title: 'Cara Kerja Sensor EWS',
        desc: 'Sensor ultrasonik mengukur ketinggian air sungai secara real-time dan mengirim data ke server setiap 5 menit untuk dianalisis.',
        color: AppTheme.accentBlue,
      ),
      _EduTopic(
        icon: Icons.notifications_active,
        title: 'Sistem Peringatan Otomatis',
        desc: 'Ketika ketinggian air melampaui ambang batas, sistem secara otomatis mengganti status dan mengirimkan notifikasi kepada pengguna terdaftar.',
        color: AppTheme.statusWaspada,
      ),
      _EduTopic(
        icon: Icons.family_restroom,
        title: 'Persiapan Keluarga',
        desc: 'Setiap keluarga sebaiknya memiliki rencana evakuasi, tas siaga, dan titik kumpul yang disepakati bersama sebelum bencana terjadi.',
        color: AppTheme.statusSiaga,
      ),
      _EduTopic(
        icon: Icons.water_damage,
        title: 'Mengenali Tanda Banjir',
        desc: 'Perhatikan tanda-tanda seperti air sungai keruh, bau tanah basah, suara gemuruh dari hulu, dan naiknya permukaan air secara cepat.',
        color: AppTheme.statusBahaya,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MATERI EDUKASI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accentBlue, letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text('Pelajari Lebih Lanjut', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...topics.map((t) => _EduCard(topic: t)),
      ],
    );
  }

  Widget _buildFAQ() {
    final faqs = [
      _FAQItem('Bagaimana data sensor diperbarui?', 'Data sensor dikirim berkala ke sistem dan ditampilkan hampir real-time pada dashboard publik. Pembaruan terjadi setiap 5 menit sekali.'),
      _FAQItem('Apa peran admin dalam sistem EWS?', 'Admin mengelola sensor, memvalidasi data/alert, dan memastikan informasi darurat dikirim tepat waktu kepada masyarakat.'),
      _FAQItem('Apa yang harus dilakukan saat status Kuning?', 'Siapkan dokumen penting, tas siaga, dan pantau terus pembaruan status dari dashboard maupun petugas setempat.'),
      _FAQItem('Apakah tombol darurat bisa langsung menelepon?', 'Ya, tombol menggunakan fitur one-click call, terutama efektif pada perangkat mobile yang memiliki aplikasi telepon aktif.'),
      _FAQItem('Berapa lama sistem bisa beroperasi tanpa internet?', 'Sensor memiliki penyimpanan lokal sementara. Data akan disinkronkan ketika koneksi pulih. Status terakhir tetap ditampilkan.'),
      _FAQItem('Apakah aplikasi ini tersedia secara offline?', 'Fitur utama memerlukan koneksi internet, namun panduan darurat dan nomor telepon dapat diakses dalam mode offline setelah diunduh.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PERTANYAAN UMUM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accentBlue, letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text('FAQ — Pertanyaan yang Sering Diajukan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...faqs.asMap().entries.map((e) => _FAQCard(
          item: e.value,
          isExpanded: _expandedFaqs.contains(e.key),
          onTap: () => setState(() {
            if (_expandedFaqs.contains(e.key)) {
              _expandedFaqs.remove(e.key);
            } else {
              _expandedFaqs.add(e.key);
            }
          }),
        )),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Butuh Bantuan Lebih Lanjut?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Tim kami siap membantu 24/7 untuk pertanyaan teknis dan laporan darurat.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: 'support@ewsfloodguard.id'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email disalin: support@ewsfloodguard.id'), duration: Duration(seconds: 2)),
                    );
                  },
                  icon: const Icon(Icons.email_outlined, size: 16, color: Colors.white),
                  label: const Text('Email Support', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Hubungi Tim EWS'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📞 +62 21 555 0199'),
                            SizedBox(height: 8),
                            Text('📧 support@ewsfloodguard.id'),
                            SizedBox(height: 8),
                            Text('Jam operasional: 24/7', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Hubungi Kami'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EduTopic {
  final IconData icon;
  final String title, desc;
  final Color color;

  const _EduTopic({required this.icon, required this.title, required this.desc, required this.color});
}

class _EduCard extends StatelessWidget {
  final _EduTopic topic;

  const _EduCard({required this.topic});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: topic.color.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(topic.icon, color: topic.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Text(topic.desc, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQItem {
  final String question, answer;
  const _FAQItem(this.question, this.answer);
}

class _FAQCard extends StatelessWidget {
  final _FAQItem item;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FAQCard({required this.item, required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isExpanded ? AppTheme.accentBlue.withAlpha(77) : const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.question,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isExpanded ? AppTheme.primaryBlue : AppTheme.textDark,
                        )),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.textGrey,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(item.answer, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
