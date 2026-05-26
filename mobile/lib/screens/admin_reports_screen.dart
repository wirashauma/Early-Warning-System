import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/report_provider.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final p = ReportProvider();
        p.loadSensors();
        p.applyFilter();
        return p;
      },
      child: const _AdminReportsBody(),
    );
  }
}

class _AdminReportsBody extends StatefulWidget {
  const _AdminReportsBody();

  @override
  State<_AdminReportsBody> createState() => _AdminReportsBodyState();
}

class _AdminReportsBodyState extends State<_AdminReportsBody> {
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    _updateRangeText(provider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Sensor Dropdown — wired to ReportProvider
                DropdownButtonFormField<String>(
                  initialValue: provider.selectedSensorId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Sensor',
                    border: OutlineInputBorder(),
                  ),
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
                ),
                const SizedBox(height: 12),
                // Date Range Picker — wired to ReportProvider
                TextFormField(
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
                const SizedBox(height: 12),
                // Apply Filter Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.loading
                        ? null
                        : () => provider.applyFilter(),
                    icon: provider.loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search, size: 16),
                    label: Text(
                      provider.loading ? 'Memuat...' : 'Tampilkan Data',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Export Buttons — wired to ReportProvider.downloadAndOpenReport()
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.picture_as_pdf,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    provider.exporting ? 'Memproses...' : 'Unduh PDF',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                  ),
                  onPressed: provider.exporting
                      ? null
                      : () => _handleExport(
                          context,
                          provider,
                          type: 'combined',
                          format: 'pdf',
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.grid_on_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    provider.exporting ? 'Memproses...' : 'Unduh Excel',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                  ),
                  onPressed: provider.exporting
                      ? null
                      : () => _handleExport(
                          context,
                          provider,
                          type: 'combined',
                          format: 'excel',
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Error Banner
          if (provider.error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFCA5A5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                provider.error!,
                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
              ),
            ),
          // Data Table or Empty State
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.rawRows.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tidak ada data logs pada rentang filter ini.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${provider.rawRows.length} record ditemukan',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                        DateFormat('yyyy-MM-dd HH:mm').format(
                                          DateTime.parse(r['timestamp']),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(r['sensorId'] ?? '-')),
                                    DataCell(
                                      Text((r['levelCm'] ?? 0).toString()),
                                    ),
                                    DataCell(
                                      Text((r['rainfallMm'] ?? 0).toString()),
                                    ),
                                    DataCell(
                                      Text((r['flowRateLpm'] ?? 0).toString()),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
