import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart'; // Ditambahkan untuk membaca state login global
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/auth_provider.dart'; // Ditambahkan untuk membedakan Admin/User
import '../models/admin_provider.dart';
import '../providers/telemetry_provider.dart';
import '../models/sensor_model.dart';
import '../models/api_service.dart';
import '../models/water_level_log.dart';
import '../models/rainfall_log.dart';
import '../models/flow_rate_log.dart';
import '../theme/app_theme.dart';
import '../widgets/ews_appbar.dart';
import 'main_navigation.dart';
import 'edukasi_screen.dart';
import 'darurat_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  const DashboardScreen({super.key, this.onRefresh});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedSensorIndex = 0;
  int _selectedChartTab = 0; // 0 = Tinggi Air, 1 = Curah Hujan, 2 = Debit
  bool _loadingHistory = false;
  List<WaterLevelLog> _wlHistory = [];
  List<RainfallLog> _rfHistory = [];
  List<FlowRateLog> _frHistory = [];
  String? _historyError;
  final ApiService _api = ApiService();

  Future<void> _loadSensorHistory(SensorModel sensor) async {
    if (!mounted) return;
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });

    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(hours: 24));
      final startIso = oneDayAgo.toUtc().toIso8601String();
      final endIso = now.toUtc().toIso8601String();

      final telemetry = context.read<TelemetryProvider>();
      final wlSensor = telemetry.sensors.firstWhere(
        (s) => s.type.toUpperCase() == 'WATER_LEVEL',
        orElse: () => sensor,
      );
      final rfSensor = telemetry.sensors.firstWhere(
        (s) => s.type.toUpperCase() == 'RAINFALL',
        orElse: () => sensor,
      );
      final frSensor = telemetry.sensors.firstWhere(
        (s) => s.type.toUpperCase() == 'FLOW_RATE',
        orElse: () => sensor,
      );

      final results = await Future.wait([
        _api
            .fetchWaterLevelHistory(
              sensorId: wlSensor.sensorId,
              startDate: startIso,
              endDate: endIso,
              limit: 100,
            )
            .catchError((e) => <WaterLevelLog>[]),
        _api
            .fetchRainfallHistory(
              sensorId: rfSensor.sensorId,
              startDate: startIso,
              endDate: endIso,
              limit: 100,
            )
            .catchError((e) => <RainfallLog>[]),
        _api
            .fetchFlowRateHistory(
              sensorId: frSensor.sensorId,
              startDate: startIso,
              endDate: endIso,
              limit: 100,
            )
            .catchError((e) => <FlowRateLog>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _wlHistory = results[0] as List<WaterLevelLog>;
        _rfHistory = results[1] as List<RainfallLog>;
        _frHistory = results[2] as List<FlowRateLog>;
        _loadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = e.toString();
        _loadingHistory = false;
      });
    }
  }

  bool _hasInstalledSensors(TelemetryProvider telemetry) =>
      telemetry.sensors.isNotEmpty;

  SensorModel? _selected(TelemetryProvider telemetry) {
    if (telemetry.sensors.isNotEmpty &&
        _selectedSensorIndex < telemetry.sensors.length) {
      return telemetry.sensors[_selectedSensorIndex];
    }
    return null;
  }

  String _sensorStatus(SensorModel sensor) {
    final raw = (sensor.status ?? '').toString().toUpperCase();
    if (raw == 'DANGER' || raw == 'BAHAYA') return 'Bahaya';
    if (raw == 'ALERT' || raw == 'WARNING' || raw == 'WASPADA')
      return 'Waspada';
    if (raw == 'NORMAL' || raw == 'SAFE' || raw == 'AMAN') return 'Normal';
    return sensor.isOnline ? 'Normal' : 'Offline';
  }

  Color _sensorColor(SensorModel sensor) {
    final status = _sensorStatus(sensor);
    if (status == 'Bahaya') return AppTheme.statusBahaya;
    if (status == 'Waspada') return AppTheme.statusWaspada;
    if (status == 'Offline') return const Color(0xFF94A3B8);
    return AppTheme.statusNormal;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final String currentRole = authProvider.userRole.toString().toUpperCase();
      final bool isAdmin =
          currentRole == 'ADMIN' || currentRole == 'USERROLE.ADMIN';

      if (isAdmin) {
        debugPrint(
          '[DashboardScreen] initState -> loadDashboardStats() for ADMIN',
        );
        final provider = context.read<AdminProvider>();
        try {
          await provider.loadDashboardStats();
        } catch (e) {
          debugPrint('[DashboardScreen] loadDashboardStats failed: $e');
        }
      } else {
        debugPrint('[DashboardScreen] initState -> loadInitialData() for USER');
        final telemetry = context.read<TelemetryProvider>();
        try {
          await telemetry.loadInitialData();
          if (telemetry.sensors.isNotEmpty &&
              _selectedSensorIndex < telemetry.sensors.length) {
            _loadSensorHistory(telemetry.sensors[_selectedSensorIndex]);
          }
        } catch (e) {
          debugPrint('[DashboardScreen] loadInitialData failed: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat dashboard: $e'),
              backgroundColor: AppTheme.statusBahaya,
            ),
          );
        }
      }
    });
  }

  static const List<Map<String, dynamic>> _sensorLocations = [
    {
      'label': 'H1',
      'colorVal': 0xFFE53E3E,
      'lat': -0.9570,
      'lng': 100.3530,
      'name': 'Hulu Batang Arau',
    },
    {
      'label': 'T1',
      'colorVal': 0xFFDD6B20,
      'lat': -0.9490,
      'lng': 100.3610,
      'name': 'Tengah Sungai',
    },
    {
      'label': 'H2',
      'colorVal': 0xFF38A169,
      'lat': -0.9430,
      'lng': 100.3700,
      'name': 'Hilir Batang Arau',
    },
  ];

  // Simulasi manifes data sensor dari database seed backend Anda khusus untuk tampilan Admin
  // Admin sensor list is driven by backend via AdminProvider.sensors

  @override
  Widget build(BuildContext context) {
    // 1. Ambil status peran dari AuthProvider
    final authProvider = context.watch<AuthProvider>();
    final String currentRole = authProvider.userRole.toString().toUpperCase();
    final bool isAdmin =
        currentRole == 'ADMIN' || currentRole == 'USERROLE.ADMIN';

    // 2. Jika Admin, langsung tampilkan inventaris manajemen infrastruktur IoT petugas
    if (isAdmin) {
      final adminProvider = context.watch<AdminProvider>();
      return _buildAdminDashboard(adminProvider);
    }

    // 3. Jika User biasa, render layout grafik peta bawaan asli Anda bound to TelemetryProvider
    final telemetryProvider = context.watch<TelemetryProvider>();
    return Scaffold(
      appBar: EWSAppBar(onRefresh: widget.onRefresh),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (telemetryProvider.errorMessage != null)
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
                  telemetryProvider.errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            _buildStatusBanner(telemetryProvider),
            _buildMetricCards(telemetryProvider),
            _buildSensorMonitor(telemetryProvider),
            _buildActionPanel(),
            _buildPriorityPanel(telemetryProvider),
            _buildChartSection(telemetryProvider),
            _buildEdukasiSection(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAMPILAN KHUSUS MANAJEMEN ALAT IOT (HANYA KELUAR JIKA LOGIN SEBAGAI ADMIN)
  // =========================================================================
  Widget _buildAdminDashboard(AdminProvider adminProvider) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: EWSAppBar(onRefresh: widget.onRefresh),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MANAJEMEN PERANGKAT',
                      style: TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Infrastruktur Sensor IoT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Total: ${adminProvider.sensors.length}',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: adminProvider.sensors.length,
              itemBuilder: (context, index) {
                final raw = adminProvider.sensors[index];
                final sensor = raw is Map<String, dynamic> ? raw : {};
                final type = (sensor['type'] ?? sensor['sensor_type'] ?? '')
                    .toString();
                final isWater = type.toUpperCase().contains('WATER');
                final sensorId =
                    sensor['sensorId'] ??
                    sensor['sensor_id'] ??
                    sensor['id'] ??
                    '';
                final sensorName = sensor['name'] ?? '';
                final battery =
                    sensor['battery_level'] ?? sensor['batteryLevel'] ?? null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sensorId.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: AppTheme.accentBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sensorName.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                isWater ? Icons.water : Icons.thunderstorm,
                                size: 13,
                                color: AppTheme.textGrey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                type.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(
                                Icons.battery_charging_full,
                                size: 13,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                battery != null ? battery.toString() : '-',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (sensor['connectivity'] ??
                                  sensor['status'] ??
                                  'UNKNOWN')
                              .toString(),
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BLOK WIDGET USER WARGA (DIKUNCI DAN TIDAK DIUBAH SAMA SEKALI)
  // =========================================================================

  Widget _buildStatusBanner(TelemetryProvider telemetryProvider) {
    if (!_hasInstalledSensors(telemetryProvider)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.lightBlue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'STATUS KESELURUHAN WILAYAH',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'TIDAK TERSEDIA',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Belum ada sensor terpasang. Silakan pasang perangkat IoT terlebih dahulu untuk melihat data real-time.',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final sensors = telemetryProvider.sensors;
    final hasDanger = sensors.any(
      (s) =>
          s.status != null &&
          (s.status!.toUpperCase() == 'DANGER' ||
              s.status!.toUpperCase() == 'BAHAYA'),
    );
    final hasAlert =
        !hasDanger &&
        sensors.any(
          (s) =>
              s.status != null &&
              ['ALERT', 'WARNING', 'WASPADA'].contains(s.status!.toUpperCase()),
        );
    final globalLabel = hasDanger
        ? 'Bahaya'
        : hasAlert
        ? 'Waspada'
        : 'Aman';
    final color = hasDanger
        ? AppTheme.statusBahaya
        : hasAlert
        ? AppTheme.statusWaspada
        : AppTheme.statusNormal;

    DateTime u = DateTime.now();
    final latestTs = sensors
        .map((s) => s.effectiveLastSeenAt)
        .where((t) => t != null)
        .cast<DateTime>()
        .toList();
    if (latestTs.isNotEmpty) {
      latestTs.sort((a, b) => b.compareTo(a));
      u = latestTs.first;
    }
    final ts =
        '${u.day} Mei ${u.year}, ${u.hour.toString().padLeft(2, '0')}.${u.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS KESELURUHAN WILAYAH',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            globalLabel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Pembaruan Terakhir',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  ts,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(TelemetryProvider telemetryProvider) {
    final hasSensors = _hasInstalledSensors(telemetryProvider);
    final sensors = telemetryProvider.sensors;
    final totalSensors = sensors.length;
    final onlineCount = telemetryProvider.onlineSensorsCount;

    double maxLevel = 0.0;
    if (sensors.isNotEmpty) {
      maxLevel = sensors
          .map((s) => s.waterLevel ?? 0.0)
          .fold<double>(0.0, (prev, el) => el > prev ? el : prev);
    }

    double avgRainfall = 0.0;
    if (sensors.isNotEmpty) {
      final validRainfalls = sensors
          .map((s) => s.rainfall)
          .where((r) => r != null)
          .cast<double>()
          .toList();
      if (validRainfalls.isNotEmpty) {
        avgRainfall =
            validRainfalls.reduce((a, b) => a + b) / validRainfalls.length;
      }
    }

    final dangerCount = telemetryProvider.dangerCount;
    final warningCount = telemetryProvider.warningCount;
    final riskCount = dangerCount + warningCount;
    final cards = [
      {
        'label': 'Tinggi Air (Aktif)',
        'value': hasSensors ? '${maxLevel.toInt()} cm' : '0 cm',
        'sub': hasSensors ? 'Puncak saat ini' : 'Belum ada sensor terpasang',
        'color': AppTheme.accentBlue,
      },
      {
        'label': 'Curah Hujan',
        'value': hasSensors
            ? '${avgRainfall.toStringAsFixed(0)} mm/j'
            : '0 mm/j',
        'sub': hasSensors
            ? (avgRainfall < 5 ? 'Ringan' : 'Sedang')
            : 'Data belum tersedia',
        'color': AppTheme.statusWaspada,
      },
      {
        'label': 'Sensor Berisiko',
        'value': '$riskCount',
        'sub': 'Bahaya: $dangerCount • Waspada: $warningCount',
        'color': riskCount > 0 ? AppTheme.statusBahaya : AppTheme.statusNormal,
      },
      {
        'label': 'Sensor Aktif',
        'value': hasSensors ? '$onlineCount/$totalSensors' : '0/0',
        'sub': hasSensors ? 'Sensor online aktif' : 'Tidak ada sensor',
        'color': AppTheme.statusNormal,
      },
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFF8FAFC),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: cards
            .map(
              (c) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c['label'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    Text(
                      c['value'] as String,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: c['color'] as Color,
                      ),
                    ),
                    Text(
                      c['sub'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSensorMonitor(TelemetryProvider telemetryProvider) {
    final hasSensors = _hasInstalledSensors(telemetryProvider);
    final sensors = telemetryProvider.sensors;
    final selectedSensor = _selected(telemetryProvider);

    return Container(
      margin: const EdgeInsets.all(12),
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
            'Monitor Sensor Spesifik',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const Text(
            'Pilih area untuk melihat detail metrik.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (!hasSensors || selectedSensor == null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'Belum ada sensor terpasang. Data sensor akan muncul setelah perangkat IoT aktif.',
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                _MetricBox(
                  label: 'STATUS',
                  value: 'Tidak Ada',
                  color: AppTheme.textDark,
                  flex: 2,
                ),
                SizedBox(width: 8),
                _MetricBox(
                  label: 'TINGGI AIR',
                  value: '0 cm',
                  color: AppTheme.textDark,
                  flex: 2,
                ),
                SizedBox(width: 8),
                _MetricBox(
                  label: 'KONEKSI',
                  value: '0%',
                  color: AppTheme.textDark,
                  flex: 2,
                ),
                SizedBox(width: 8),
                _MetricBox(
                  label: 'BATERAI',
                  value: '0%',
                  color: AppTheme.textDark,
                  flex: 2,
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<int>(
                value: _selectedSensorIndex,
                isExpanded: true,
                underline: const SizedBox(),
                items: sensors
                    .asMap()
                    .entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text('${e.value.name} (${e.value.sensorId})'),
                      ),
                    )
                    .toList(),
                onChanged: (i) {
                  if (i != null) {
                    setState(() => _selectedSensorIndex = i);
                    if (sensors.isNotEmpty && i < sensors.length) {
                      _loadSensorHistory(sensors[i]);
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricBox(
                  label: 'STATUS',
                  value: _sensorStatus(selectedSensor),
                  color: _sensorColor(selectedSensor),
                  flex: 2,
                ),
                const SizedBox(width: 8),
                _MetricBox(
                  label: 'TINGGI AIR',
                  value: '${(selectedSensor.waterLevel ?? 0.0).toInt()} cm',
                  color: AppTheme.textDark,
                  flex: 2,
                ),
                const SizedBox(width: 8),
                _MetricBox(
                  label: 'KONEKSI',
                  value: selectedSensor.displayConnectivity,
                  color: selectedSensor.isOnline
                      ? AppTheme.statusNormal
                      : AppTheme.statusBahaya,
                  flex: 2,
                ),
                const SizedBox(width: 8),
                _MetricBox(
                  label: 'BATERAI',
                  value: selectedSensor.batteryLevel != null
                      ? '${selectedSensor.batteryLevel}%'
                      : '-',
                  color: AppTheme.statusNormal,
                  flex: 2,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _sensorColor(selectedSensor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _sensorColor(selectedSensor).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: _sensorColor(selectedSensor),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tindakan yang Disarankan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _sensorColor(selectedSensor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _actionDesc(_sensorStatus(selectedSensor)),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._actionPoints(_sensorStatus(selectedSensor)).map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 5, right: 8),
                            decoration: BoxDecoration(
                              color: _sensorColor(selectedSensor),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              p,
                              style: const TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Peta Sensor',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            clipBehavior: Clip.hardEdge,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(-0.9490, 100.3610),
                initialZoom: 14.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ews_flood_guard',
                ),
                if (hasSensors)
                  MarkerLayer(
                    markers: sensors.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      final color = _sensorColor(s);
                      return Marker(
                        point: LatLng(s.latitude, s.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedSensorIndex = i);
                            _loadSensorHistory(s);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedSensorIndex == i
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                s.name
                                    .substring(
                                      0,
                                      s.name.length > 2 ? 2 : s.name.length,
                                    )
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _buildPriorityPanel(TelemetryProvider telemetryProvider) {
    if (!_hasInstalledSensors(telemetryProvider)) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.visibility, color: AppTheme.accentBlue, size: 16),
                SizedBox(width: 6),
                Text(
                  'Pantauan Prioritas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.accentBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Belum ada data sensor yang dapat diprioritaskan saat ini.',
              style: TextStyle(
                color: AppTheme.textGrey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final sensors = telemetryProvider.sensors;
    SensorModel worst;
    if (sensors.isNotEmpty) {
      worst = sensors.reduce((a, b) {
        final al = a.waterLevel ?? 0.0;
        final bl = b.waterLevel ?? 0.0;
        return al >= bl ? a : b;
      });
    } else {
      worst = SensorModel(
        id: '',
        sensorId: '',
        name: 'Belum Tersedia',
        type: 'WATER_LEVEL',
        latitude: 0,
        longitude: 0,
        connectivity: 'OFFLINE',
        isActive: false,
        waterLevel: 0.0,
        rainfall: 0.0,
        status: 'Normal',
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility, color: AppTheme.accentBlue, size: 16),
              SizedBox(width: 6),
              Text(
                'Pantauan Prioritas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worst.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(worst.waterLevel ?? 0.0).toInt()} cm • ${_sensorStatus(worst)}',
                  style: TextStyle(
                    color: _sensorColor(worst),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sensor ini menunjukkan level risiko tertinggi saat ini. Fokuskan perhatian Anda di area ini.',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleChartCard({
    required String title,
    required String liveValue,
    required Color color,
    required Widget chartWidget,
    List<double> values = const [],
    String unit = '',
  }) {
    double? minVal;
    double? avgVal;
    double? latestVal;
    if (values.isNotEmpty) {
      minVal = values.reduce((a, b) => a < b ? a : b);
      avgVal = values.reduce((a, b) => a + b) / values.length;
      latestVal = values.last;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Terkini: $liveValue',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: _loadingHistory
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : _historyError != null
                ? const Center(
                    child: Text(
                      'Gagal memuat data riwayat.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.statusBahaya,
                      ),
                    ),
                  )
                : chartWidget,
          ),
          if (values.isNotEmpty && !_loadingHistory && _historyError == null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatIndicator(
                  label: 'MIN',
                  value: unit == 'cm' 
                      ? '${minVal!.toInt()} $unit' 
                      : '${minVal!.toStringAsFixed(1)} $unit',
                  color: const Color(0xFF64748B),
                ),
                _buildStatIndicator(
                  label: 'RATA-RATA',
                  value: unit == 'cm' 
                      ? '${avgVal!.toInt()} $unit' 
                      : '${avgVal!.toStringAsFixed(1)} $unit',
                  color: color,
                ),
                _buildStatIndicator(
                  label: 'TERKINI',
                  value: unit == 'cm' 
                      ? '${latestVal!.toInt()} $unit' 
                      : '${latestVal!.toStringAsFixed(1)} $unit',
                  color: const Color(0xFF22C55E),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatIndicator({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(TelemetryProvider telemetryProvider) {
    final hasSensors = _hasInstalledSensors(telemetryProvider);
    if (!hasSensors) {
      return const SizedBox();
    }

    final selectedSensor = _selected(telemetryProvider);
    if (selectedSensor == null) {
      return const SizedBox();
    }
    final waterLevel = selectedSensor.waterLevel ?? 0.0;
    final rainfall = selectedSensor.rainfall ?? 0.0;
    final currentFlow = _frHistory.isNotEmpty
        ? _frHistory.last.flowRate
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            'Grafik Telemetri Historis',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textDark,
            ),
          ),
        ),
        _buildSingleChartCard(
          title: 'Grafik Tinggi Air',
          liveValue: '${waterLevel.toInt()} cm',
          color: AppTheme.accentBlue,
          values: _wlHistory.map((e) => (e as WaterLevelLog).waterLevel).toList(),
          unit: 'cm',
          chartWidget: _buildFlChart(
            _wlHistory,
            (log) => (log as WaterLevelLog).waterLevel,
            AppTheme.accentBlue,
            'cm',
          ),
        ),
        _buildSingleChartCard(
          title: 'Grafik Curah Hujan',
          liveValue: '${rainfall.toStringAsFixed(1)} mm/jam',
          color: const Color(0xFF10B981),
          values: _rfHistory.map((e) => (e as RainfallLog).rainfall).toList(),
          unit: 'mm',
          chartWidget: _buildFlChart(
            _rfHistory,
            (log) => (log as RainfallLog).rainfall,
            const Color(0xFF10B981),
            'mm',
          ),
        ),
        _buildSingleChartCard(
          title: 'Grafik Debit Aliran',
          liveValue: '${currentFlow.toStringAsFixed(1)} LPM',
          color: const Color(0xFFF59E0B),
          values: _frHistory.map((e) => (e as FlowRateLog).flowRate).toList(),
          unit: 'LPM',
          chartWidget: _buildFlChart(
            _frHistory,
            (log) => (log as FlowRateLog).flowRate,
            const Color(0xFFF59E0B),
            'LPM',
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildActionPanel() {
    return Container(
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
          const Text(
            'Aksi Darurat & Pintasan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const Text(
            'Akses cepat menu penting.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 14),
          _ShortcutTile(
            icon: Icons.map_outlined,
            label: 'Buka Peta Sensor',
            onTap: () => navIndexNotifier.value = 1,
          ),
          _ShortcutTile(
            icon: Icons.menu_book_outlined,
            label: 'Panduan Mitigasi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EdukasiScreen()),
              );
            },
          ),
          _ShortcutTile(
            icon: Icons.emergency_outlined,
            label: 'Pusat Darurat',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DaruratScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFlChart(
    List<dynamic> logs,
    double Function(dynamic) getValue,
    Color lineColor,
    String unit,
  ) {
    if (logs.isEmpty) {
      IconData iconData = Icons.waves;
      if (unit == 'mm') iconData = Icons.umbrella;
      if (unit == 'LPM') iconData = Icons.speed;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, color: const Color(0xFF94A3B8), size: 28),
            const SizedBox(height: 6),
            Text(
              'Tidak ada data dalam 24 jam terakhir.',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
      );
    }

    final spots = logs.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), getValue(e.value));
    }).toList();

    final values = spots.map((s) => s.y).toList();
    final minY = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final maxY = values.isEmpty ? 10.0 : values.reduce((a, b) => a > b ? a : b);
    final rangeY = maxY - minY;
    final paddingY = rangeY == 0 ? 5.0 : rangeY * 0.15;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (spots.length / 4).clamp(1.0, 100.0),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < logs.length) {
                  DateTime? time;
                  final log = logs[idx];
                  if (log is WaterLevelLog) {
                    time = log.recordedAt;
                  } else if (log is RainfallLog) {
                    time = log.recordedAt;
                  } else if (log is FlowRateLog) {
                    time = log.recordedAt;
                  } else {
                    final rawTime = log.recordedAt;
                    time = rawTime is DateTime
                        ? rawTime
                        : DateTime.parse(rawTime.toString());
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: logs.length > 1 ? (logs.length - 1).toDouble() : 1.0,
        minY: (minY - paddingY).clamp(0.0, double.infinity),
        maxY: maxY + paddingY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipColor: (touchedSpot) =>
                const Color(0xFF0F172A).withOpacity(0.9),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final log = logs[spot.spotIndex];
                DateTime? dt;
                if (log is WaterLevelLog) dt = log.recordedAt;
                else if (log is RainfallLog) dt = log.recordedAt;
                else if (log is FlowRateLog) dt = log.recordedAt;
                final formattedTime = dt != null
                    ? DateFormat('HH:mm:ss').format(dt)
                    : '';
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} $unit\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: formattedTime,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.normal,
                        fontSize: 9,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length <= 15,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: lineColor,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  lineColor.withValues(alpha: 0.25),
                  lineColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(int index, String label, Color color) {
    final active = _selectedChartTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedChartTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? color : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdukasiSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panduan Kesiapsiagaan Banjir',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text(
            'Pelajari langkah cepat saat mendapatkan peringatan: cek status, siapkan barang penting, dan prioritaskan evakuasi.',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildGuideStep(
            'Kuning (Waspada)',
            'Pantau kondisi dan siapkan tas siaga dengan dokumen, obat, dan makanan.',
          ),
          const SizedBox(height: 12),
          _buildGuideStep(
            'Oren (Siaga)',
            'Amankan barang berharga ke tempat tinggi dan siapkan jalur evakuasi.',
          ),
          const SizedBox(height: 12),
          _buildGuideStep(
            'Merah (Bahaya)',
            'Evakuasi segera ke lokasi aman resmi dan bantu keluarga keluar lebih dulu.',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String label, String desc, {bool showDivider = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          desc,
          style: const TextStyle(
            color: AppTheme.textGrey,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF1F5F9)),
        ],
      ],
    );
  }

  String _actionDesc(String status) {
    switch (status) {
      case 'Waspada':
        return 'Air mulai naik. Siap-siap tanpa panik.';
      case 'Siaga':
        return 'Risiko banjir makin tinggi. Fokus ke pra-evakuasi.';
      case 'Bahaya':
        return 'Kondisi kritis. Prioritas utama adalah menyelamatkan jiwa.';
      default:
        return 'Situasi saat ini aman. Tetap pantau dashboard secara berkala.';
    }
  }

  List<String> _actionPoints(String status) {
    switch (status) {
      case 'Waspada':
        return [
          'Pantau dashboard tiap 10-15 menit.',
          'Siapkan tas siaga.',
          'Pastikan rute evakuasi keluarga.',
        ];
      case 'Siaga':
        return [
          'Pindahkan barang berharga ke tempat tinggi.',
          'Siapkan kelompok rentan untuk berangkat lebih awal.',
          'Pastikan jalur evakuasi tidak terhalang.',
        ];
      case 'Bahaya':
        return [
          'Evakuasi segera ke lokasi aman resmi.',
          'Hubungi layanan darurat jika ada yang terjebak.',
          'Ikuti instruksi petugas.',
        ];
      default:
        return [
          'Pantau pembaruan level air setiap 30 menit.',
          'Pastikan notifikasi perangkat tetap aktif.',
          'Simpan jalur evakuasi sebagai antisipasi.',
        ];
    }
  }
}

class _MetricBox extends StatelessWidget {
  final String label, value;
  final Color color;
  final int flex;
  const _MetricBox({
    required this.label,
    required this.value,
    required this.color,
    required this.flex,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.accentBlue),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward, size: 16, color: AppTheme.textGrey),
          ],
        ),
      ),
    );
  }
}
