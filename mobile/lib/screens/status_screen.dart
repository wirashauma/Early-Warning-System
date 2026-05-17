import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../widgets/ews_appbar.dart';
import '../models/sensor_model.dart';

class StatusScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  const StatusScreen({super.key, this.onRefresh});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  int? _focusedIndex;
  String _filter = 'Semua';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Koordinat sensor untuk pemetaan
  static const List<Map<String, dynamic>> _coords = [
    {'colorVal': 0xFFE53E3E, 'lat': -0.9570, 'lng': 100.3530},
    {'colorVal': 0xFFDD6B20, 'lat': -0.9490, 'lng': 100.3610},
    {'colorVal': 0xFF38A169, 'lat': -0.9430, 'lng': 100.3700},
  ];

  List<SensorData> get _filtered => dummySensors.where((s) {
    final matchFilter = _filter == 'Semua' || s.status == _filter;
    final matchSearch = _searchQuery.isEmpty ||
        s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.location.toLowerCase().contains(_searchQuery.toLowerCase());
    return matchFilter && matchSearch;
  }).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final risky = dummySensors.where((s) => s.status != 'Normal').length;
    final lastUpdate = dummySensors.map((s) => s.lastUpdate).reduce((a, b) => a.isAfter(b) ? a : b);
    final ts = '${lastUpdate.day} Mar ${lastUpdate.year}, ${lastUpdate.hour.toString().padLeft(2, '0')}.${lastUpdate.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: EWSAppBar(onRefresh: widget.onRefresh),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(risky, ts),
            _buildMap(),
            _buildSensorList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int risky, String ts) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STATUS PEMANTAUAN', style: TextStyle(fontSize: 10, color: AppTheme.accentBlue, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 6),
          const Text('Peta & Daftar Sensor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Identifikasi titik risiko banjir secara real-time melalui integrasi peta dan data metrik sensor.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.4)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _StatBox(label: 'Total Sensor', value: '${dummySensors.length}'),
              _StatBox(label: 'Sensor Berisiko', value: '$risky', valueColor: risky > 0 ? AppTheme.statusBahaya : AppTheme.textDark),
              _StatBox(label: 'Konektivitas', value: '${dummySensors.length}/${dummySensors.length}'),
              _StatBox(label: 'Pembaruan Terakhir', value: ts, small: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('Fokus: ${_focusedIndex != null ? dummySensors[_focusedIndex!].name : '-'}',
                  style: const TextStyle(fontSize: 11)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildMap() {
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Peta Interaktif Sensor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Wrap(spacing: 10, children: [
              _Legend(color: AppTheme.statusNormal, label: 'Normal'),
              _Legend(color: AppTheme.statusWaspada, label: 'Waspada'),
              _Legend(color: AppTheme.statusBahaya, label: 'Bahaya'),
            ]),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              flex: 3,
              child: Container(
                height: 220,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                clipBehavior: Clip.hardEdge,
                child: FlutterMap(
                  options: MapOptions(
                    center: _focusedIndex != null
                        ? LatLng(_coords[_focusedIndex!]['lat'] as double, _coords[_focusedIndex!]['lng'] as double)
                        : const LatLng(-0.9490, 100.3610),
                    zoom: 14.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.ews_flood_guard',
                    ),
                    MarkerLayer(
                      markers: dummySensors.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        final isFocused = _focusedIndex == i;
                        return Marker(
                          point: LatLng(_coords[i]['lat'] as double, _coords[i]['lng'] as double),
                          width: 44, height: 44,
                          builder: (ctx) => GestureDetector(
                            onTap: () => setState(() => _focusedIndex = isFocused ? null : i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: s.statusColor, shape: BoxShape.circle,
                                border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: s.statusColor.withOpacity(0.5), 
                                    blurRadius: isFocused ? 10 : 4
                                  )
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  s.name.length > 7 ? s.name[7] : 'S', 
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                                )
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('DETAIL FOKUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textGrey)),
                const SizedBox(height: 8),
                if (_focusedIndex == null)
                  const Text('Pilih titik di peta.', style: TextStyle(fontSize: 12, color: AppTheme.textGrey))
                else ...[
                  Text(dummySensors[_focusedIndex!].name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('${dummySensors[_focusedIndex!].waterLevel.toInt()} cm',
                      style: TextStyle(color: dummySensors[_focusedIndex!].statusColor, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(dummySensors[_focusedIndex!].status,
                      style: TextStyle(color: dummySensors[_focusedIndex!].statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSensorList() {
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
          const Text('Daftar Sensor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Cari sensor...',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true, fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: ['Semua', 'Normal', 'Waspada', 'Bahaya'].map((f) => GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _filter == f ? AppTheme.accentBlue : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _filter == f ? AppTheme.accentBlue : const Color(0xFFE2E8F0)),
                ),
                child: Text(f, style: TextStyle(fontSize: 12, color: _filter == f ? Colors.white : AppTheme.textDark)),
              ),
            )).toList()),
          ),
          const SizedBox(height: 12),
          if (_filtered.isEmpty)
            const Center(child: Text('Sensor tidak ditemukan.'))
          else
            ..._filtered.map((s) => _SensorCard(sensor: s)),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool small;
  const _StatBox({required this.label, required this.value, this.valueColor, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: small ? 11 : 20, fontWeight: FontWeight.bold, color: valueColor ?? AppTheme.textDark)),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)),
    ]);
  }
}

class _SensorCard extends StatelessWidget {
  final SensorData sensor;
  const _SensorCard({required this.sensor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        Icon(Icons.sensors, color: sensor.statusColor, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(sensor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(sensor.location, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
        ])),
        Text('${sensor.waterLevel.toInt()} cm', style: TextStyle(color: sensor.statusColor, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}