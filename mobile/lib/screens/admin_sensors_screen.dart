import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_provider.dart';

class AdminSensorsScreen extends StatefulWidget {
  const AdminSensorsScreen({super.key});

  @override
  State<AdminSensorsScreen> createState() => _AdminSensorsScreenState();
}

class _AdminSensorsScreenState extends State<AdminSensorsScreen> {
  bool _initialized = false;

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
                        Icon(Icons.sensors_off_outlined, size: 48, color: Color(0xFF64748B)),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada sensor terpasang.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                    final isOnline = sensor['connectivity']?.toString().toUpperCase() == 'ONLINE';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sensor['sensorId']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0066FF), fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(sensor['name']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14)),
                                const SizedBox(height: 6),
                                Text('Tipe Perangkat: ${sensor['type'] ?? '-'}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  sensor['connectivity']?.toString() ?? 'UNKNOWN',
                                  style: TextStyle(color: isOnline ? const Color(0xFF10B981) : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Baterai: ${sensor['batteryLevel'] != null ? '${sensor['batteryLevel']}%' : '-'}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
        onPressed: () {},
      ),
    );
  }
}
