import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../models/admin_provider.dart';
import '../models/sensor_model.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await context.read<AdminProvider>().loadDashboardStats();
      } catch (e) {
        debugPrint('[AdminDashboardScreen] loadDashboardStats failed: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('adminDashboardLoadFailed', replacements: {'error': e.toString()})),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final stats = adminProvider.dashboardStats;

    final totalSensors = stats['totalSensors'] ?? 0;
    final onlineSensors = adminProvider.onlineSensorsCount;
    final offlineSensors = adminProvider.offlineSensorsCount;
    final avgRainfall = adminProvider.avgRainfall;
    final waterLevels = stats['waterLevels'] as List<dynamic>? ?? [];

    final maxLevelCm = waterLevels.fold<double>(0.0, (prev, item) {
      final level = item is Map<String, dynamic>
          ? (item['waterLevel'] ?? 0)
          : 0;
      return (level is num && level.toDouble() > prev)
          ? level.toDouble()
          : prev;
    });

    final dangerCount = adminProvider.dangerCount;
    final warningCount = adminProvider.warningCount;
    final currentStatus = adminProvider.globalStatus;

    // Status Badge Color Logic
    final Color statusBg;
    final Color statusBorder;
    final Color statusTextCol;
    final IconData statusIcon;

    if (currentStatus == 'Bahaya') {
      statusBg = const Color(0xFFFEE2E2);
      statusBorder = const Color(0xFFFCA5A5);
      statusTextCol = const Color(0xFFDC2626);
      statusIcon = Icons.error_outline_rounded;
    } else if (currentStatus == 'Waspada') {
      statusBg = const Color(0xFFFEF3C7);
      statusBorder = const Color(0xFFFCD34D);
      statusTextCol = const Color(0xFFD97706);
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusBg = const Color(0xFFDCFCE7);
      statusBorder = const Color(0xFF86EFAC);
      statusTextCol = const Color(0xFF16A34A);
      statusIcon = Icons.check_circle_outline_rounded;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () => adminProvider.loadDashboardStats(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // SliverAppBar that hides search bar smoothly on scroll
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF0066FF)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('adminDashboardTitle'),
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    context.t('appSubtitle'),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    context.t('dashboardYearTag'),
                    style: const TextStyle(
                      color: Color(0xFF0369A1),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFF0066FF),
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: context.t('adminSearchHint'),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF64748B),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    readOnly: true,
                    onTap: () {
                      _showSearchDialog(context, adminProvider);
                    },
                  ),
                ),
              ),
            ),

            // Dashboard Content
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (adminProvider.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        adminProvider.errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  // Hero Welcome Card with Deep/Premium Gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1E3A8A),
                          Color(0xFF312E81),
                          Color(0xFF4F46E5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF312E81,
                          ).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              context.t('welcomeMessage'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const Text('👋', style: TextStyle(fontSize: 22)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.t('adminDashboardSubtitle'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              context.t('globalStatus'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusBorder,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusIcon,
                                    color: statusTextCol,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    currentStatus.toUpperCase(),
                                    style: TextStyle(
                                      color: statusTextCol,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Metric Stats Section (GridView)
                  adminProvider.isLoading
                      ? const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.25,
                          children: [
                            _buildMetricCard(
                              label: context.t('sensorActive'),
                              value: '$onlineSensors',
                              sub: '${context.t('totalSensors')}: $totalSensors',
                              icon: Icons.sensors,
                              iconColor: Colors.blue,
                              iconBg: const Color(0xFFEFF6FF),
                            ),
                            _buildMetricCard(
                              label: context.t('warning'),
                              value: '$warningCount',
                              sub: warningCount > 0
                                  ? context.t('sensorsInAlertStatus')
                                  : context.t('systemMonitoredSafe'),
                              icon: Icons.warning_rounded,
                              iconColor: AppTheme.statusWaspada,
                              iconBg: const Color(0xFFFFFBEB),
                              isWarning: warningCount > 0,
                            ),
                            _buildMetricCard(
                              label: context.t('danger'),
                              value: '$dangerCount',
                              sub: dangerCount > 0
                                  ? context.t('needsImmediateResponse')
                                  : context.t('noThreats'),
                              icon: Icons.gpp_bad_outlined,
                              iconColor: Colors.pink,
                              iconBg: const Color(0xFFFFF1F2),
                              isDanger: dangerCount > 0,
                            ),
                            _buildMetricCard(
                              label: context.t('rainfallLabel'),
                              value: '${avgRainfall.toStringAsFixed(1)} mm/j',
                              sub: context.t('averageSensorData'),
                              icon: Icons.cloud_queue,
                              iconColor: Colors.cyan,
                              iconBg: const Color(0xFFECFEFF),
                            ),
                            _buildMetricCard(
                              label: context.t('peakWaterLevel'),
                              value: '${maxLevelCm.toInt()} cm',
                              sub: context.t('highestReading'),
                              icon: Icons.water_drop_outlined,
                              iconColor: Colors.teal,
                              iconBg: const Color(0xFFF0FDF4),
                            ),
                            _buildMetricCard(
                              label: context.t('sensorOffline'),
                              value: '$offlineSensors',
                              sub: offlineSensors > 0
                                  ? context.t('needsDeviceCheck')
                                  : context.t('allSensorsOnline'),
                              icon: Icons.wifi_off_rounded,
                              iconColor: Colors.purple,
                              iconBg: const Color(0xFFF5F3FF),
                              isWarning: offlineSensors > 0,
                            ),
                          ],
                        ),

                  const SizedBox(height: 24),

                  // Clean section divider
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  const SizedBox(height: 20),

                  // Map Header Section
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.t('interactiveSensorMap'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Premium Map Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 220,
                          clipBehavior: Clip.hardEdge,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(-0.9490, 100.3610),
                              initialZoom: 11.5,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.ews_flood_guard',
                              ),
                              MarkerLayer(
                                markers: adminProvider.sensors
                                    .map((sensor) {
                                      if (sensor is! Map<String, dynamic>) {
                                        return null;
                                      }
                                      final latVal =
                                          double.tryParse(
                                            sensor['latitude']?.toString() ??
                                                '',
                                          ) ??
                                          0.0;
                                      final lngVal =
                                          double.tryParse(
                                            sensor['longitude']?.toString() ??
                                                '',
                                          ) ??
                                          0.0;
                                      if (latVal == 0.0 || lngVal == 0.0) {
                                        return null;
                                      }

                                      final isOnline = _isSensorOnline(sensor);
                                      final status =
                                          sensor['status']?.toString() ??
                                          'Normal';
                                      final markerColor = isOnline
                                          ? (status == 'Bahaya'
                                                ? AppTheme.statusBahaya
                                                : (status == 'Waspada'
                                                      ? AppTheme.statusWaspada
                                                      : AppTheme.statusNormal))
                                          : Colors.grey;

                                      return Marker(
                                        point: LatLng(latVal, lngVal),
                                        width: 40,
                                        height: 40,
                                        child: GestureDetector(
                                          onTap: () {
                                            _showSensorDetailsDialog(
                                              context,
                                              sensor,
                                            );
                                          },
                                          child: Icon(
                                            Icons.location_on_rounded,
                                            color: markerColor,
                                            size: 32,
                                          ),
                                        ),
                                      );
                                    })
                                    .whereType<Marker>()
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.t('adminMapDescription'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontFamily: 'Poppins',
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    bool isDanger = false,
    bool isWarning = false,
  }) {
    Color cardBgColor = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);
    double borderWidth = 1.0;

    if (isDanger) {
      cardBgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFCA5A5);
      borderWidth = 1.5;
    } else if (isWarning) {
      cardBgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      borderWidth = 1.5;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: isDanger
                      ? const Color(0xFFEF4444)
                      : (isWarning
                            ? const Color(0xFFD97706)
                            : const Color(0xFF94A3B8)),
                  fontFamily: 'Poppins',
                  fontWeight: isDanger || isWarning
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isSensorOnline(Map<String, dynamic> sensor) {
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

  void _showSensorDetailsDialog(
    BuildContext context,
    Map<String, dynamic> sensor,
  ) {
    final name = sensor['name']?.toString() ?? context.t('sensorUnnamed');
    final sensorId =
        sensor['sensorId']?.toString() ?? sensor['id']?.toString() ?? '-';
    final type = sensor['type']?.toString() ?? 'WATER_LEVEL';
    final lat = sensor['latitude']?.toString() ?? '-';
    final lng = sensor['longitude']?.toString() ?? '-';
    final battery = sensor['batteryLevel']?.toString() ?? '-';
    final connectivity = sensor['connectivity']?.toString() ?? 'OFFLINE';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.sensors, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context.t('sensorDetailsIdLabel'), sensorId),
            _buildDetailRow(
              context.t('sensorTypeLabelShort'),
              type == 'WATER_LEVEL'
                  ? context.t('sensorTypeWaterLevelShort')
                  : context.t('sensorTypeRainGaugeShort'),
            ),
            _buildDetailRow(context.t('sensorCoordinatesLabel'), '$lat, $lng'),
            _buildDetailRow(context.t('batteryLabelShort'), '$battery%'),
            _buildDetailRow(
              context.t('connectivityLabel'),
              connectivity.toUpperCase() == 'ONLINE'
                  ? context.t('sensorOnline')
                  : context.t('sensorOffline'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('close')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (dialogCtx, setState) {
            final filtered = provider.sensors.where((s) {
              if (s is! Map<String, dynamic>) return false;
              final name = s['name']?.toString().toLowerCase() ?? '';
              final sid =
                  s['sensorId']?.toString().toLowerCase() ??
                  s['id']?.toString().toLowerCase() ??
                  '';
              return name.contains(query.toLowerCase()) ||
                  sid.contains(query.toLowerCase());
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: context.t('searchSensorHint'),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          query = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                context.t('sensorNotFound'),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (lCtx, index) {
                                final s = filtered[index];
                                final name = s['name']?.toString() ?? 'Sensor';
                                final sid =
                                    s['sensorId']?.toString() ??
                                    s['id']?.toString() ??
                                    '';
                                return ListTile(
                                  leading: const Icon(
                                    Icons.sensors,
                                    color: AppTheme.primaryBlue,
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'ID: $sid',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _showSensorDetailsDialog(context, s);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
