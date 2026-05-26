import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/report_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final p = ReportProvider();
        p.loadSensors();
        p.applyFilter();
        return p;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Laporan')),
        body: const _ReportsBody(),
      ),
    );
  }
}

class _ReportsBody extends StatefulWidget {
  const _ReportsBody();

  @override
  State<_ReportsBody> createState() => _ReportsBodyState();
}

class _ReportsBodyState extends State<_ReportsBody> {
  final DateFormat _displayDateFmt = DateFormat('dd MMM yyyy');
  late final TextEditingController _rangeController;

  @override
  void initState() {
    super.initState();
    _rangeController = TextEditingController();
  }

  @override
  void dispose() {
    _rangeController.dispose();
    super.dispose();
  }

  void _updateRangeText(ReportProvider provider) {
    _rangeController.text =
        '${_displayDateFmt.format(provider.startDate)} - ${_displayDateFmt.format(provider.endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    _updateRangeText(provider);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rangeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Rentang Tanggal Pencarian',
                            suffixIcon: Icon(Icons.date_range),
                            border: OutlineInputBorder(),
                          ),
                          onTap: () async {
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365 * 5),
                              ),
                              lastDate: DateTime.now(),
                              initialDateRange: DateTimeRange(
                                start: provider.startDate,
                                end: provider.endDate,
                              ),
                            );
                            if (range != null) {
                              provider.setDateRange(range.start, range.end);
                              await provider.applyFilter();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: provider.selectedSensorId,
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('Semua Sensor'),
                            ),
                            ...provider.sensors.map(
                              (s) => DropdownMenuItem(
                                value: s.sensorId,
                                child: Text(s.name),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            provider.setSelectedSensor(v ?? 'all');
                          },
                          decoration: const InputDecoration(
                            labelText: 'Sensor',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: provider.loading
                            ? null
                            : () => provider.applyFilter(),
                        child: provider.loading
                            ? const CircularProgressIndicator()
                            : const Text('Tampilkan Data'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: provider.exporting
                            ? null
                            : () => _handleExport(
                                context,
                                provider,
                                type: 'combined',
                                format: 'pdf',
                              ),
                        icon: provider.exporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf),
                        label: Text(
                          provider.exporting ? 'Memproses...' : 'Unduh PDF',
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: provider.exporting
                            ? null
                            : () => _handleExport(
                                context,
                                provider,
                                type: 'combined',
                                format: 'excel',
                              ),
                        icon: provider.exporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.table_chart),
                        label: Text(
                          provider.exporting ? 'Memproses...' : 'Unduh Excel',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (provider.error != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFCA5A5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                provider.error!,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Charts - simple implementations
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Ketinggian Air (cm)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 180, child: _buildWaterLevelChart(provider)),
                  const SizedBox(height: 12),
                  const Text(
                    'Curah Hujan (mm)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 160, child: _buildRainfallChart(provider)),
                  const SizedBox(height: 12),
                  const Text(
                    'Debit Air (LPM)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 160, child: _buildFlowChart(provider)),

                  const SizedBox(height: 12),
                  const Text(
                    'Tabel Data Mentah',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Waktu')),
                          DataColumn(label: Text('Sensor')),
                          DataColumn(label: Text('Ketinggian (cm)')),
                          DataColumn(label: Text('Hujan (mm)')),
                          DataColumn(label: Text('Debit (LPM)')),
                        ],
                        rows: provider.rawRows.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  DateFormat(
                                    'yyyy-MM-dd HH:mm',
                                  ).format(DateTime.parse(r['timestamp'])),
                                ),
                              ),
                              DataCell(Text(r['sensorId'] ?? '-')),
                              DataCell(Text((r['levelCm'] ?? 0).toString())),
                              DataCell(Text((r['rainfallMm'] ?? 0).toString())),
                              DataCell(
                                Text((r['flowRateLpm'] ?? 0).toString()),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    ReportProvider provider, {
    required String type,
    required String format,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text('Mengunduh ${format.toUpperCase()}...')),
    );

    try {
      final filePath = await provider.downloadAndOpenReport(
        type: type,
        format: format,
      );
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Unduh ${format.toUpperCase()} berhasil. File tersimpan di: $filePath',
          ),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Export gagal: ${e.toString()}')),
      );
    }
  }

  Widget _buildWaterLevelChart(ReportProvider provider) {
    final points = provider.rawRows
        .map(
          (r) => FlSpot(
            DateTime.parse(r['timestamp']).millisecondsSinceEpoch.toDouble(),
            (r['levelCm'] ?? 0).toDouble(),
          ),
        )
        .toList();

    if (points.isEmpty) return const Center(child: Text('No data'));

    final minX = points.first.x;
    final maxX = points.last.x;
    final minY = points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY + 1,
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: false,
            dotData: FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(show: false),
      ),
    );
  }

  Widget _buildRainfallChart(ReportProvider provider) {
    final points = provider.rawRows
        .map(
          (r) => BarChartGroupData(
            x: DateTime.parse(r['timestamp']).millisecondsSinceEpoch ~/ 1000,
            barRods: [BarChartRodData(toY: (r['rainfallMm'] ?? 0).toDouble())],
          ),
        )
        .toList();
    if (points.isEmpty) return const Center(child: Text('No data'));
    return BarChart(
      BarChartData(barGroups: points, titlesData: FlTitlesData(show: false)),
    );
  }

  Widget _buildFlowChart(ReportProvider provider) {
    final points = provider.rawRows
        .map(
          (r) => BarChartGroupData(
            x: DateTime.parse(r['timestamp']).millisecondsSinceEpoch ~/ 1000,
            barRods: [BarChartRodData(toY: (r['flowRateLpm'] ?? 0).toDouble())],
          ),
        )
        .toList();
    if (points.isEmpty) return const Center(child: Text('No data'));
    return BarChart(
      BarChartData(barGroups: points, titlesData: FlTitlesData(show: false)),
    );
  }
}
