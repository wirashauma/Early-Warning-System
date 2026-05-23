import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/admin_provider.dart';
import '../models/sensor_model.dart';
import '../theme/app_theme.dart';
import '../widgets/ews_appbar.dart';

class StatusScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  const StatusScreen({super.key, this.onRefresh});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  int? _focusedIndex;
  bool _loadedOnce = false;
  String _filter = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      debugPrint(
        '[StatusScreen] didChangeDependencies -> loadDashboardStats()',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final provider = context.read<AdminProvider>();
        try {
          await provider.loadDashboardStats();
        } catch (e) {
          debugPrint('[StatusScreen] loadDashboardStats failed: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat peta sensor: $e'),
              backgroundColor: AppTheme.statusBahaya,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isOnline(Map<String, dynamic> sensor) {
    return SensorModel.isTimestampOnline(
      sensor['last_seen_at'] ??
          sensor['lastSeenAt'] ??
          sensor['last_active_at'] ??
          sensor['lastActiveAt'] ??
          sensor['updated_at'] ??
          sensor['updatedAt'] ??
          sensor['recorded_at'] ??
          sensor['recordedAt'],
    );
  }

  String _sensorStatus(Map<String, dynamic> sensor) {
    final raw = (sensor['waterLevelStatus'] ?? sensor['status'] ?? '')
        .toString()
        .toUpperCase();
    if (raw == 'DANGER') return 'Bahaya';
    if (raw == 'ALERT' || raw == 'WARNING') return 'Waspada';
    if (raw == 'NORMAL' || raw == 'SAFE') return 'Normal';
    return _isOnline(sensor) ? 'Normal' : 'Offline';
  }

  Color _sensorColor(Map<String, dynamic> sensor) {
    final status = _sensorStatus(sensor);
    if (status == 'Bahaya') return AppTheme.statusBahaya;
    if (status == 'Waspada') return AppTheme.statusWaspada;
    if (status == 'Offline') return const Color(0xFF94A3B8);
    return AppTheme.statusNormal;
  }

  List<Map<String, dynamic>> _sensors(AdminProvider admin) {
    return admin.sensors.whereType<Map<String, dynamic>>().where((sensor) {
      final name = (sensor['name'] ?? '').toString();
      final status = _sensorStatus(sensor);
      final matchFilter = _filter == 'Semua' || status == _filter;
      final query = _searchQuery.trim().toLowerCase();
      final matchSearch = query.isEmpty || name.toLowerCase().contains(query);
      return matchFilter && matchSearch;
    }).toList();
  }

  Map<String, dynamic>? _focusedSensor(List<Map<String, dynamic>> sensors) {
    if (_focusedIndex == null || _focusedIndex! >= sensors.length) return null;
    return sensors[_focusedIndex!];
  }

  LatLng _centerOf(List<Map<String, dynamic>> sensors) {
    if (sensors.isEmpty) {
      return const LatLng(-0.9490, 100.3610);
    }
    final first = sensors.first;
    final lat = (first['latitude'] is num)
        ? (first['latitude'] as num).toDouble()
        : -0.9490;
    final lng = (first['longitude'] is num)
        ? (first['longitude'] as num).toDouble()
        : 100.3610;
    return LatLng(lat, lng);
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textGrey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final sensors = _sensors(admin);
    final totalSensors = admin.sensors.length;
    final onlineSensors = admin.onlineSensorsCount;
    final offlineSensors = admin.offlineSensorsCount;
    final warningCount = admin.warningCount;
    final dangerCount = admin.dangerCount;
    final globalStatus = admin.globalStatus;
    final center = _centerOf(sensors);

    final latestUpdate = () {
      final timestamps = sensors
          .map((s) => s['lastActiveAt'] ?? s['updatedAt'] ?? s['recordedAt'])
          .where((v) => v != null)
          .map((v) => DateTime.tryParse(v.toString()))
          .where((dt) => dt != null)
          .map((dt) => dt!.toLocal())
          .toList();
      if (timestamps.isEmpty) return DateTime.now();
      timestamps.sort((a, b) => b.compareTo(a));
      return timestamps.first;
    }();

    return Scaffold(
      appBar: EWSAppBar(onRefresh: widget.onRefresh),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (admin.errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  admin.errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STATUS PEMANTAUAN',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Peta & Daftar Sensor',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Identifikasi titik risiko banjir secara real-time melalui integrasi peta dan data metrik sensor.',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      _StatBox(label: 'Total Sensor', value: '$totalSensors'),
                      _StatBox(label: 'Sensor Aktif', value: '$onlineSensors'),
                      _StatBox(
                        label: 'Sensor Offline',
                        value: '$offlineSensors',
                      ),
                      _StatBox(
                        label: 'Pembaruan Terakhir',
                        value:
                            '${latestUpdate.day}/${latestUpdate.month}/${latestUpdate.year}',
                        small: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Status Global: $globalStatus',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Waspada: $warningCount • Bahaya: $dangerCount',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Peta Interaktif Sensor',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        children: [
                          _buildLegend(AppTheme.statusNormal, 'Normal'),
                          _buildLegend(AppTheme.statusWaspada, 'Waspada'),
                          _buildLegend(AppTheme.statusBahaya, 'Bahaya'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (sensors.isEmpty)
                    Container(
                      height: 220,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'Belum ada sensor dari backend.',
                        style: TextStyle(color: AppTheme.textGrey),
                      ),
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: FlutterMap(
                              options: MapOptions(center: center, zoom: 13.5),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.ews_flood_guard',
                                ),
                                MarkerLayer(
                                  markers: sensors.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final sensor = entry.value;
                                    final lat = (sensor['latitude'] is num)
                                        ? (sensor['latitude'] as num).toDouble()
                                        : center.latitude;
                                    final lng = (sensor['longitude'] is num)
                                        ? (sensor['longitude'] as num)
                                              .toDouble()
                                        : center.longitude;
                                    final color = _sensorColor(sensor);
                                    final focusedNow = _focusedIndex == index;
                                    return Marker(
                                      point: LatLng(lat, lng),
                                      width: 44,
                                      height: 44,
                                      builder: (ctx) => GestureDetector(
                                        onTap: () => setState(
                                          () => _focusedIndex = focusedNow
                                              ? null
                                              : index,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: focusedNow
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: color.withOpacity(0.45),
                                                blurRadius: focusedNow ? 10 : 4,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              (sensor['name']?.toString() ??
                                                      'S')
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
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
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DETAIL FOKUS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_focusedSensor(sensors) == null)
                                const Text(
                                  'Pilih titik di peta.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textGrey,
                                  ),
                                )
                              else ...[
                                Text(
                                  _focusedSensor(
                                        sensors,
                                      )!['name']?.toString() ??
                                      '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(_focusedSensor(sensors)!['waterLevel'] is num ? (_focusedSensor(sensors)!['waterLevel'] as num).toInt() : 0)} cm',
                                  style: const TextStyle(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _sensorStatus(_focusedSensor(sensors)!),
                                  style: const TextStyle(
                                    color: AppTheme.textDark,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lat/Lng: ${(_focusedSensor(sensors)!['latitude'] as num?)?.toDouble().toStringAsFixed(4) ?? '-'}, ${(_focusedSensor(sensors)!['longitude'] as num?)?.toDouble().toStringAsFixed(4) ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textGrey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Cari sensor...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Semua', 'Normal', 'Waspada', 'Bahaya'].map((
                        filter,
                      ) {
                        return GestureDetector(
                          onTap: () => setState(() => _filter = filter),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _filter == filter
                                  ? AppTheme.accentBlue
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _filter == filter
                                    ? AppTheme.accentBlue
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 12,
                                color: _filter == filter
                                    ? Colors.white
                                    : AppTheme.textDark,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (sensors.where((s) => true).isEmpty)
                    const Center(child: Text('Sensor tidak ditemukan.'))
                  else
                    ...sensors.map(
                      (sensor) => _SensorCard(
                        sensor: sensor,
                        statusLabel: _sensorStatus(sensor),
                        statusColor: _sensorColor(sensor),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool small;
  const _StatBox({
    required this.label,
    required this.value,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: small ? 11 : 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final Map<String, dynamic> sensor;
  final String statusLabel;
  final Color statusColor;
  const _SensorCard({
    required this.sensor,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final waterLevel = (sensor['waterLevel'] is num)
        ? (sensor['waterLevel'] as num).toDouble()
        : 0.0;
    final battery = sensor['batteryLevel'] ?? sensor['battery_level'];
    final lat = (sensor['latitude'] is num)
        ? (sensor['latitude'] as num).toDouble()
        : null;
    final lng = (sensor['longitude'] is num)
        ? (sensor['longitude'] as num).toDouble()
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.sensors, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensor['name']?.toString() ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lat/Lng: ${lat?.toStringAsFixed(4) ?? '-'}, ${lng?.toStringAsFixed(4) ?? '-'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Baterai: ${battery ?? '-'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${waterLevel.toInt()} cm',
                style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
