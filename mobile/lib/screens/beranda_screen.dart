import 'package:flutter/material.dart';
import '../widgets/ews_appbar.dart';
import 'main_navigation.dart';
import '../theme/app_theme.dart';

class BerandaScreen extends StatelessWidget {
  final VoidCallback? onRefresh;
  final ValueChanged<int>? onNavigate; // 0=Beranda,1=Dashboard,2=Status,3=Darurat,4=Edukasi
  const BerandaScreen({super.key, this.onRefresh, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EWSAppBar(onRefresh: onRefresh),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeroSection(),
            _StatsSection(),
            _FeaturesSection(),
            _HowItWorksSection(),
            _FooterSection(),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF0F4C75)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PLATFORM EARLY WARNING SYSTEM',
                  style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kelola Respons Banjir Lebih Cepat, Tepat, dan Terkoordinasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sistem peringatan dini berbasis sensor untuk membantu masyarakat memantau potensi banjir, memahami tingkat risiko, dan mengambil tindakan cepat saat kondisi darurat.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => navIndexNotifier.value = 1,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Lihat Dashboard Real-Time'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => navIndexNotifier.value = 3,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Tindakan Darurat'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Data real-time', 'Alert otomatis', 'Peta risiko interaktif'].map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(51)),
                    ),
                    child: Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = [
      {'value': '3', 'label': 'Sensor Aktif', 'icon': Icons.sensors},
      {'value': '24/7', 'label': 'Monitoring', 'icon': Icons.access_time},
      {'value': '<5 mnt', 'label': 'Respons Alert', 'icon': Icons.notifications_active},
      {'value': '99%', 'label': 'Uptime Sistem', 'icon': Icons.cloud_done},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          const Text('Statistik Sistem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: stats.map((s) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(s['icon'] as IconData, color: AppTheme.primaryBlue, size: 24),
                    const SizedBox(height: 8),
                    Text(s['value'] as String,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    Text(s['label'] as String,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'icon': Icons.sensors,
        'title': 'Sensor Real-Time',
        'desc': 'Pantau ketinggian air, curah hujan, dan kecepatan arus sungai secara langsung.',
        'color': AppTheme.accentBlue,
      },
      {
        'icon': Icons.notifications_active,
        'title': 'Alert Otomatis',
        'desc': 'Notifikasi dini dikirim ke masyarakat ketika level air melewati batas aman.',
        'color': AppTheme.statusWaspada,
      },
      {
        'icon': Icons.map,
        'title': 'Peta Risiko Interaktif',
        'desc': 'Visualisasi lokasi sensor, zona risiko, dan titik evakuasi terdekat.',
        'color': AppTheme.statusSiaga,
      },
      {
        'icon': Icons.phone_in_talk,
        'title': 'Tindakan Darurat',
        'desc': 'One-click call ke BPBD, Basarnas, dan layanan darurat lainnya.',
        'color': AppTheme.statusBahaya,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fitur Utama', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accentBlue, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Semua yang Anda Butuhkan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...features.map((f) => _FeatureCard(
            icon: f['icon'] as IconData,
            title: f['title'] as String,
            desc: f['desc'] as String,
            color: f['color'] as Color,
          )),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _FeatureCard({required this.icon, required this.title, required this.desc, required this.color});

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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      {'num': '1', 'title': 'Sensor Membaca Data', 'desc': 'Sensor IoT mengukur ketinggian air, curah hujan, dan arus sungai secara real-time setiap menit.'},
      {'num': '2', 'title': 'Sistem Menganalisis', 'desc': 'Data dikirim ke server dan dianalisis untuk menentukan level status berdasarkan ambang batas.'},
      {'num': '3', 'title': 'Alert Dikirim', 'desc': 'Jika status meningkat, notifikasi otomatis dikirim ke admin dan masyarakat sekitar.'},
      {'num': '4', 'title': 'Tindakan Cepat', 'desc': 'Masyarakat mengakses panduan darurat dan menghubungi layanan emergency via satu tombol.'},
    ];

    return Container(
      color: AppTheme.lightBlue,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CARA KERJA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accentBlue, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Dari Sensor ke Tindakan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((e) => _StepItem(
            num: e.value['num']!,
            title: e.value['title']!,
            desc: e.value['desc']!,
            isLast: e.key == steps.length - 1,
          )),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String num, title, desc;
  final bool isLast;

  const _StepItem({required this.num, required this.title, required this.desc, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
              child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: const Color(0xFFBFDBFE)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E3A5F),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EWS Flood Guard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Sistem Peringatan Dini Banjir', style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Platform monitoring real-time untuk membantu admin memantau sensor, memvalidasi alert, dan mempercepat koordinasi respons banjir.',
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.email_outlined, color: Colors.white60, size: 14),
              const SizedBox(width: 8),
              const Text('support@ewsfloodguard.id', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: Colors.white60, size: 14),
              const SizedBox(width: 8),
              const Text('+62 21 555 0199', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white60, size: 14),
              const SizedBox(width: 8),
              const Text('Padang, Sumatera Barat', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('© 2026 EWS Flood Guard. All rights reserved.', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
