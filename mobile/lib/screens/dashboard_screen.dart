import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart'; // Ditambahkan untuk membaca state login global
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/auth_provider.dart'; // Ditambahkan untuk membedakan Admin/User
import '../models/admin_provider.dart';
import '../providers/telemetry_provider.dart';
import '../models/sensor_model.dart';
import '../models/api_service.dart';
import '../models/water_level_log.dart';
import '../models/rainfall_log.dart';
import '../models/flow_rate_log.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';
import '../widgets/ews_appbar.dart';
import 'main_navigation.dart';
import 'edukasi_screen.dart';
import 'darurat_screen.dart';

class ChartDataPoint {
  final DateTime timestamp;
  final double value;
  final String label;

  ChartDataPoint({
    required this.timestamp,
    required this.value,
    required this.label,
  });
}


class DashboardScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  const DashboardScreen({super.key, this.onRefresh});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedSensorIndex = 0;
  bool _loadingHistory = false;
  List<WaterLevelLog> _wlHistory = [];
  List<RainfallLog> _rfHistory = [];
  List<FlowRateLog> _frHistory = [];
  String? _historyError;
  final ApiService _api = ApiService();

  String _wlRange = 'day'; // 'day' | 'week'
  String _rfRange = 'day'; // 'day' | 'week'
  String _frRange = 'day'; // 'day' | 'week'


  Future<void> _loadSensorHistory(SensorModel sensor) async {
    if (!mounted) return;
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });

    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final startIso = sevenDaysAgo.toUtc().toIso8601String();
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
              limit: 500,
            )
            .catchError((e) => <WaterLevelLog>[]),
        _api
            .fetchRainfallHistory(
              sensorId: rfSensor.sensorId,
              startDate: startIso,
              endDate: endIso,
              limit: 500,
            )
            .catchError((e) => <RainfallLog>[]),
        _api
            .fetchFlowRateHistory(
              sensorId: frSensor.sensorId,
              startDate: startIso,
              endDate: endIso,
              limit: 500,
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

  String _getIndoDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Sen';
      case DateTime.tuesday:
        return 'Sel';
      case DateTime.wednesday:
        return 'Rab';
      case DateTime.thursday:
        return 'Kam';
      case DateTime.friday:
        return 'Jum';
      case DateTime.saturday:
        return 'Sab';
      case DateTime.sunday:
        return 'Min';
      default:
        return '';
    }
  }

  List<ChartDataPoint> _getProcessedWlData() {
    if (_wlHistory.isEmpty) return [];
    final sorted = List<WaterLevelLog>.from(_wlHistory)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final latestTimestamp = sorted.last.recordedAt;
    
    if (_wlRange == 'day') {
      final cutoff = latestTimestamp.subtract(const Duration(hours: 24));
      return sorted
          .where((e) => e.recordedAt.isAfter(cutoff) && e.waterLevel > 0)
          .map((e) {
            final timeStr = '${e.recordedAt.hour.toString().padLeft(2, '0')}:${e.recordedAt.minute.toString().padLeft(2, '0')}';
            return ChartDataPoint(
              timestamp: e.recordedAt,
              value: e.waterLevel,
              label: timeStr,
            );
          })
          .toList();
    } else {
      final cutoff = latestTimestamp.subtract(const Duration(days: 7));
      final weeklyLogs = sorted.where((e) => e.recordedAt.isAfter(cutoff) && e.waterLevel > 0).toList();
      final Map<String, List<WaterLevelLog>> grouped = {};
      for (final log in weeklyLogs) {
        final dateStr = DateFormat('yyyy-MM-dd').format(log.recordedAt.toLocal());
        grouped.putIfAbsent(dateStr, () => []).add(log);
      }
      final List<ChartDataPoint> points = [];
      grouped.forEach((dateStr, logs) {
        final sum = logs.fold<double>(0.0, (s, e) => s + e.waterLevel);
        final avg = sum / logs.length;
        final maxTs = logs.map((e) => e.recordedAt).reduce((a, b) => a.isAfter(b) ? a : b);
        final weekdayStr = _getIndoDayName(maxTs.toLocal().weekday);
        points.add(ChartDataPoint(
          timestamp: maxTs,
          value: avg.roundToDouble(),
          label: weekdayStr,
        ));
      });
      points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return points.length > 7 ? points.sublist(points.length - 7) : points;
    }
  }

  List<ChartDataPoint> _getProcessedRfData() {
    if (_rfHistory.isEmpty) return [];
    final sorted = List<RainfallLog>.from(_rfHistory)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final latestTimestamp = sorted.last.recordedAt;
    
    if (_rfRange == 'day') {
      final cutoff = latestTimestamp.subtract(const Duration(hours: 24));
      return sorted
          .where((e) => e.recordedAt.isAfter(cutoff))
          .map((e) {
            final timeStr = '${e.recordedAt.hour.toString().padLeft(2, '0')}:${e.recordedAt.minute.toString().padLeft(2, '0')}';
            return ChartDataPoint(
              timestamp: e.recordedAt,
              value: e.rainfall,
              label: timeStr,
            );
          })
          .toList();
    } else {
      final cutoff = latestTimestamp.subtract(const Duration(days: 7));
      final weeklyLogs = sorted.where((e) => e.recordedAt.isAfter(cutoff)).toList();
      final Map<String, List<RainfallLog>> grouped = {};
      for (final log in weeklyLogs) {
        final dateStr = DateFormat('yyyy-MM-dd').format(log.recordedAt.toLocal());
        grouped.putIfAbsent(dateStr, () => []).add(log);
      }
      final List<ChartDataPoint> points = [];
      grouped.forEach((dateStr, logs) {
        final sum = logs.fold<double>(0.0, (s, e) => s + e.rainfall);
        final avg = sum / logs.length;
        final maxTs = logs.map((e) => e.recordedAt).reduce((a, b) => a.isAfter(b) ? a : b);
        final weekdayStr = _getIndoDayName(maxTs.toLocal().weekday);
        points.add(ChartDataPoint(
          timestamp: maxTs,
          value: double.parse(avg.toStringAsFixed(2)),
          label: weekdayStr,
        ));
      });
      points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return points.length > 7 ? points.sublist(points.length - 7) : points;
    }
  }

  List<ChartDataPoint> _getProcessedFrData() {
    if (_frHistory.isEmpty) return [];
    final sorted = List<FlowRateLog>.from(_frHistory)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final latestTimestamp = sorted.last.recordedAt;
    
    if (_frRange == 'day') {
      final cutoff = latestTimestamp.subtract(const Duration(hours: 24));
      return sorted
          .where((e) => e.recordedAt.isAfter(cutoff))
          .map((e) {
            final timeStr = '${e.recordedAt.hour.toString().padLeft(2, '0')}:${e.recordedAt.minute.toString().padLeft(2, '0')}';
            return ChartDataPoint(
              timestamp: e.recordedAt,
              value: e.flowRate,
              label: timeStr,
            );
          })
          .toList();
    } else {
      final cutoff = latestTimestamp.subtract(const Duration(days: 7));
      final weeklyLogs = sorted.where((e) => e.recordedAt.isAfter(cutoff)).toList();
      final Map<String, List<FlowRateLog>> grouped = {};
      for (final log in weeklyLogs) {
        final dateStr = DateFormat('yyyy-MM-dd').format(log.recordedAt.toLocal());
        grouped.putIfAbsent(dateStr, () => []).add(log);
      }
      final List<ChartDataPoint> points = [];
      grouped.forEach((dateStr, logs) {
        final sum = logs.fold<double>(0.0, (s, e) => s + e.flowRate);
        final avg = sum / logs.length;
        final maxTs = logs.map((e) => e.recordedAt).reduce((a, b) => a.isAfter(b) ? a : b);
        final weekdayStr = _getIndoDayName(maxTs.toLocal().weekday);
        points.add(ChartDataPoint(
          timestamp: maxTs,
          value: double.parse(avg.toStringAsFixed(2)),
          label: weekdayStr,
        ));
      });
      points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return points.length > 7 ? points.sublist(points.length - 7) : points;
    }
  }

  String _formatValue(double val, String unit) {
    final displayUnit = unit == 'L/min' ? 'L/m' : unit;
    if (unit == 'cm') {
      return '${val.toInt()} $displayUnit';
    }
    if (val == val.toInt()) {
      return '${val.toInt()} $displayUnit';
    }
    return '${val.toStringAsFixed(1)} $displayUnit';
  }

  Future<void> _handlePdfExport(String type, String sensorId) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${context.t('downloadingReport')} PDF...')),
    );
    
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      final startIso = DateFormat("yyyy-MM-dd'T'00:00:00.000'Z'").format(sevenDaysAgo);
      final endIso = DateFormat("yyyy-MM-dd'T'23:59:59.000'Z'").format(now);
      
      final bytes = await _api.downloadReportBytes(
        type: type,
        startDate: startIso,
        endDate: endIso,
        format: 'pdf',
        sensorId: sensorId,
      );

      final dir = await getApplicationDocumentsDirectory();
      final filename = 'ews-report-$type-${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      final openResult = await OpenFilex.open(file.path);
      if (!mounted) return;
      if (openResult.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.t('downloadSuccess')} ${file.path}. ${openResult.message}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.t('downloadSuccess')} ${file.path}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.t('exportFailed')} ${e.toString()}'),
          backgroundColor: AppTheme.statusBahaya,
        ),
      );
    }
  }

  String _sensorStatusKey(SensorModel sensor) {
    final raw = (sensor.status ?? '').toString().toUpperCase();
    if (raw == 'DANGER' || raw == 'BAHAYA') {
      return 'danger';
    }
    if (raw == 'ALERT' || raw == 'WARNING' || raw == 'WASPADA') {
      return 'warning';
    }
    if (raw == 'NORMAL' || raw == 'SAFE' || raw == 'AMAN') {
      return 'normal';
    }
    return sensor.isOnline ? 'normal' : 'offline';
  }

  String _sensorStatusLabel(BuildContext context, SensorModel sensor) {
    final key = _sensorStatusKey(sensor);
    if (key == 'danger') return context.t('danger');
    if (key == 'warning') return context.t('warning');
    if (key == 'offline') return context.t('offline');
    return context.t('normal');
  }

  Color _sensorColor(SensorModel sensor) {
    final statusKey = _sensorStatusKey(sensor);
    if (statusKey == 'danger') return AppTheme.statusBahaya;
    if (statusKey == 'warning') return AppTheme.statusWaspada;
    if (statusKey == 'offline') return const Color(0xFF94A3B8);
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
              content: Text('${context.t('errorLoadDashboard')} $e'),
              backgroundColor: AppTheme.statusBahaya,
            ),
          );
        }
      }
    });
  }

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
                    sensor['battery_level'] ?? sensor['batteryLevel'];

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
          children: [
            Text(
              context.t('overallStatusTitle'),
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.t('noSensorStatusAvailable'),
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.t('noSensorStatusSubtitle'),
              style: const TextStyle(
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
    final globalLabelKey = hasDanger
        ? 'danger'
        : hasAlert
            ? 'warning'
            : 'safe';
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
    final ts = DateFormat('dd/MM/yyyy, HH.mm').format(u);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('overallStatusTitle'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t(globalLabelKey).toUpperCase(),
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
                Text(
                  context.t('lastUpdate'),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
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
        'label': context.t('activeWaterLevel'),
        'value': hasSensors ? '${maxLevel.toInt()} cm' : '0 cm',
        'sub': hasSensors ? context.t('currentPeak') : context.t('noSensorsAvailable'),
        'color': AppTheme.accentBlue,
      },
      {
        'label': context.t('rainfallLabel'),
        'value': hasSensors
            ? '${avgRainfall.toStringAsFixed(0)} mm/j'
            : '0 mm/j',
        'sub': hasSensors
            ? (avgRainfall < 5 ? context.t('rainfallLight') : context.t('rainfallModerate'))
            : context.t('noSensorsAvailable'),
        'color': AppTheme.statusWaspada,
      },
      {
        'label': context.t('riskSensors'),
        'value': '$riskCount',
        'sub': '${context.t('danger')}: $dangerCount • ${context.t('warning')}: $warningCount',
        'color': riskCount > 0 ? AppTheme.statusBahaya : AppTheme.statusNormal,
      },
      {
        'label': context.t('sensorOnlineActive'),
        'value': hasSensors ? '$onlineCount/$totalSensors' : '0/0',
        'sub': hasSensors ? context.t('sensorOnlineActive') : context.t('noSensorsAvailable'),
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
          Text(
            context.t('sensorMonitorTitle'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            context.t('sensorMonitorSubtitle'),
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
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
              child: Text(
                context.t('noSensorsInstalled'),
                style: const TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricBox(
                  label: context.t('statusLabel'),
                  value: context.t('notAvailable'),
                  color: AppTheme.textDark,
                  flex: 2,
                ),
                SizedBox(width: 8),
                _MetricBox(
                  label: context.t('waterLevelLabel'),
                  value: '0 cm',
                  color: AppTheme.textDark,
                  flex: 2,
                ),
                SizedBox(width: 8),
                _MetricBox(
                  label: context.t('connectivityLabel'),
                  value: '0%',
                  color: AppTheme.textDark,
                  flex: 2,
                ),
                SizedBox(width: 8),
                _MetricBox(
                  label: context.t('batteryLabel'),
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
                  label: context.t('statusLabel'),
                  value: _sensorStatusLabel(context, selectedSensor),
                  color: _sensorColor(selectedSensor),
                  flex: 2,
                ),
                const SizedBox(width: 8),
                _MetricBox(
                  label: context.t('waterLevelLabel'),
                  value: '${(selectedSensor.waterLevel ?? 0.0).toInt()} cm',
                  color: AppTheme.textDark,
                  flex: 2,
                ),
                const SizedBox(width: 8),
                _MetricBox(
                  label: context.t('connectivityLabel'),
                  value: selectedSensor.displayConnectivity,
                  color: selectedSensor.isOnline
                      ? AppTheme.statusNormal
                      : AppTheme.statusBahaya,
                  flex: 2,
                ),
                const SizedBox(width: 8),
                _MetricBox(
                  label: context.t('batteryLabel'),
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
                color: _sensorColor(selectedSensor).withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _sensorColor(selectedSensor).withAlpha(77),
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
                        context.t('recommendedActionsTitle'),
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
                    _actionDesc(context, _sensorStatusKey(selectedSensor)),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._actionPoints(context, _sensorStatusKey(selectedSensor)).map(
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
          Text(
            context.t('sensorMapTitle'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                                  color: color.withAlpha(128),
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
          children: [
            Row(
              children: [
                const Icon(Icons.visibility, color: AppTheme.accentBlue, size: 16),
                const SizedBox(width: 6),
                Text(
                  context.t('priorityMonitoringTitle'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.accentBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.t('priorityMonitoringEmpty'),
              style: const TextStyle(
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
        name: context.t('sensorUnavailable'),
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
          Row(
            children: [
              const Icon(Icons.visibility, color: AppTheme.accentBlue, size: 16),
              const SizedBox(width: 6),
              Text(
                context.t('priorityMonitoringTitle'),
                style: const TextStyle(
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
                  '${(worst.waterLevel ?? 0.0).toInt()} cm • ${_sensorStatusLabel(context, worst)}',
                  style: TextStyle(
                    color: _sensorColor(worst),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.t('prioritySensorNote'),
                  style: const TextStyle(
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
    required List<ChartDataPoint> processedPoints,
    required String range,
    required ValueChanged<String> onRangeChanged,
    required String unit,
    required String telemetryType,
    required String sensorId,
  }) {
    double? minVal;
    double? avgVal;
    double? latestVal;
    if (processedPoints.isNotEmpty) {
      final values = processedPoints.map((e) => e.value).toList();
      minVal = values.reduce((a, b) => a < b ? a : b);
      avgVal = values.reduce((a, b) => a + b) / values.length;
      latestVal = values.last;
    }

    final bool isRain = telemetryType == 'rainfall';
    final accentColor = isRain ? const Color(0xFF06B6D4) : color;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(8),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              InkWell(
                onTap: () => _handlePdfExport(telemetryType == 'flow_rate' ? 'combined' : telemetryType, sensorId),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.picture_as_pdf,
                        size: 11,
                        color: Color(0xFFBE123C),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'PDF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFBE123C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _buildPillTab(
                        label: context.t('day'),
                        isActive: range == 'day',
                        onTap: () => onRangeChanged('day'),
                      ),
                      _buildPillTab(
                        label: context.t('week'),
                        isActive: range == 'week',
                        onTap: () => onRangeChanged('week'),
                      ),
                    ],
                  ),
                ),
                _buildLiveBadge(telemetryType, liveValue),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
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
                    : processedPoints.isEmpty
                        ? _buildEmptyState(telemetryType)
                        : chartWidget,
          ),
          if (processedPoints.isNotEmpty && !_loadingHistory && _historyError == null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatIndicator(
                    label: context.t('minimum'),
                    value: _formatValue(minVal!, unit),
                    color: const Color(0xFF3B82F6),
                    telemetryType: telemetryType,
                    statType: 'min',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatIndicator(
                    label: context.t('average'),
                    value: _formatValue(avgVal!, unit),
                    color: accentColor,
                    telemetryType: telemetryType,
                    statType: 'avg',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatIndicator(
                    label: context.t('current'),
                    value: _formatValue(latestVal!, unit),
                    color: isRain ? const Color(0xFF06B6D4) : const Color(0xFF10B981),
                    telemetryType: telemetryType,
                    statType: 'latest',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPillTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBadge(String telemetryType, String liveValue) {
    if (telemetryType == 'flow_rate') {
      final double val = double.tryParse(liveValue.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      final bool isHigh = val >= 20.0;
      final bool isMed = val >= 10.0 && val < 20.0;
      
      final String label = isHigh ? 'Debit Tinggi' : isMed ? 'Debit Sedang' : 'Debit Rendah';
      final Color bg = isHigh 
          ? const Color(0xFFFFF1F2) 
          : isMed 
              ? const Color(0xFFFFFBEB) 
              : const Color(0xFFECFDF5);
      final Color border = isHigh 
          ? const Color(0xFFFECDD3) 
          : isMed 
              ? const Color(0xFFFEF3C7) 
              : const Color(0xFFD1FAE5);
      final Color text = isHigh 
          ? const Color(0xFFBE123C) 
          : isMed 
              ? const Color(0xFFB45309) 
              : const Color(0xFF047857);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(
          '$label ($liveValue)',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: text,
          ),
        ),
      );
    }

    final bool isRain = telemetryType == 'rainfall';
    final Color badgeBg = isRain ? const Color(0xFFECFEFF) : const Color(0xFFEFF6FF);
    final Color badgeBorder = isRain ? const Color(0xFFCFFAFE) : const Color(0xFFDBEAFE);
    final Color badgeText = isRain ? const Color(0xFF0E7490) : const Color(0xFF1E40AF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeBorder),
      ),
      child: Text(
        'Live: $liveValue',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: badgeText,
        ),
      ),
    );
  }

  Widget _buildStatIndicator({
    required String label,
    required String value,
    required Color color,
    required String telemetryType,
    required String statType,
  }) {
    final bool isRain = telemetryType == 'rainfall';
    final Color accentColor = isRain ? const Color(0xFF06B6D4) : const Color(0xFF10B981);
    
    Widget? leftIcon;
    BoxDecoration cardDeco;
    
    if (statType == 'min') {
      leftIcon = Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.arrow_downward,
          size: 12,
          color: Color(0xFF3B82F6),
        ),
      );
      
      cardDeco = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      );
    } else if (statType == 'avg') {
      leftIcon = Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isRain ? const Color(0xFFECFEFF) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.swap_horiz,
          size: 12,
          color: accentColor,
        ),
      );
      
      cardDeco = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      );
    } else {
      leftIcon = Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isRain ? const Color(0xFFECFEFF) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
      
      cardDeco = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRain ? const Color(0xFFCFFAFE) : const Color(0xFFD1FAE5),
        ),
      );
    }

    return Container(
      decoration: cardDeco.copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (statType == 'latest')
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3.5,
              child: Container(
                color: accentColor,
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              statType == 'latest' ? 12 : 10,
              8,
              10,
              8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    leftIcon,
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: statType == 'latest' ? (isRain ? const Color(0xFF0E7490) : const Color(0xFF047857)) : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String telemetryType) {
    String desc = context.t('noWaterLevelData');
    if (telemetryType == 'rainfall') {
      desc = context.t('noRainfallData');
    } else if (telemetryType == 'flow_rate') {
      desc = context.t('noFlowRateData');
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC).withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: Color(0xFF94A3B8),
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No Data Available',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
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
    final processedFr = _getProcessedFrData();
    final currentFlow = processedFr.isNotEmpty
        ? processedFr.last.value
        : 0.0;

    final processedWl = _getProcessedWlData();
    final processedRf = _getProcessedRfData();

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
          title: context.t('waterLevelGraphTitle'),
          liveValue: '${waterLevel.toInt()} cm',
          color: AppTheme.accentBlue,
          processedPoints: processedWl,
          range: _wlRange,
          onRangeChanged: (val) {
            setState(() => _wlRange = val);
          },
          unit: 'cm',
          telemetryType: 'water_level',
          sensorId: selectedSensor.sensorId,
          chartWidget: _buildFlChart(
            processedWl,
            AppTheme.accentBlue,
            'cm',
            'water_level',
          ),
        ),
        _buildSingleChartCard(
          title: context.t('rainfallGraphTitle'),
          liveValue: '${rainfall.toStringAsFixed(1)} mm',
          color: const Color(0xFF06B6D4),
          processedPoints: processedRf,
          range: _rfRange,
          onRangeChanged: (val) {
            setState(() => _rfRange = val);
          },
          unit: 'mm',
          telemetryType: 'rainfall',
          sensorId: selectedSensor.sensorId,
          chartWidget: _buildFlChart(
            processedRf,
            const Color(0xFF3B82F6),
            'mm',
            'rainfall',
          ),
        ),
        _buildSingleChartCard(
          title: context.t('flowRateGraphTitle'),
          liveValue: '${currentFlow.toStringAsFixed(1)} L/m',
          color: const Color(0xFF10B981),
          processedPoints: processedFr,
          range: _frRange,
          onRangeChanged: (val) {
            setState(() => _frRange = val);
          },
          unit: 'L/m',
          telemetryType: 'flow_rate',
          sensorId: selectedSensor.sensorId,
          chartWidget: _buildFlChart(
            processedFr,
            const Color(0xFF3B82F6),
            'L/m',
            'flow_rate',
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
          Text(
            context.t('actionPanelTitle'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            context.t('actionPanelSubtitle'),
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 14),
          _ShortcutTile(
            icon: Icons.map_outlined,
            label: context.t('openSensorMap'),
            onTap: () => navIndexNotifier.value = 1,
          ),
          _ShortcutTile(
            icon: Icons.menu_book_outlined,
            label: context.t('mitigationGuide'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EdukasiScreen()),
              );
            },
          ),
          _ShortcutTile(
            icon: Icons.emergency_outlined,
            label: context.t('emergencyContacts'),
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
    List<ChartDataPoint> processedData,
    Color lineColor,
    String unit,
    String telemetryType,
  ) {
    if (processedData.isEmpty) {
      return const SizedBox();
    }

    if (telemetryType == 'flow_rate') {
      final barGroups = processedData.asMap().entries.map((e) {
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: e.value.value,
              color: const Color(0xFF3B82F6),
              width: 14,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        );
      }).toList();

      final maxVal = processedData.map((s) => s.value).reduce((a, b) => a > b ? a : b);
      final paddingY = maxVal * 0.15 == 0 ? 5.0 : maxVal * 0.15;

      return BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
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
                interval: (barGroups.length / 4).clamp(1.0, 100.0),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < processedData.length) {
                    return SideTitleWidget(
                      meta: meta,
                      space: 6,
                      child: Text(
                        processedData[idx].label,
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
          minY: 0.0,
          maxY: maxVal + paddingY,
          barGroups: barGroups,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipColor: (group) => const Color(0xFF0F172A).withAlpha(230),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final pt = processedData[groupIndex];
                final formattedTime = DateFormat('HH:mm:ss').format(pt.timestamp);
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(1)} $unit\n',
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
              },
            ),
          ),
        ),
      );
    }

    final spots = processedData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final values = spots.map((s) => s.y).toList();
    final minY = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final maxY = values.isEmpty ? 10.0 : values.reduce((a, b) => a > b ? a : b);
    final rangeY = maxY - minY;
    final paddingY = rangeY == 0 ? 5.0 : rangeY * 0.15;

    final chartColor = const Color(0xFF3B82F6);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
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
                if (idx >= 0 && idx < processedData.length) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      processedData[idx].label,
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
        maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1.0,
        minY: (minY - paddingY).clamp(0.0, double.infinity),
        maxY: maxY + paddingY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipColor: (touchedSpot) =>
                const Color(0xFF0F172A).withAlpha(230),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final pt = processedData[spot.spotIndex];
                final formattedTime = DateFormat('HH:mm:ss').format(pt.timestamp);
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
            color: chartColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            showingIndicators: const [],
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  chartColor.withValues(alpha: 0.25),
                  chartColor.withValues(alpha: 0.0),
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
          Text(
            context.t('floodPreparednessGuideTitle'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            context.t('floodPreparednessGuideSubtitle'),
            style: const TextStyle(
              color: AppTheme.textGrey,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildGuideStep(
            context.t('guideStepWarningLabel'),
            context.t('guideStepWarningDesc'),
          ),
          const SizedBox(height: 12),
          _buildGuideStep(
            context.t('guideStepAlertLabel'),
            context.t('guideStepAlertDesc'),
          ),
          const SizedBox(height: 12),
          _buildGuideStep(
            context.t('guideStepDangerLabel'),
            context.t('guideStepDangerDesc'),
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

  String _actionDesc(BuildContext context, String statusKey) {
    switch (statusKey) {
      case 'warning':
        return context.t('actionDescWarning');
      case 'alert':
        return context.t('actionDescAlert');
      case 'danger':
        return context.t('actionDescDanger');
      default:
        return context.t('actionDescNormal');
    }
  }

  List<String> _actionPoints(BuildContext context, String statusKey) {
    switch (statusKey) {
      case 'warning':
        return [
          context.t('actionPointWarning1'),
          context.t('actionPointWarning2'),
          context.t('actionPointWarning3'),
        ];
      case 'alert':
        return [
          context.t('actionPointAlert1'),
          context.t('actionPointAlert2'),
          context.t('actionPointAlert3'),
        ];
      case 'danger':
        return [
          context.t('actionPointDanger1'),
          context.t('actionPointDanger2'),
          context.t('actionPointDanger3'),
        ];
      default:
        return [
          context.t('actionPointNormal1'),
          context.t('actionPointNormal2'),
          context.t('actionPointNormal3'),
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
