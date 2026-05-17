import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ews_appbar.dart';

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EWSAppBar(
        onRefresh: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Memperbarui alerts...')),
          );
        },
      ),
      backgroundColor: AppTheme.pageBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildAlertsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifikasi & Alert',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pantau notifikasi banjir dan update sistem',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    final alerts = [
      {
        'title': 'Status Kuning - Sensor H1 Batang Arau',
        'message': 'Ketinggian air telah mencapai 165 cm. Siapkan perlengkapan darurat.',
        'severity': 'WARNING',
        'time': '10 menit yang lalu',
        'icon': Icons.warning_outlined,
        'color': AppTheme.statusWaspada,
      },
      {
        'title': 'Update Sistem Berhasil',
        'message': 'Data sensor telah diperbarui. Semua sensor dalam kondisi normal.',
        'severity': 'INFO',
        'time': '25 menit yang lalu',
        'icon': Icons.info_outlined,
        'color': AppTheme.accentBlue,
      },
      {
        'title': 'Koneksi Sensor T1 Hilang',
        'message': 'Sensor T1 tidak merespons. Tim teknis sedang memperbaiki.',
        'severity': 'ERROR',
        'time': '1 jam yang lalu',
        'icon': Icons.signal_cellular_null,
        'color': AppTheme.statusBahaya,
      },
    ];

    return Container(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: alerts.map((alert) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: (alert['color'] as Color).withAlpha(26),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (alert['color'] as Color).withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      alert['icon'] as IconData,
                      color: alert['color'] as Color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert['title'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert['message'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alert['time'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (alert['color'] as Color).withAlpha(26),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      alert['severity'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: alert['color'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
