import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../localization/app_localizations.dart';
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
        appBar: AppBar(title: Text(context.t('reports'))),
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
                            DropdownMenuItem(
                              value: 'all',
                              child: Text(context.t('allSensors')),
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
                          decoration: InputDecoration(
                            labelText: context.t('sensorLabel'),
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
                            : Text(context.t('showData')),
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
                          provider.exporting ? context.t('processing') : context.t('downloadPdf'),
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
                          provider.exporting ? context.t('processing') : context.t('downloadExcel'),
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

          // Charts - Premium visual implementations
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildSingleChartCard(
                    title: context.t('waterLevelGraphTitle'),
                    liveValue: '${(provider.rawRows.isNotEmpty ? (provider.rawRows.last['levelCm'] ?? 0) : 0).toInt()} cm',
                    color: const Color(0xFF0066FF),
                    loading: provider.loading,
                    values: provider.rawRows.map<double>((r) => (r['levelCm'] ?? 0.0).toDouble()).toList(),
                    unit: 'cm',
                    chartWidget: _buildFlChart(
                      provider.rawRows,
                      (r) => (r['levelCm'] ?? 0).toDouble(),
                      const Color(0xFF0066FF),
                      'cm',
                    ),
                  ),
                  _buildSingleChartCard(
                    title: context.t('rainfallGraphTitle'),
                    liveValue: '${(provider.rawRows.isNotEmpty ? (provider.rawRows.last['rainfallMm'] ?? 0.0) : 0.0).toStringAsFixed(1)} mm/jam',
                    color: const Color(0xFF10B981),
                    loading: provider.loading,
                    values: provider.rawRows.map<double>((r) => (r['rainfallMm'] ?? 0.0).toDouble()).toList(),
                    unit: 'mm',
                    chartWidget: _buildFlChart(
                      provider.rawRows,
                      (r) => (r['rainfallMm'] ?? 0.0).toDouble(),
                      const Color(0xFF10B981),
                      'mm',
                    ),
                  ),
                  _buildSingleChartCard(
                    title: context.t('flowRateGraphTitle'),
                    liveValue: '${(provider.rawRows.isNotEmpty ? (provider.rawRows.last['flowRateLpm'] ?? 0.0) : 0.0).toStringAsFixed(1)} LPM',
                    color: const Color(0xFFF59E0B),
                    loading: provider.loading,
                    values: provider.rawRows.map<double>((r) => (r['flowRateLpm'] ?? 0.0).toDouble()).toList(),
                    unit: 'LPM',
                    chartWidget: _buildFlChart(
                      provider.rawRows,
                      (r) => (r['flowRateLpm'] ?? 0.0).toDouble(),
                      const Color(0xFFF59E0B),
                      'LPM',
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    context.t('rawDataTable'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Time')),
                          DataColumn(label: Text('Sensor')),
                          DataColumn(label: Text('Water Level (cm)')),
                          DataColumn(label: Text('Rainfall (mm)')),
                          DataColumn(label: Text('Flow Rate (LPM)')),
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
    final downloadingMsg = context.t('downloadingReport');
    final successMsg = context.t('downloadSuccess');
    final failedMsg = context.t('exportFailed');
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text('$downloadingMsg ${format.toUpperCase()}...')),
    );

    try {
      final filePath = await provider.downloadAndOpenReport(
        type: type,
        format: format,
      );
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('$successMsg $filePath'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text('$failedMsg ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildSingleChartCard({
    required String title,
    required String liveValue,
    required Color color,
    required Widget chartWidget,
    required bool loading,
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
      margin: const EdgeInsets.only(bottom: 12),
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
                  color: color.withAlpha(26),
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
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : chartWidget,
          ),
          if (values.isNotEmpty && !loading) ...[
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

  Widget _buildFlChart(
    List<Map<String, dynamic>> logs,
    double Function(Map<String, dynamic>) getValue,
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
              context.t('noFilteredData'),
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
                  final rawTime = logs[idx]['timestamp'];
                  if (rawTime == null) return const SizedBox();
                  final time = DateTime.parse(rawTime.toString());
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
                const Color(0xFF0F172A).withAlpha(230),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final log = logs[spot.spotIndex];
                final rawTime = log['timestamp'];
                final formattedTime = rawTime != null
                    ? DateFormat('HH:mm:ss').format(DateTime.parse(rawTime.toString()))
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
}
