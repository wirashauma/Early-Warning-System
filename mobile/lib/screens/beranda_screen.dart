import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_provider.dart';
import '../widgets/ews_appbar.dart';
import 'main_navigation.dart';
import '../theme/app_theme.dart';

class BerandaScreen extends StatelessWidget {
  final VoidCallback? onRefresh;
  final ValueChanged<int>? onNavigate; // 0=Beranda,1=Dashboard,2=Status,3=Darurat,4=Edukasi
  const BerandaScreen({super.key, this.onRefresh, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    // 🛠️ LANGKAH KUNCI: Membaca peran akun dari AuthProvider global
    final authProvider = context.watch<AuthProvider>();
    final String currentRole = authProvider.userRole.toString().toUpperCase();
    final bool isAdmin = currentRole == 'ADMIN' || currentRole == 'USERROLE.ADMIN';

    return Scaffold(
      appBar: EWSAppBar(onRefresh: onRefresh),
      // PERCAKAPAN HAK AKSES: Jika Admin, tampilkan Dashboard Operasional Mobile Admin
      body: SingleChildScrollView(
        child: Column(
          children: isAdmin 
            ? [
                _buildAdminHeroSection(),
                _buildAdminStatsSection(),
                _buildAdminQuickActions(context),
              ]
            : [
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

  // =========================================================================
  // KOMPONEN LAYOUT BERANDA KHUSUS ADMIN MOBILE
  // =========================================================================

  Widget _buildAdminHeroSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)], // Gradasi Navy Premium khusus Admin
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
                  'SISTEM PEMANTAUAN PETUGAS BPBD',
                  style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Selamat Datang di Panel Manajemen Admin Mobile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pantau seluruh status telemetri perangkat IoT, kelola ambang batas risiko, dan lakukan tindakan broadcast darurat terkoordinasi secara langsung.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              // Tombol kontrol cepat admin
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => navIndexNotifier.value = 1, // Pindah ke tab Data Sensor
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.analytics_outlined, size: 18),
                      label: const Text('Kelola Alat IoT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminStatsSection() {
    // Sinkronisasi data manifest dari berkas seed.ts (3 Perangkat Water Level + 2 Rain Gauge = 5 Sensor Aktif)
    final adminStats = [
      {'value': '0', 'label': 'Sensor Terpasang', 'icon': Icons.sensors, 'color': AppTheme.primaryBlue},
      {'value': 'NON-AKTIF', 'label': 'Konektivitas Global', 'icon': Icons.cloud_off, 'color': Colors.grey},
      {'value': '0', 'label': 'Status Waspada', 'icon': Icons.warning_rounded, 'color': AppTheme.statusWaspada},
      {'value': '0', 'label': 'Status Bahaya', 'icon': Icons.notifications_active, 'color': Colors.redAccent},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kondisi Infrastruktur Real-Time', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: adminStats.map((s) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                    const SizedBox(height: 6),
                    Text(s['value'] as String, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: s['color'] as Color)),
                    Text(s['label'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2), // Box merah tipis penanda aksi darurat
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.campaign, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text('Komando Siaran Cepat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF9F1239))),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Gunakan tombol di bawah untuk menyiarkan push notification peringatan evakuasi massal secara manual ke seluruh perangkat warga apabila terjadi anomali sistem.',
              style: TextStyle(fontSize: 12, color: Color(0xFFBE123C), height: 1.4),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => navIndexNotifier.value = 3, // Pindah langsung ke menu siaran darurat
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Buka Menu Broadcast Darurat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// LAYOUT ASLI LAMA KHUSUS WARGA (TETAP DIKUNCI AMAN TANPA PERUBAHAN)
// =========================================================================
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
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
              color: color.withValues(alpha: 0.1),
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
            'Platform monitoring real-time untuk membantu admin memantau sensor, memvalidasi alert, and mempercepat koordinasi respons banjir.',
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.email_outlined, color: Colors.white60, size: 14),
              SizedBox(width: 8),
              Text('support@ewsfloodguard.id', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.phone_outlined, color: Colors.white60, size: 14),
              SizedBox(width: 8),
              Text('+62 21 555 0199', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.white60, size: 14),
              SizedBox(width: 8),
              Text('Padang, Sumatera Barat', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('© 2026 EWS Flood Guard. All rights reserved.', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}