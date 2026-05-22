import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/admin_provider.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      context.read<AdminProvider>().loadDashboardStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final stats = adminProvider.dashboardStats;

    final totalSensors = stats['totalSensors'] ?? 0;
    final onlineSensors = stats['onlineSensors'] ?? 0;
    final offlineSensors = stats['offlineSensors'] ?? 0;
    final avgRainfall = stats['avgRainfall'] ?? 0.0;
    final waterLevels = stats['waterLevels'] as List<dynamic>? ?? [];
    final recentAlerts = stats['recentAlerts'] as List<dynamic>? ?? [];
    final maxLevelCm = waterLevels.fold<double>(0.0, (prev, item) {
      final level = item is Map<String, dynamic> ? (item['waterLevel'] ?? 0) : 0;
      return (level is num && level.toDouble() > prev) ? level.toDouble() : prev;
    });
    final dangerCount = recentAlerts.where((item) => item is Map<String, dynamic> && (item['severity'] == 'DANGER' || item['severity'] == 'critical')).length;
    final warningCount = recentAlerts.where((item) => item is Map<String, dynamic> && (item['severity'] == 'WARNING' || item['severity'] == 'warning')).length;
    final currentStatus = dangerCount > 0
        ? 'Bahaya'
        : warningCount > 0
            ? 'Waspada'
            : 'Aman';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('Selamat Datang! ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('👋', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ringkasan cepat kondisi sistem Early Warning System untuk membantu tim merespons perubahan level air lebih sigap.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Status global saat ini: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(20)),
                      child: Text(currentStatus, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Text('Tahun Operasional: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                Text('2026/2027', style: TextStyle(color: Color(0xFF0066FF), fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          adminProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildMetricCard('Sensor Aktif', '$onlineSensors', 'Total sensor: $totalSensors', Icons.sensors, Colors.blue, const Color(0xFFEFF6FF)),
                    _buildMetricCard('Status Waspada', '$warningCount', 'Sensor dalam status alert', Icons.warning_rounded, AppTheme.statusWaspada, const Color(0xFFEFF6FF)),
                    _buildMetricCard('Status Bahaya', '$dangerCount', 'Perlu respons segera', Icons.gpp_bad_outlined, Colors.pink, const Color(0xFFFFF1F2)),
                    _buildMetricCard('Curah Hujan', '${avgRainfall.toStringAsFixed(1)} mm/jam', 'Rata-rata data', Icons.cloud_queue, Colors.cyan, const Color(0xFFECFEFF)),
                    _buildMetricCard('Puncak Tinggi Air', '${maxLevelCm.toInt()} cm', 'Pembacaan tertinggi', Icons.water_drop_outlined, Colors.teal, const Color(0xFFF0FDF4)),
                    _buildMetricCard('Sensor Offline', '$offlineSensors', 'Perlu pengecekan', Icons.wifi_off_rounded, Colors.purple, const Color(0xFFF5F3FF)),
                  ],
                ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text('Peta Interaktif Lokasi Sensor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 180,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                  child: FlutterMap(
                    options: MapOptions(
                      center: LatLng(-0.9490, 100.3610),
                      zoom: 11.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.ews_flood_guard',
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String sub, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 6),
              Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          )
        ],
      ),
    );
  }
}
