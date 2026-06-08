import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/telemetry_provider.dart';
import '../models/sensor_model.dart';
import '../theme/app_theme.dart';
import '../widgets/ews_appbar.dart';
import 'main_navigation.dart';

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
  final MapController _mapController = MapController();
  List<String> _lastFitIds = [];

  void _fitBounds(List<SensorModel> filteredSensors) {
    if (filteredSensors.isEmpty) return;
    final points = filteredSensors.map((s) {
      return LatLng(s.latitude, s.longitude);
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // New flutter_map API uses move/fitCamera. To keep this simple and
        // compatible, move the map to the bounds center and use a sensible zoom.
        final bounds = LatLngBounds.fromPoints(points);
        final center = bounds.center;
        _mapController.move(center, 13.5);
      } catch (e) {
        debugPrint('fitBounds failed: $e');
      }
    });
  }

  void _checkAndFitBounds(List<SensorModel> filteredSensors) {
    final currentIds = filteredSensors.map((s) => s.sensorId).toList();
    if (listEquals(_lastFitIds, currentIds)) return;
    _lastFitIds = currentIds;
    _fitBounds(filteredSensors);
  }

  void _showSensorDetails(BuildContext context, SensorModel sensor) {
    final name = sensor.name;
    final sensorId = sensor.sensorId;
    final status = _sensorStatus(sensor);
    final color = _sensorColor(sensor);
    final waterLevel = sensor.waterLevel?.toInt() ?? 0;
    final rainfall = sensor.rainfall ?? 0.0;
    final flowRate = sensor.flowRate ?? 0.0;
    final battery = sensor.batteryLevel;
    final connectivity = sensor.displayConnectivity;
    final lastSeen = sensor.effectiveLastSeenAt?.toIso8601String() ?? '-';

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: $sensorId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      Icons.water,
                      'Tinggi Air',
                      '$waterLevel cm',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricTile(
                      Icons.grain,
                      'Curah Hujan',
                      '${rainfall.toStringAsFixed(1)} mm',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      Icons.speed,
                      'Debit Air',
                      '${flowRate.toStringAsFixed(1)} LPM',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricTile(
                      Icons.battery_charging_full,
                      'Baterai',
                      battery != null ? '$battery%' : 'N/A',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      Icons.wifi,
                      'Koneksi',
                      connectivity,
                      subtitle: lastSeen.split('T').first,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    navIndexNotifier.value = 0;
                  },
                  child: const Text('Pantau di Dasbor'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(
    IconData icon,
    String label,
    String value, {
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.accentBlue, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textGrey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 9, color: AppTheme.textGrey),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      debugPrint('[StatusScreen] didChangeDependencies -> loadInitialData()');
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final provider = context.read<TelemetryProvider>();
        try {
          await provider.loadInitialData();
        } catch (e) {
          debugPrint('[StatusScreen] loadInitialData failed: $e');
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

  String _sensorStatus(SensorModel sensor) {
    final raw = (sensor.status ?? '').toString().toUpperCase();
    if (raw == 'DANGER' || raw == 'BAHAYA') {
      return 'Bahaya';
    }
    if (raw == 'ALERT' || raw == 'WARNING' || raw == 'WASPADA') {
      return 'Waspada';
    }
    if (raw == 'NORMAL' || raw == 'SAFE' || raw == 'AMAN') {
      return 'Normal';
    }
    return sensor.isOnline ? 'Normal' : 'Offline';
  }

  Color _sensorColor(SensorModel sensor) {
    final status = _sensorStatus(sensor);
    if (status == 'Bahaya') return AppTheme.statusBahaya;
    if (status == 'Waspada') return AppTheme.statusWaspada;
    if (status == 'Offline') return const Color(0xFF94A3B8);
    return AppTheme.statusNormal;
  }

  List<SensorModel> _sensors(TelemetryProvider telemetry) {
    return telemetry.sensors.where((sensor) {
      final name = sensor.name.toString();
      final status = _sensorStatus(sensor);
      final matchFilter = _filter == 'Semua' || status == _filter;
      final query = _searchQuery.trim().toLowerCase();
      final matchSearch = query.isEmpty || name.toLowerCase().contains(query);
      return matchFilter && matchSearch;
    }).toList();
  }

  SensorModel? _focusedSensor(List<SensorModel> sensors) {
    if (_focusedIndex == null || _focusedIndex! >= sensors.length) return null;
    return sensors[_focusedIndex!];
  }

  LatLng _centerOf(List<SensorModel> sensors) {
    if (sensors.isEmpty) {
      return const LatLng(-0.9490, 100.3610);
    }
    final first = sensors.first;
    return LatLng(first.latitude, first.longitude);
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
    final telemetry = context.watch<TelemetryProvider>();
    final sensors = _sensors(telemetry);

    // Automatically center and zoom camera to cover all active markers on load/filter
    _checkAndFitBounds(sensors);

    final totalSensors = telemetry.sensors.length;
    final onlineSensors = telemetry.onlineSensorsCount;
    final offlineSensors = telemetry.offlineSensorsCount;
    final warningCount = telemetry.warningCount;
    final dangerCount = telemetry.dangerCount;

    final globalStatus = dangerCount > 0
        ? 'Bahaya'
        : warningCount > 0
        ? 'Waspada'
        : 'Aman';

    final center = _centerOf(sensors);

    final latestUpdate = () {
      final timestamps = sensors
          .map((s) => s.effectiveLastSeenAt)
          .where((v) => v != null)
          .map((v) => v!)
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
            if (telemetry.errorMessage != null)
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
                  telemetry.errorMessage!,
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
                    'Identifikasi titik risiko banjir secara real-time melalui integrasi peta and data metrik sensor.',
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
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: center,
                                initialZoom: 13.5,
                              ),
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
                                    final lat = sensor.latitude;
                                    final lng = sensor.longitude;
                                    final color = _sensorColor(sensor);
                                    final focusedNow = _focusedIndex == index;
                                    return Marker(
                                      point: LatLng(lat, lng),
                                      width: 44,
                                      height: 44,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(
                                            () => _focusedIndex = focusedNow
                                                ? null
                                                : index,
                                          );
                                          _showSensorDetails(context, sensor);
                                        },
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
                                                color: color.withAlpha(115),
                                                blurRadius: focusedNow ? 10 : 4,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              sensor.name
                                                  .toString()
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
                                  _focusedSensor(sensors)!.name.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_focusedSensor(sensors)!.waterLevel?.toInt() ?? 0} cm',
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
                                  'Lat/Lng: ${_focusedSensor(sensors)!.latitude.toStringAsFixed(4)}, ${_focusedSensor(sensors)!.longitude.toStringAsFixed(4)}',
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
                  if (sensors.isEmpty)
                    const Center(child: Text('Sensor tidak ditemukan.'))
                  else
                    ...sensors.map(
                      (sensor) => GestureDetector(
                        onTap: () => _showSensorDetails(context, sensor),
                        child: _SensorCard(
                          sensor: sensor,
                          statusLabel: _sensorStatus(sensor),
                          statusColor: _sensorColor(sensor),
                        ),
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
  final SensorModel sensor;
  final String statusLabel;
  final Color statusColor;
  const _SensorCard({
    required this.sensor,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final waterLevel = sensor.waterLevel ?? 0.0;
    final rainfall = sensor.rainfall ?? 0.0;
    final flowRate = sensor.flowRate ?? 0.0;
    final battery = sensor.batteryLevel;
    final lat = sensor.latitude;
    final lng = sensor.longitude;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sensors, color: statusColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lat/Lng: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          // Symmetrical 2x2 grid for metrics
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.0,
            children: [
              _buildMinicard('Tinggi Air', '${waterLevel.toInt()} cm'),
              _buildMinicard('Curah Hujan', '${rainfall.toStringAsFixed(1)} mm'),
              _buildMinicard('Debit Air', '${flowRate.toStringAsFixed(1)} LPM'),
              _buildMinicard('Baterai', battery != null ? '$battery%' : 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinicard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppTheme.textGrey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }
}
