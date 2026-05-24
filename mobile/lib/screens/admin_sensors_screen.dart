import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus sensor'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus sensor ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<AdminProvider>();
      final success = await provider.deleteSensor(id);
      if (success) {
        await provider.loadSensors();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sensor berhasil dihapus')),
          );
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Gagal menghapus sensor'),
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
    final riverCtrl = TextEditingController(
      text: sensor['riverName']?.toString() ?? sensor['name']?.toString() ?? '',
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
    final zeroCtrl = TextEditingController(
      text: sensor['zeroCalibrationCm']?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Sensor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                decoration: const InputDecoration(
                  labelText: 'ID Perangkat (sensorId)',
                ),
                enabled: false,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Lokasi'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: riverCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Sungai/Area',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: typeValue,
                items: const [
                  DropdownMenuItem(
                    value: 'WATER_LEVEL',
                    child: Text('Water Level (Tinggi Air)'),
                  ),
                  DropdownMenuItem(
                    value: 'RAINFALL',
                    child: Text('Rainfall (Curah Hujan)'),
                  ),
                  DropdownMenuItem(
                    value: 'FLOW_RATE',
                    child: Text('Flow Rate (Debit Aliran)'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    typeValue = v;
                    setState(() {});
                  }
                },
                decoration: const InputDecoration(labelText: 'Tipe Sensor'),
              ),
              const SizedBox(height: 8),
              if (typeValue == 'WATER_LEVEL')
                TextField(
                  controller: zeroCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kalibrasi Nol (cm)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              const SizedBox(height: 8),
              TextField(
                controller: latCtrl,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lngCtrl,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: batteryCtrl,
                decoration: const InputDecoration(labelText: 'Baterai (%)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: (connectivityCtrl.text.isNotEmpty
                    ? connectivityCtrl.text.toUpperCase()
                    : 'ONLINE'),
                items: const [
                  DropdownMenuItem(value: 'ONLINE', child: Text('Online')),
                  DropdownMenuItem(value: 'OFFLINE', child: Text('Offline')),
                ],
                onChanged: (v) {
                  if (v != null) connectivityCtrl.text = v;
                },
                decoration: const InputDecoration(labelText: 'Status Koneksi'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Simpan'),
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

      final provider = context.read<AdminProvider>();
      final success = await provider.updateSensor(
        id: id,
        name: name,
        latitude: lat,
        longitude: lng,
        batteryLevel: battery,
        connectivity: connectivity,
      );

      if (success) {
        await provider.loadSensors();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sensor berhasil diperbarui')),
          );
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? 'Gagal memperbarui sensor',
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

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Sensor Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                decoration: const InputDecoration(
                  labelText: 'ID Perangkat (sensorId)',
                  hintText: 'contoh: SNS-WL-04',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Lokasi'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: latCtrl,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lngCtrl,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: batteryCtrl,
                decoration: const InputDecoration(labelText: 'Baterai (%)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return DropdownButtonFormField<String>(
                    value: connectivity,
                    items: const [
                      DropdownMenuItem(
                          value: 'ONLINE', child: Text('Online')),
                      DropdownMenuItem(
                          value: 'OFFLINE', child: Text('Offline')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => connectivity = v);
                      }
                    },
                    decoration:
                        const InputDecoration(labelText: 'Status Koneksi'),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );

    if (result == true) {
      final sensorId = idCtrl.text.trim();
      final name = nameCtrl.text.trim();

      if (sensorId.isEmpty || name.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('ID Perangkat dan Nama Lokasi wajib diisi')),
          );
        }
        return;
      }

      final lat = double.tryParse(latCtrl.text.trim()) ?? 0.0;
      final lng = double.tryParse(lngCtrl.text.trim()) ?? 0.0;
      final battery = int.tryParse(batteryCtrl.text.trim()) ?? 100;

      final provider = context.read<AdminProvider>();
      final success = await provider.createSensor(
        sensorId: sensorId,
        name: name,
        latitude: lat,
        longitude: lng,
        batteryLevel: battery,
        connectivity: connectivity,
      );

      if (success) {
        await provider.loadSensors();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sensor baru berhasil ditambahkan')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  provider.errorMessage ?? 'Gagal menambahkan sensor'),
            ),
          );
        }
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
          : sensors.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.sensors_off_outlined,
                      size: 48,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada sensor terpasang.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Silakan tambahkan perangkat IoT terlebih dahulu agar data sensor dapat muncul di halaman ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
                              'Tipe Perangkat: ${sensor['type'] ?? '-'}',
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
                              isOnline ? 'ONLINE' : 'OFFLINE',
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
                            'Baterai: ${sensor['batteryLevel'] != null ? '${sensor['batteryLevel']}%' : '-'}',
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
