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
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dasbor Admin',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'Early Warning System',
                    style: TextStyle(
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '2026/2027',
                    style: TextStyle(
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
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                      hintText: 'Cari sensor, notifikasi, atau laporan...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    readOnly: true,
                    onTap: () {},
                  ),
                ),
              ),
            ),
            
            // Dashboard Content
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Hero Welcome Card with Deep/Premium Gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF312E81), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF312E81).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Selamat Datang! ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text('👋', style: TextStyle(fontSize: 22)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Ringkasan cepat kondisi sistem Early Warning System untuk membantu tim merespons perubahan level air lebih sigap.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text(
                              'Status global saat ini: ',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins'),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusBorder, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, color: statusTextCol, size: 14),
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
                              label: 'Sensor Aktif',
                              value: '$onlineSensors',
                              sub: 'Total sensor: $totalSensors',
                              icon: Icons.sensors,
                              iconColor: Colors.blue,
                              iconBg: const Color(0xFFEFF6FF),
                            ),
                            _buildMetricCard(
                              label: 'Status Waspada',
                              value: '$warningCount',
                              sub: warningCount > 0 ? 'Sensor dalam status alert' : 'Sistem terpantau aman',
                              icon: Icons.warning_rounded,
                              iconColor: AppTheme.statusWaspada,
                              iconBg: const Color(0xFFFFFBEB),
                              isWarning: warningCount > 0,
                            ),
                            _buildMetricCard(
                              label: 'Status Bahaya',
                              value: '$dangerCount',
                              sub: dangerCount > 0 ? 'Perlu respons segera' : 'Tidak ada ancaman',
                              icon: Icons.gpp_bad_outlined,
                              iconColor: Colors.pink,
                              iconBg: const Color(0xFFFFF1F2),
                              isDanger: dangerCount > 0,
                            ),
                            _buildMetricCard(
                              label: 'Curah Hujan',
                              value: '${avgRainfall.toStringAsFixed(1)} mm/j',
                              sub: 'Rata-rata data sensor',
                              icon: Icons.cloud_queue,
                              iconColor: Colors.cyan,
                              iconBg: const Color(0xFFECFEFF),
                            ),
                            _buildMetricCard(
                              label: 'Puncak Tinggi Air',
                              value: '${maxLevelCm.toInt()} cm',
                              sub: 'Pembacaan tertinggi',
                              icon: Icons.water_drop_outlined,
                              iconColor: Colors.teal,
                              iconBg: const Color(0xFFF0FDF4),
                            ),
                            _buildMetricCard(
                              label: 'Sensor Offline',
                              value: '$offlineSensors',
                              sub: offlineSensors > 0 ? 'Perlu pengecekan alat' : 'Semua sensor online',
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
                      const Text(
                        'Peta Interaktif Lokasi Sensor',
                        style: TextStyle(
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
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: Color(0xFF64748B)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Peta di atas menunjukkan sebaran sensor EWS secara real-time. Ketuk penanda sensor pada peta untuk info detail.',
                                  style: TextStyle(
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
                      : (isWarning ? const Color(0xFFD97706) : const Color(0xFF94A3B8)),
                  fontFamily: 'Poppins',
                  fontWeight: isDanger || isWarning ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        ],
      ),
    );
  }
}
