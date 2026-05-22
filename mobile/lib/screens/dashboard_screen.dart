import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart'; // Ditambahkan untuk membaca state login global
import '../models/auth_provider.dart'; // Ditambahkan untuk membedakan Admin/User
import '../models/admin_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ews_appbar.dart';
import '../models/sensor_model.dart';
import 'main_navigation.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  const DashboardScreen({super.key, this.onRefresh});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedSensorIndex = 0;

  bool _hasInstalledSensors(AdminProvider admin) =>
      (admin.dashboardStats['totalSensors'] ?? 0) > 0 ||
      admin.sensors.isNotEmpty;

  SensorData _selected(AdminProvider admin) {
    final waterLevels =
        admin.dashboardStats['waterLevels'] as List<dynamic>? ?? [];
    if (waterLevels.isNotEmpty && _selectedSensorIndex < waterLevels.length) {
      final m = waterLevels[_selectedSensorIndex] as Map<String, dynamic>;
      return SensorData(
        name: m['sensorId']?.toString() ?? 'Sensor',
        location: m['location']?.toString() ?? '-',
        waterLevel: (m['waterLevel'] is num)
            ? (m['waterLevel'] as num).toDouble()
            : 0.0,
        rainfall: (m['rainfall'] is num)
            ? (m['rainfall'] as num).toDouble()
            : 0.0,
        status: m['status']?.toString() ?? 'Normal',
        lastUpdate:
            DateTime.tryParse(m['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
      );
    }
    return SensorData(
      name: 'Sensor Belum Tersedia',
      location: '-',
      waterLevel: 0,
      rainfall: 0,
      status: 'Normal',
      lastUpdate: DateTime.now(),
    );
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
  final List<Map<String, String>> _adminSensorsData = [
    {
      'id': 'EWS-WL-001',
      'name': 'Sensor Hulu Batang Arau',
      'type': 'WATER_LEVEL',
      'status': 'ONLINE',
      'battery': '88%',
    },
    {
      'id': 'EWS-WL-002',
      'name': 'Sensor Tengah Batang Arau',
      'type': 'WATER_LEVEL',
      'status': 'ONLINE',
      'battery': '76%',
    },
    {
      'id': 'EWS-WL-003',
      'name': 'Sensor Hilir Batang Arau',
      'type': 'WATER_LEVEL',
      'status': 'ONLINE',
      'battery': '59%',
    },
    {
      'id': 'EWS-RF-001',
      'name': 'Rain Gauge Padang Barat',
      'type': 'RAINFALL',
      'status': 'ONLINE',
      'battery': '83%',
    },
    {
      'id': 'EWS-RF-002',
      'name': 'Rain Gauge Padang Utara',
      'type': 'RAINFALL',
      'status': 'ONLINE',
      'battery': '71%',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Ambil status peran dari AuthProvider
    final authProvider = context.watch<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final String currentRole = authProvider.userRole.toString().toUpperCase();
    final bool isAdmin =
        currentRole == 'ADMIN' || currentRole == 'USERROLE.ADMIN';

    // 2. Jika Admin, langsung tampilkan inventaris manajemen infrastruktur IoT petugas
    if (isAdmin) {
      return _buildAdminDashboard();
    }

    // 3. Jika User biasa, render layout grafik peta bawaan asli Anda
    return Scaffold(
      appBar: EWSAppBar(onRefresh: widget.onRefresh),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusBanner(adminProvider),
            _buildMetricCards(adminProvider),
            _buildSensorMonitor(adminProvider),
            _buildActionPanel(),
            _buildPriorityPanel(adminProvider),
            _buildChartSection(adminProvider),
            _buildEdukasiSection(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAMPILAN KHUSUS MANAJEMEN ALAT IOT (HANYA KELUAR JIKA LOGIN SEBAGAI ADMIN)
  // =========================================================================
  Widget _buildAdminDashboard() {
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
                    'Total: ${_adminSensorsData.length}',
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
              itemCount: _adminSensorsData.length,
              itemBuilder: (context, index) {
                final sensor = _adminSensorsData[index];
                final isWater = sensor['type'] == 'WATER_LEVEL';

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
                            sensor['id']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: AppTheme.accentBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sensor['name']!,
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
                                sensor['type']!,
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
                                sensor['battery']!,
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
                          sensor['status']!,
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

  Widget _buildStatusBanner(AdminProvider adminProvider) {
    if (!_hasInstalledSensors(adminProvider)) {
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

    final waterLevels =
        adminProvider.dashboardStats['waterLevels'] as List<dynamic>? ?? [];
    Map<String, dynamic>? worstMap;
    if (waterLevels.isNotEmpty) {
      worstMap =
          waterLevels.reduce((a, b) {
                final al = (a is Map && a['waterLevel'] is num)
                    ? (a['waterLevel'] as num).toDouble()
                    : 0.0;
                final bl = (b is Map && b['waterLevel'] is num)
                    ? (b['waterLevel'] as num).toDouble()
                    : 0.0;
                return al >= bl ? a : b;
              })
              as Map<String, dynamic>?;
    }
    final worst = worstMap != null
        ? SensorData(
            name: worstMap['sensorId']?.toString() ?? 'Sensor',
            location: worstMap['location']?.toString() ?? '-',
            waterLevel: (worstMap['waterLevel'] is num)
                ? (worstMap['waterLevel'] as num).toDouble()
                : 0.0,
            rainfall: (worstMap['rainfall'] is num)
                ? (worstMap['rainfall'] as num).toDouble()
                : 0.0,
            status: worstMap['status']?.toString() ?? 'Normal',
            lastUpdate:
                DateTime.tryParse(worstMap['updatedAt']?.toString() ?? '') ??
                DateTime.now(),
          )
        : SensorData(
            name: 'Sensor Belum Tersedia',
            location: '-',
            waterLevel: 0,
            rainfall: 0,
            status: 'Normal',
            lastUpdate: DateTime.now(),
          );
    final color = worst.statusColor;
    final u = worst.lastUpdate;
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
            worst.status.toUpperCase(),
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

  Widget _buildMetricCards(AdminProvider adminProvider) {
    final hasSensors = _hasInstalledSensors(adminProvider);
    final sensors = hasSensors ? adminProvider.sensors : [];
    final waterLevelsList =
        adminProvider.dashboardStats['waterLevels'] as List<dynamic>? ?? [];
    final maxWater = waterLevelsList.isNotEmpty
        ? SensorData(
            name: waterLevelsList.first['sensorId']?.toString() ?? 'Sensor',
            location: waterLevelsList.first['location']?.toString() ?? '-',
            waterLevel: (waterLevelsList
                .map(
                  (e) => (e is Map && e['waterLevel'] is num)
                      ? (e['waterLevel'] as num).toDouble()
                      : 0.0,
                )
                .reduce((a, b) => a > b ? a : b)),
            rainfall: 0,
            status: 'Normal',
            lastUpdate: DateTime.now(),
          )
        : SensorData(
            name: 'Belum Tersedia',
            location: '-',
            waterLevel: 0,
            rainfall: 0,
            status: 'Normal',
            lastUpdate: DateTime.now(),
          );
    final avgRainfall = adminProvider.dashboardStats['avgRainfall'] ?? 0.0;
    final risky =
        (adminProvider.dashboardStats['recentAlerts'] as List<dynamic>?)
            ?.length ??
        0;
    final cards = [
      {
        'label': 'Tinggi Air (Aktif)',
        'value': hasSensors ? '${maxWater.waterLevel.toInt()} cm' : '0 cm',
        'sub': hasSensors ? maxWater.name : 'Belum ada sensor terpasang',
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
        'value': '$risky',
        'sub': 'Bahaya: 0 • Waspada: $risky',
        'color': risky > 0 ? AppTheme.statusBahaya : AppTheme.statusNormal,
      },
      {
        'label': 'Konektivitas',
        'value': hasSensors ? '${sensors.length}/${sensors.length}' : '0/0',
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

  Widget _buildSensorMonitor(AdminProvider adminProvider) {
    final hasSensors = _hasInstalledSensors(adminProvider);
    final waterLevelsList =
        adminProvider.dashboardStats['waterLevels'] as List<dynamic>? ?? [];
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
          if (!hasSensors) ...[
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
                items: (waterLevelsList)
                    .asMap()
                    .entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          e.value['sensorId']?.toString() ?? 'Sensor',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (i) {
                  if (i != null) setState(() => _selectedSensorIndex = i);
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricBox(
                  label: 'STATUS',
                  value: _selected(adminProvider).status,
                  color: _selected(adminProvider).statusColor,
                  flex: 2,
                ),
                const SizedBox(width: 8),
                _MetricBox(
                  label: 'TINGGI AIR',
                  value: '${_selected(adminProvider).waterLevel.toInt()} cm',
                  color: AppTheme.textDark,
                  flex: 2,
                ),
                const SizedBox(width: 8),
                _MetricBox(
                  label: 'KONEKSI',
                  value: 'Online',
                  color: AppTheme.statusNormal,
                  flex: 2,
                ),
                const SizedBox(width: 8),
                _MetricBox(
                  label: 'BATERAI',
                  value: '87%',
                  color: AppTheme.statusNormal,
                  flex: 2,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selected(
                  adminProvider,
                ).statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selected(
                    adminProvider,
                  ).statusColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: _selected(adminProvider).statusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tindakan yang Disarankan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _selected(adminProvider).statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _actionDesc(_selected(adminProvider).status),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._actionPoints(_selected(adminProvider).status).map(
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
                              color: _selected(adminProvider).statusColor,
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
                center: LatLng(-0.9490, 100.3610),
                zoom: 14.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ews_flood_guard',
                ),
                if (hasSensors)
                  MarkerLayer(
                    markers: _sensorLocations.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      final color = Color(s['colorVal'] as int);
                      return Marker(
                        point: LatLng(s['lat'] as double, s['lng'] as double),
                        width: 40,
                        height: 40,
                        builder: (context) => GestureDetector(
                          onTap: () => setState(() => _selectedSensorIndex = i),
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
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                s['label'] as String,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => navIndexNotifier.value = 3,
              icon: const Icon(Icons.phone, size: 18),
              label: const Text(
                'Kontak Darurat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusBahaya,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _ShortcutTile(
            icon: Icons.map_outlined,
            label: 'Buka Peta Sensor',
            onTap: () => navIndexNotifier.value = 2,
          ),
          _ShortcutTile(
            icon: Icons.menu_book_outlined,
            label: 'Panduan Mitigasi',
            onTap: () => navIndexNotifier.value = 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityPanel(AdminProvider adminProvider) {
    if (!_hasInstalledSensors(adminProvider)) {
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

    final waterLevels =
        adminProvider.dashboardStats['waterLevels'] as List<dynamic>? ?? [];
    SensorData worst;
    if (waterLevels.isNotEmpty) {
      final worstMap =
          waterLevels.reduce((a, b) {
                final al = (a is Map && a['waterLevel'] is num)
                    ? (a['waterLevel'] as num).toDouble()
                    : 0.0;
                final bl = (b is Map && b['waterLevel'] is num)
                    ? (b['waterLevel'] as num).toDouble()
                    : 0.0;
                return al >= bl ? a : b;
              })
              as Map<String, dynamic>;
      worst = SensorData(
        name: worstMap['sensorId']?.toString() ?? 'Sensor',
        location: worstMap['location']?.toString() ?? '-',
        waterLevel: (worstMap['waterLevel'] is num)
            ? (worstMap['waterLevel'] as num).toDouble()
            : 0.0,
        rainfall: (worstMap['rainfall'] is num)
            ? (worstMap['rainfall'] as num).toDouble()
            : 0.0,
        status: worstMap['status']?.toString() ?? 'Normal',
        lastUpdate:
            DateTime.tryParse(worstMap['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
      );
    } else {
      worst = SensorData(
        name: 'Belum Tersedia',
        location: '-',
        waterLevel: 0,
        rainfall: 0,
        status: 'Normal',
        lastUpdate: DateTime.now(),
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
                const Text(
                  'Sensor',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${worst.waterLevel.toInt()} cm • ${worst.status}',
                  style: TextStyle(
                    color: worst.statusColor,
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

  Widget _buildChartSection(AdminProvider adminProvider) {
    final hasSensors = _hasInstalledSensors(adminProvider);
    final current = _selected(adminProvider).waterLevel;
    final chartData = hasSensors
        ? [
            {'time': '08:00', 'level': (current * 0.72).roundToDouble()},
            {'time': '10:00', 'level': (current * 0.85).roundToDouble()},
            {'time': '12:00', 'level': (current * 0.93).roundToDouble()},
            {'time': '14:00', 'level': (current * 1.05).roundToDouble()},
            {'time': '16:00', 'level': current},
          ]
        : [
            {'time': '08:00', 'level': 0.0},
            {'time': '10:00', 'level': 0.0},
            {'time': '12:00', 'level': 0.0},
            {'time': '14:00', 'level': 0.0},
            {'time': '16:00', 'level': 0.0},
          ];
    Color levelColor(double lvl) {
      if (lvl < 150) return AppTheme.statusNormal;
      if (lvl < 190) return AppTheme.statusWaspada;
      if (lvl < 220) return AppTheme.statusSiaga;
      return AppTheme.statusBahaya;
    }

    final maxLevelInChart = chartData
        .map((d) => d['level'] as double)
        .reduce((a, b) => a > b ? a : b);
    final u = _selected(adminProvider).lastUpdate;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                'Grafik Ketinggian Air',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.statusNormal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Live: ${current.toInt()} cm',
                  style: const TextStyle(
                    color: AppTheme.statusNormal,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: chartData.map((d) {
                final lvl = d['level'] as double;
                final color = levelColor(lvl);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${lvl.toInt()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 42,
                      height: (lvl / maxLevelInChart * 100).clamp(8.0, 100.0),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.8),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d['time'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Ketinggian Air (cm) - ${u.day} Mar ${u.year}',
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Curah Hujan Terkini',
                      style: TextStyle(fontSize: 11, color: AppTheme.textGrey),
                    ),
                    Text(
                      '${_selected(adminProvider).rainfall} mm/jam',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                    Text(
                      _selected(adminProvider).rainfall < 5
                          ? 'Ringan (0-5 mm/jam)'
                          : 'Sedang (5-20 mm/jam)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.water_drop,
                  color: AppTheme.accentBlue.withValues(alpha: 0.4),
                  size: 40,
                ),
              ],
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
