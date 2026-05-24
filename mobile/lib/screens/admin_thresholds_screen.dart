import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_provider.dart';

class AdminThresholdScreen extends StatefulWidget {
  const AdminThresholdScreen({super.key});

  @override
  State<AdminThresholdScreen> createState() => _AdminThresholdScreenState();
}

class _AdminThresholdScreenState extends State<AdminThresholdScreen> {
  final _formKey = GlobalKey<FormState>();

  // Water Level Controllers
  final _normalMaxCtrl = TextEditingController();
  final _warningMinCtrl = TextEditingController();
  final _warningMaxCtrl = TextEditingController();
  final _dangerMinCtrl = TextEditingController();

  // Rainfall Controllers
  final _rainLightMaxCtrl = TextEditingController();
  final _rainModerateMaxCtrl = TextEditingController();
  final _rainHeavyMinCtrl = TextEditingController();

  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadThresholds());
  }

  Future<void> _loadThresholds() async {
    if (!mounted) return;
    final provider = context.read<AdminProvider>();
    final data = await provider.loadThresholds();

    if (!mounted) return;
    setState(() {
      _normalMaxCtrl.text = (data['normalMaxCm'] ?? data['normal_max_cm'] ?? '').toString();
      _warningMinCtrl.text = (data['warningMinCm'] ?? data['warning_min_cm'] ?? '').toString();
      _warningMaxCtrl.text = (data['warningMaxCm'] ?? data['warning_max_cm'] ?? '').toString();
      _dangerMinCtrl.text = (data['dangerMinCm'] ?? data['danger_min_cm'] ?? '').toString();
      _rainLightMaxCtrl.text = (data['rainLightMax'] ?? data['rain_light_max'] ?? '').toString();
      _rainModerateMaxCtrl.text = (data['rainModerateMax'] ?? data['rain_moderate_max'] ?? '').toString();
      _rainHeavyMinCtrl.text = (data['rainHeavyMin'] ?? data['rain_heavy_min'] ?? '').toString();
      _isInitialLoading = false;
    });
  }

  Future<void> _saveThresholds() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.updateThresholds(
      normalMaxCm: int.tryParse(_normalMaxCtrl.text.trim()) ?? 0,
      warningMinCm: int.tryParse(_warningMinCtrl.text.trim()) ?? 0,
      warningMaxCm: int.tryParse(_warningMaxCtrl.text.trim()) ?? 0,
      dangerMinCm: int.tryParse(_dangerMinCtrl.text.trim()) ?? 0,
      rainLightMax: double.tryParse(_rainLightMaxCtrl.text.trim()) ?? 0,
      rainModerateMax: double.tryParse(_rainModerateMaxCtrl.text.trim()) ?? 0,
      rainHeavyMin: double.tryParse(_rainHeavyMinCtrl.text.trim()) ?? 0,
    );

    messenger.hideCurrentSnackBar();
    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Konfigurasi ambang batas berhasil diperbarui!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menyimpan konfigurasi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _normalMaxCtrl.dispose();
    _warningMinCtrl.dispose();
    _warningMaxCtrl.dispose();
    _dangerMinCtrl.dispose();
    _rainLightMaxCtrl.dispose();
    _rainModerateMaxCtrl.dispose();
    _rainHeavyMinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Konfigurasi Batas Tinggi Air (Ultrasonic)'),
            const SizedBox(height: 12),
            _buildFormInput('Level Normal Maksimal (cm)', _normalMaxCtrl),
            _buildFormInput('Level Waspada Minimal (cm)', _warningMinCtrl),
            _buildFormInput('Level Waspada Maksimal (cm)', _warningMaxCtrl),
            _buildFormInput('Level Bahaya Minimal (cm)', _dangerMinCtrl),
            const SizedBox(height: 20),
            _buildSectionHeader('Konfigurasi Batas Intensitas Curah Hujan'),
            const SizedBox(height: 12),
            _buildFormInput('Hujan Ringan Maksimal (mm/jam)', _rainLightMaxCtrl),
            _buildFormInput('Hujan Sedang Maksimal (mm/jam)', _rainModerateMaxCtrl),
            _buildFormInput('Hujan Lebat Minimal (mm/jam)', _rainHeavyMinCtrl),
            const SizedBox(height: 24),
            Consumer<AdminProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  onPressed: provider.isLoading ? null : _saveThresholds,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan Konfigurasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildFormInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Nilai wajib diisi';
          if (num.tryParse(v.trim()) == null) return 'Masukkan angka yang valid';
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }
}