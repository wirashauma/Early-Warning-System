import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/sensor_model.dart';
import 'package:provider/provider.dart';
import '../models/admin_provider.dart';
import '../widgets/ews_appbar.dart';

class DashboardScreenNew extends StatefulWidget {
  final VoidCallback? onRefresh;
  const DashboardScreenNew({super.key, this.onRefresh});
  @override
  State<DashboardScreenNew> createState() => _DashboardScreenNewState();
}

class _DashboardScreenNewState extends State<DashboardScreenNew> {
  int _selectedSensorIndex = 0;

  bool _hasInstalledSensors(AdminProvider admin) => (admin.dashboardStats['totalSensors'] ?? 0) > 0 || admin.sensors.isNotEmpty;

  SensorData _selectedSensor(AdminProvider admin) {
    final waterLevels = admin.dashboardStats['waterLevels'] as List<dynamic>? ?? [];
    if (waterLevels.isNotEmpty && _selectedSensorIndex < waterLevels.length) {
      final m = waterLevels[_selectedSensorIndex] as Map<String, dynamic>;
      return SensorData(
        name: m['sensorId']?.toString() ?? 'Sensor',
        location: m['location']?.toString() ?? '-',
        waterLevel: (m['waterLevel'] is num) ? (m['waterLevel'] as num).toDouble() : 0.0,
        rainfall: (m['rainfall'] is num) ? (m['rainfall'] as num).toDouble() : 0.0,
        status: m['status']?.toString() ?? 'Normal',
        lastUpdate: DateTime.tryParse(m['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
    }
    return SensorData(
      name: 'Belum Ada Sensor',
      location: '-',
      waterLevel: 0,
      rainfall: 0,
      status: 'Normal',
      lastUpdate: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    return Scaffold(
      appBar: EWSAppBar(onRefresh: widget.onRefresh),
      backgroundColor: AppTheme.pageBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildHeroBanner(adminProvider),
            _buildStatsGrid(adminProvider),
            _buildSensorSection(adminProvider),
            _buildRecommendationSection(adminProvider),
            _buildStatusLegend(),
            const SizedBox(height: 32),
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Monitoring',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          SizedBox(height: 4),
          Text(
            'Pantau tinggi air dan curah hujan secara real-time',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(AdminProvider admin) {
    final sensor = _selectedSensor(admin);
    final statusColor = sensor.statusColor;
    final statusLabel = sensor.status.toUpperCase();
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [statusColor, statusColor.withValues(alpha: 0.9)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STATUS SAAT INI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusLabel,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Update Terakhir',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '16 Mar 2026',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    Text(
                      '16:02',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
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

  Widget _buildStatsGrid(AdminProvider admin) {
    final sensor = _selectedSensor(admin);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StatCard(
            label: 'Tinggi Air',
            value: sensor.waterLevel.toInt().toString(),
            unit: 'cm',
            icon: Icons.water_outlined,
            color: AppTheme.accentBlue,
          ),
          _StatCard(
            label: 'Curah Hujan',
            value: sensor.rainfall.toStringAsFixed(1),
            unit: 'mm/jam',
            icon: Icons.cloud_queue_outlined,
            color: const Color(0xFF06B6D4),
          ),
          const _StatCard(
            label: 'Konektivitas',
            value: 'Online',
            unit: '',
            icon: Icons.signal_cellular_4_bar,
            color: AppTheme.statusNormal,
          ),
          _StatCard(
            label: 'Status Sensor',
            value: sensor.status,
            unit: '',
            icon: Icons.sensors_outlined,
            color: sensor.statusColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorSection(AdminProvider admin) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monitor Sensor',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pilih sensor untuk melihat detail',
                    style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_hasInstalledSensors(admin))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'Belum ada sensor terpasang. Data sensor akan muncul setelah perangkat aktif.',
                style: TextStyle(fontSize: 13, color: AppTheme.textGrey, height: 1.5),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: (admin.sensors.cast<Map<String, dynamic>>()).asMap().entries.map((e) {
                  final isSelected = e.key == _selectedSensorIndex;
                  final sensorMap = e.value;
                  final sensor = SensorData(
                    name: sensorMap['name']?.toString() ?? 'Sensor',
                    location: sensorMap['latitude']?.toString() ?? '-',
                    waterLevel: (sensorMap['waterLevel'] is num) ? (sensorMap['waterLevel'] as num).toDouble() : 0.0,
                    rainfall: (sensorMap['rainfall'] is num) ? (sensorMap['rainfall'] as num).toDouble() : 0.0,
                    status: sensorMap['status']?.toString() ?? 'Normal',
                    lastUpdate: DateTime.tryParse(sensorMap['updatedAt']?.toString() ?? '') ?? DateTime.now(),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSensorIndex = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.lightBlue : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppTheme.accentBlue : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sensor.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: sensor.statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection(AdminProvider admin) {
    final sensor = _selectedSensor(admin);
    final statusColor = sensor.statusColor;
    final recommendations = _getRecommendations(sensor.status);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getRecommendationBgColor(sensor.status),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Rekomendasi untuk Anda',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getRecommendationTitle(sensor.status),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatusLegend() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PANDUAN STATUS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Pahami Indikator Status Banjir',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 12),
          _LegendItem(
            icon: ' ✅ ',
            title: 'Hijau (Normal)',
            desc: 'Kondisi aman, aktivitas normal',
            range: '< 150 cm',
            color: AppTheme.statusNormal,
          ),
          SizedBox(height: 10),
          _LegendItem(
            icon: ' ⚠️ ',
            title: 'Kuning (Waspada)',
            desc: 'Pantau perkembangan, siap siaga',
            range: '150-199 cm',
            color: AppTheme.statusWaspada,
          ),
          SizedBox(height: 10),
          _LegendItem(
            icon: ' 🚨 ',
            title: 'Merah (Bahaya)',
            desc: 'Evakuasi segera ke titik aman',
            range: '≥ 200 cm',
            color: AppTheme.statusBahaya,
          ),
        ],
      ),
    );
  }

  String _getRecommendationTitle(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return 'Situasi aman. Tetap pantau dashboard secara berkala.';
      case 'alert':
        return 'Terjadi kenaikan air. Siapkan perlengkapan dan rencana evakuasi.';
      case 'danger':
        return 'Kondisi kritis! Prioritaskan keselamatan jiwa dan evakuasi segera.';
      default:
        return 'Pantau situasi terkini.';
    }
  }

  List<String> _getRecommendations(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return [
          'Pantau pembaruan level air setiap 30 menit',
          'Pastikan notifikasi perangkat tetap aktif',
          'Simpan jalur evakuasi untuk antisipasi',
        ];
      case 'alert':
        return [
          'Pantau dashboard setiap 10-15 menit',
          'Siapkan tas siaga dan dokumen penting',
          'Prioritaskan kesiapan keluarga rentan',
          'Hubungi kelurahan atau petugas setempat',
        ];
      case 'danger':
        return [
          'Lakukan evakuasi ke titik aman resmi SEGERA',
          'Hubungi layanan darurat jika akses terputus',
          'Ikuti arahan petugas dan hindari arus banjir',
          'Jangan mencoba menerobos area tergenang',
        ];
      default:
        return ['Pantau situasi terkini'];
    }
  }

  Color _getRecommendationBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return AppTheme.statusNormal.withValues(alpha: 0.1);
      case 'alert':
        return AppTheme.statusWaspada.withValues(alpha: 0.1);
      case 'danger':
        return AppTheme.statusBahaya.withValues(alpha: 0.1);
      default:
        return const Color(0xFFF8FAFC);
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGrey,
                  letterSpacing: 0.3,
                ),
              ),
              Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  final String range;
  final Color color;
  const _LegendItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.range,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      range,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textGrey,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}