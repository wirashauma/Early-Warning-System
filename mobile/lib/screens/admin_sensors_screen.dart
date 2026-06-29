import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../models/admin_provider.dart';
import '../models/sensor_model.dart';

class AdminSensorsScreen extends StatefulWidget {
  const AdminSensorsScreen({super.key});

  @override
  State<AdminSensorsScreen> createState() => _AdminSensorsScreenState();
}

class _AdminSensorsScreenState extends State<AdminSensorsScreen> {
  bool _initialized = false;

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

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final provider = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('deleteSensorTitle')),
        content: Text(context.t('deleteSensorConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              context.t('deleteSensorAction'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      final success = await provider.deleteSensor(id);
      if (!mounted) return;
      if (success) {
        await provider.loadSensors();
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(context.t('deleteSensorSuccess'))),
        );
      } else {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? context.t('deleteSensorFailed')),
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    Map<String, dynamic> sensor,
  ) async {
    final id = (sensor['id'] ?? sensor['sensorId'] ?? '').toString();
    final idCtrl = TextEditingController(
      text: sensor['sensorId']?.toString() ?? sensor['id']?.toString() ?? '',
    );
    final nameCtrl = TextEditingController(
      text: sensor['name']?.toString() ?? '',
    );
    final latCtrl = TextEditingController(
      text: sensor['latitude']?.toString() ?? '',
    );
    final lngCtrl = TextEditingController(
      text: sensor['longitude']?.toString() ?? '',
    );
    final batteryCtrl = TextEditingController(
      text: sensor['batteryLevel']?.toString() ?? '',
    );
    final connectivityCtrl = TextEditingController(
      text: sensor['connectivity']?.toString() ?? '',
    );
    String typeValue = (sensor['type']?.toString() ?? 'WATER_LEVEL').toString();

    final provider = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('editSensorTitle')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                decoration: InputDecoration(
                  labelText: context.t('sensorIdLabel'),
                ),
                enabled: false,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: context.t('sensorLocationLabel')),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: typeValue,
                items: [
                  DropdownMenuItem(
                    value: 'WATER_LEVEL',
                    child: Text(context.t('sensorTypeWaterLevel')),
                  ),
                  DropdownMenuItem(
                    value: 'RAINFALL',
                    child: Text(context.t('sensorTypeRainfall')),
                  ),
                  DropdownMenuItem(
                    value: 'FLOW_RATE',
                    child: Text(context.t('sensorTypeFlowRate')),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    typeValue = v;
                    setState(() {});
                  }
                },
                decoration: InputDecoration(labelText: context.t('sensorTypeLabel')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: latCtrl,
                decoration: InputDecoration(labelText: context.t('latitudeLabel')),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lngCtrl,
                decoration: InputDecoration(labelText: context.t('longitudeLabel')),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: batteryCtrl,
                decoration: InputDecoration(labelText: '${context.t('batteryLabel')} (%)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: (connectivityCtrl.text.isNotEmpty
                    ? connectivityCtrl.text.toUpperCase()
                    : 'ONLINE'),
                items: [
                  DropdownMenuItem(value: 'ONLINE', child: Text(context.t('sensorOnline'))),
                  DropdownMenuItem(value: 'OFFLINE', child: Text(context.t('sensorOffline'))),
                ],
                onChanged: (v) {
                  if (v != null) connectivityCtrl.text = v;
                },
                decoration: InputDecoration(labelText: context.t('sensorConnectivityLabel')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(true);
            },
            child: Text(context.t('saveSensor')),
          ),
        ],
      ),
    );

    if (result == true) {
      final name = nameCtrl.text.trim();
      final lat = double.tryParse(latCtrl.text.trim()) ?? 0.0;
      final lng = double.tryParse(lngCtrl.text.trim()) ?? 0.0;
      final battery = int.tryParse(batteryCtrl.text.trim()) ?? 0;
      final connectivity = connectivityCtrl.text.trim().isNotEmpty
          ? connectivityCtrl.text.trim().toUpperCase()
          : 'UNKNOWN';

      final success = await provider.updateSensor(
        id: id,
        name: name,
        type: typeValue,
        latitude: lat,
        longitude: lng,
        batteryLevel: battery,
        connectivity: connectivity,
      );

      if (success) {
        await provider.loadSensors();
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(context.t('sensorUpdatedSuccess'))),
        );
      } else {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? context.t('sensorUpdateFailed'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final batteryCtrl = TextEditingController(text: '100');
    String connectivity = 'ONLINE';
    String typeValue = 'WATER_LEVEL';

    final provider = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('addSensorTitle')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                decoration: InputDecoration(
                  labelText: context.t('sensorIdLabel'),
                  hintText: context.t('sensorIdHint'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: context.t('sensorLocationLabel')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: latCtrl,
                decoration: InputDecoration(labelText: context.t('latitudeLabel')),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lngCtrl,
                decoration: InputDecoration(labelText: context.t('longitudeLabel')),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: batteryCtrl,
                decoration: InputDecoration(labelText: '${context.t('batteryLabel')} (%)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: typeValue,
                        items: [
                          DropdownMenuItem(
                            value: 'WATER_LEVEL',
                            child: Text(context.t('sensorTypeWaterLevel')),
                          ),
                          DropdownMenuItem(
                            value: 'RAINFALL',
                            child: Text(context.t('sensorTypeRainfall')),
                          ),
                          DropdownMenuItem(
                            value: 'FLOW_RATE',
                            child: Text(context.t('sensorTypeFlowRate')),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => typeValue = v);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: context.t('sensorTypeLabel'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: connectivity,
                        items: [
                          DropdownMenuItem(
                            value: 'ONLINE',
                            child: Text(context.t('sensorOnline')),
                          ),
                          DropdownMenuItem(
                            value: 'OFFLINE',
                            child: Text(context.t('sensorOffline')),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => connectivity = v);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: context.t('sensorConnectivityLabel'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.t('addSensorButton')),
          ),
        ],
      ),
    );

    if (result == true) {
      final sensorId = idCtrl.text.trim();
      final name = nameCtrl.text.trim();

      if (sensorId.isEmpty || name.isEmpty) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(context.t('sensorCreateRequired')),
            ),
          );
        }
        return;
      }

      final lat = double.tryParse(latCtrl.text.trim()) ?? 0.0;
      final lng = double.tryParse(lngCtrl.text.trim()) ?? 0.0;
      final battery = int.tryParse(batteryCtrl.text.trim()) ?? 100;

      final success = await provider.createSensor(
        sensorId: sensorId,
        name: name,
        type: typeValue,
        latitude: lat,
        longitude: lng,
        batteryLevel: battery,
        connectivity: connectivity,
      );

      if (success) {
        await provider.loadSensors();
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(context.t('sensorCreatedSuccess'))),
        );
      } else {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? context.t('sensorCreatedFailed'),
            ),
          ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      context.read<AdminProvider>().loadSensors();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final sensors = adminProvider.sensors;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : adminProvider.errorMessage != null && sensors.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFB91C1C),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      adminProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<AdminProvider>().loadSensors(),
                      child: Text(context.t('retry')),
                    ),
                  ],
                ),
              ),
            )
          : sensors.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sensors_off_outlined,
                      size: 48,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.t('noSensorsInstalledAdminTitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.t('noSensorsInstalledAdminSubtitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sensors.length,
              itemBuilder: (context, index) {
                final sensor = sensors[index] as Map<String, dynamic>;
                final isOnline = _isSensorOnline(sensor);
                final id = sensor['id'] ?? sensor['sensorId'] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sensor['sensorId']?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0066FF),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sensor['name']?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${context.t('deviceTypeLabel')}: ${sensor['type'] ?? '-'}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOnline ? context.t('sensorOnline') : context.t('sensorOffline'),
                              style: TextStyle(
                                color: isOnline
                                    ? const Color(0xFF10B981)
                                    : Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${context.t('batteryLabelShort')}: ${sensor['batteryLevel'] != null ? '${sensor['batteryLevel']}%' : '-'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Color(0xFF0066FF),
                                ),
                                onPressed: () =>
                                    _showEditDialog(context, sensor),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, id.toString()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0066FF),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCreateDialog(context),
      ),
    );
  }
}
