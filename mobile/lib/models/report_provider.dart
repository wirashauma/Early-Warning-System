import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'api_service.dart';
import 'water_level_log.dart';
import 'rainfall_log.dart';
import 'flow_rate_log.dart';
import 'sensor_model.dart';

class ReportProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  DateTime startDate = DateTime.now().subtract(Duration(days: 6));
  DateTime endDate = DateTime.now();
  String selectedSensorId = 'all';

  bool loading = false;
  bool exporting = false;
  String? error;

  List<SensorModel> sensors = [];
  List<WaterLevelLog> waterLevels = [];
  List<RainfallLog> rainfalls = [];
  List<FlowRateLog> flowRates = [];

  // Combined raw rows used by the table
  List<Map<String, dynamic>> rawRows = [];
  List<String> partialErrors = [];

  final DateFormat _fmt = DateFormat("yyyy-MM-dd'T'00:00:00.000'Z'");

  Future<void> loadSensors() async {
    try {
      sensors = await _api.fetchSensors(page: 1, limit: 200);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  void setSelectedSensor(String id) {
    selectedSensorId = id;
    notifyListeners();
  }

  void setDateRange(DateTime start, DateTime end) {
    startDate = start;
    endDate = end;
    notifyListeners();
  }

  Future<void> applyFilter() async {
    loading = true;
    error = null;
    partialErrors = [];
    notifyListeners();

    final startIso = _fmt.format(startDate);
    final endIso = DateFormat("yyyy-MM-dd'T'23:59:59.000'Z'").format(endDate);

    try {
      final List<WaterLevelLog> wlList = [];
      final List<RainfallLog> rfList = [];
      final List<FlowRateLog> frList = [];

      if (selectedSensorId == 'all') {
        for (final s in sensors) {
          try {
            if (s.type == 'WATER_LEVEL') {
              final wl = await _api.fetchWaterLevelHistory(
                sensorId: s.sensorId,
                startDate: startIso,
                endDate: endIso,
                interval: 'hourly',
                limit: 10000,
              );
              wlList.addAll(wl);
            } else if (s.type == 'RAINFALL') {
              final rf = await _api.fetchRainfallHistory(
                sensorId: s.sensorId,
                startDate: startIso,
                endDate: endIso,
                interval: 'hourly',
                limit: 10000,
              );
              rfList.addAll(rf);
            } else if (s.type == 'FLOW_RATE') {
              final fr = await _api.fetchFlowRateHistory(
                sensorId: s.sensorId,
                startDate: startIso,
                endDate: endIso,
                interval: 'hourly',
                limit: 10000,
              );
              frList.addAll(fr);
            }
          } catch (e) {
            debugPrint(
              '[ReportProvider] applyFilter error on ${s.sensorId}: $e',
            );
            partialErrors.add('${s.sensorId}: $e');
          }
        }
      } else {
        final sensor = sensors.firstWhere(
          (s) => s.sensorId == selectedSensorId || s.id == selectedSensorId,
          orElse: () => SensorModel(
            id: '',
            sensorId: selectedSensorId,
            name: '',
            type: 'WATER_LEVEL',
            latitude: 0.0,
            longitude: 0.0,
            connectivity: 'OFFLINE',
            isActive: false,
          ),
        );

        if (sensor.sensorId.isNotEmpty) {
          try {
            if (sensor.type == 'WATER_LEVEL') {
              final wl = await _api.fetchWaterLevelHistory(
                sensorId: sensor.sensorId,
                startDate: startIso,
                endDate: endIso,
                interval: 'hourly',
                limit: 10000,
              );
              wlList.addAll(wl);
            } else if (sensor.type == 'RAINFALL') {
              final rf = await _api.fetchRainfallHistory(
                sensorId: sensor.sensorId,
                startDate: startIso,
                endDate: endIso,
                interval: 'hourly',
                limit: 10000,
              );
              rfList.addAll(rf);
            } else if (sensor.type == 'FLOW_RATE') {
              final fr = await _api.fetchFlowRateHistory(
                sensorId: sensor.sensorId,
                startDate: startIso,
                endDate: endIso,
                interval: 'hourly',
                limit: 10000,
              );
              frList.addAll(fr);
            }
          } catch (e) {
            debugPrint(
              '[ReportProvider] applyFilter error on ${sensor.sensorId}: $e',
            );
            partialErrors.add('${sensor.sensorId}: $e');
            rethrow;
          }
        }
      }

      waterLevels = wlList;
      rainfalls = rfList;
      flowRates = frList;

      // Merge into rawRows by timestamp + sensor
      final Map<String, Map<String, dynamic>> map = {};

      void addRow(String ts, String sensorId, Map<String, dynamic> values) {
        final key = '$sensorId|$ts';
        final existing =
            map[key] ??
            {
              'timestamp': ts,
              'sensorId': sensorId,
              'levelCm': 0.0,
              'rainfallMm': 0.0,
              'flowRateLpm': 0.0,
            };
        existing.addAll(values);
        map[key] = existing;
      }

      for (final w in waterLevels) {
        addRow(w.recordedAt.toIso8601String(), w.sensorId, {
          'levelCm': w.waterLevel * 100.0,
        });
      }
      for (final r in rainfalls) {
        addRow(r.recordedAt.toIso8601String(), r.sensorId, {
          'rainfallMm': r.rainfall,
        });
      }
      for (final f in flowRates) {
        addRow(f.recordedAt.toIso8601String(), f.sensorId, {
          'flowRateLpm': f.flowRate,
        });
      }

      rawRows = map.values.toList()
        ..sort(
          (a, b) => DateTime.parse(
            a['timestamp'],
          ).compareTo(DateTime.parse(b['timestamp'])),
        );

      if (partialErrors.isNotEmpty) {
        error =
            'Sebagian data laporan gagal dimuat:\n${partialErrors.take(3).join('\n')}';
      }

      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String> downloadAndOpenReport({
    required String type,
    required String format,
  }) async {
    if (exporting) {
      throw ApiException(0, 'Unduhan sedang berjalan. Mohon tunggu.');
    }

    exporting = true;
    notifyListeners();

    final startIso = _fmt.format(startDate);
    final endIso = DateFormat("yyyy-MM-dd'T'23:59:59.000'Z'").format(endDate);

    try {
      final bytes = await _api.downloadReportBytes(
        type: type,
        startDate: startIso,
        endDate: endIso,
        format: format,
        sensorId: selectedSensorId == 'all' ? null : selectedSensorId,
      );

      final dir = await getApplicationDocumentsDirectory();
      final ext = format == 'pdf' ? 'pdf' : 'xlsx';
      final filename =
          'ews-report-$type-${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      final openResult = await OpenFilex.open(file.path);
      if (openResult.type != ResultType.done) {
        throw ApiException(
          0,
          'File tersimpan di ${file.path}, tetapi gagal dibuka otomatis: ${openResult.message}',
        );
      }

      return file.path;
    } finally {
      exporting = false;
      notifyListeners();
    }
  }
}
