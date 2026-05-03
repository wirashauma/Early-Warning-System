import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../widgets/ews_appbar.dart';
import '../models/sensor_model.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  const DashboardScreen({super.key, this.onRefresh});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedSensorIndex = 0;

  SensorData get _selectedSensor => dummySensors[_selectedSensorIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EWSAppBar(onRefresh: widget.onRefresh),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildSensorMap(),
            _buildLiveSensor(),
            _buildStatusLegend(),
            _buildChartSection(),
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
          const Text('Real-Time Dashboard Pemantauan Banjir',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Masyarakat dapat melihat peta sensor, data real-time, grafik tren ketinggian air, dan intensitas curah hujan secara langsung dari dashboard ini.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  // Koordinat sensor di sepanjang Batang Arau, Padang
  static const List<Map<String, dynamic>> _sensorLocations = [
    {'label': 'H1', 'colorVal': 0xFFE53E3E, 'lat': -0.9570, 'lng': 100.3530, 'name': 'Hulu Batang Arau'},
    {'label': 'T1', 'colorVal': 0xFFDD6B20, 'lat': -0.9490, 'lng': 100.3610, 'name': 'Tengah Sungai'},
    {'label': 'H2', 'colorVal': 0xFF38A169, 'lat': -0.9430, 'lng': 100.3700, 'name': 'Hilir Batang Arau'},
  ];

  Widget _buildSensorMap() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Peta Sensor - Batang Arau, Padang',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Text('Tap marker untuk detail',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 11)),
              ],
            ),
          ),
          // Peta REAL menggunakan flutter_map + OpenStreetMap (gratis)
          Container(
            height: 250,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.hardEdge,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(-0.9490, 100.3610),
                initialZoom: 14.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ews_flood_guard',
                ),
                MarkerLayer(
                  markers: _sensorLocations.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    final isSelected = _selectedSensorIndex == i;
                    final color = Color(s['colorVal'] as int);
                    return Marker(
                      point: LatLng(s['lat'] as double, s['lng'] as double),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSensorIndex = i),
                        child: Tooltip(
                          message: s['name'] as String,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.6),
                                  blurRadius: isSelected ? 10 : 4,
                                  spreadRadius: isSelected ? 2 : 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                s['label'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Sensor selector tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: dummySensors.asMap().entries.map((e) {
                final isSelected = e.key == _selectedSensorIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSensorIndex = e.key),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.lightBlue : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppTheme.accentBlue : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(e.value.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
                              )),
                          Text(e.value.location,
                              style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Lokasi terpilih: ${_selectedSensor.name} • Update: 16 Mar 2026, 16.02',
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSensor() {
    final sensor = _selectedSensor;
    final statusColor = sensor.statusColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kondisi Live Sensor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(sensor.status,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Water level gauge
              _WaterGauge(level: sensor.waterLevel, maxLevel: 300),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${sensor.waterLevel.toInt()} cm',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const Text('Ketinggian air saat ini',
                        style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.statusWaspada.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Curah hujan Sedang (5-20 mm/jam)',
                        style: TextStyle(color: AppTheme.statusWaspada, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${sensor.rainfall} mm/jam',
                        style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Indikator Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          ...[
            ('Normal', AppTheme.statusNormal, 'Aman, aktivitas normal.'),
            ('Kuning (Waspada)', AppTheme.statusWaspada, 'Pantau perkembangan.'),
            ('Oren (Siaga)', AppTheme.statusSiaga, 'Siap evakuasi dini.'),
            ('Merah (Bahaya)', AppTheme.statusBahaya, 'Evakuasi segera.'),
          ].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: item.$2, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const Text(' — ', style: TextStyle(color: AppTheme.textGrey)),
                Text(item.$3, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatusLegend() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EDUKASI VISUAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accentBlue, letterSpacing: 1)),
          const SizedBox(height: 4),
          const Text('Status Indicators & Legend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Pahami kode warna status agar masyarakat dapat mengambil keputusan lebih cepat dan tepat.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          const SizedBox(height: 16),
          ...[
            ('Hijau (Normal)', AppTheme.statusNormal, 'Kondisi aman, ketinggian air di bawah ambang batas waspada.', '< 150 cm', 'Aktivitas normal, tetap pantau dashboard setiap 30 menit.'),
            ('Kuning (Waspada)', AppTheme.statusWaspada, 'Ketinggian air meningkat, masyarakat diminta waspada dan bersiap.', '150 - 199 cm', 'Siapkan tas darurat, dokumen penting, dan rute evakuasi keluarga.'),
            ('Oren (Siaga)', AppTheme.statusSiaga, 'Kondisi mendekati bahaya, masyarakat diminta bersiap untuk evakuasi segera.', '190 - 219 cm', 'Aktifkan rencana evakuasi dan prioritaskan kelompok rentan untuk bergerak lebih awal.'),
            ('Merah (Bahaya / Evakuasi)', AppTheme.statusBahaya, 'Kondisi darurat, evakuasi segera diperlukan sesuai arahan petugas.', '≥ 220 cm', 'Segera evakuasi ke titik aman terdekat dan ikuti arahan petugas.'),
          ].map((item) => _StatusCard(
            title: item.$1,
            color: item.$2,
            desc: item.$3,
            range: item.$4,
            action: item.$5,
          )),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grafik Tren Ketinggian Air', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          // Simple bar chart placeholder
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Map<String, dynamic>>[
                {'time': '08:00', 'level': 110.0, 'color': AppTheme.statusNormal},
                {'time': '10:00', 'level': 130.0, 'color': AppTheme.statusNormal},
                {'time': '12:00', 'level': 145.0, 'color': AppTheme.statusNormal},
                {'time': '14:00', 'level': 160.0, 'color': AppTheme.statusWaspada},
                {'time': '16:00', 'level': 126.0, 'color': AppTheme.statusNormal},
              ].map((d) => Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${(d['level'] as double).toInt()}', style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)),
                  const SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: (d['level'] as double) / 160 * 100,
                    decoration: BoxDecoration(
                      color: (d['color'] as Color).withAlpha(204),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(d['time'] as String, style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)),
                ],
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Ketinggian Air (cm) - 16 Mar 2026', style: TextStyle(color: AppTheme.textGrey, fontSize: 11))),
        ],
      ),
    );
  }
}


class _WaterGauge extends StatelessWidget {
  final double level;
  final double maxLevel;

  const _WaterGauge({required this.level, required this.maxLevel});

  @override
  Widget build(BuildContext context) {
    final pct = (level / maxLevel).clamp(0.0, 1.0);
    return Container(
      width: 60,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        color: const Color(0xFFF8FAFC),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          FractionallySizedBox(
            heightFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.statusNormal,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title, desc, range, action;
  final Color color;

  const _StatusCard({required this.title, required this.color, required this.desc, required this.range, required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 20, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              Icon(_getIcon(title), color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ambang indikator', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppTheme.textGrey)),
                    Text(range, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Tindakan cepat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppTheme.accentBlue)),
          const SizedBox(height: 4),
          Text(action, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  IconData _getIcon(String title) {
    if (title.contains('Normal')) return Icons.check_box;
    if (title.contains('Kuning')) return Icons.warning_amber;
    if (title.contains('Oren')) return Icons.circle_notifications;
    return Icons.dangerous;
  }
}
