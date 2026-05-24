import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/admin_provider.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController(
    text: 'Peringatan Kenaikan Debit Air',
  );
  final TextEditingController _messageCtrl = TextEditingController(
    text: 'Peringatan: Kenaikan volume air terdeteksi di pintu air hulu.',
  );
  String _selectedLevel = 'Waspada';
  bool _sendPush = true;
  bool _sendEmail = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final provider = context.read<AdminProvider>();
        provider.loadAlertHistory();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Siarkan Peringatan Manual (Broadcast)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Tingkat Bahaya',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Aman', 'Waspada', 'Bahaya']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedLevel = val ?? _selectedLevel),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Judul Peringatan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Judul wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Pesan Peringatan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Pesan wajib diisi'
                      : null,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text(
                    'Kirim via Push Notification',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: _sendPush,
                  onChanged: (v) => setState(() => _sendPush = v!),
                ),
                CheckboxListTile(
                  title: const Text(
                    'Kirim via Email',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: _sendEmail,
                  onChanged: (v) => setState(() => _sendEmail = v!),
                ),
                const SizedBox(height: 12),
                Consumer<AdminProvider>(
                  builder: (context, provider, _) {
                    return ElevatedButton(
                      onPressed: provider.isLoading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;

                              final channels = <String>[];
                              if (_sendPush) channels.add('push');
                              if (_sendEmail) channels.add('email');

                              if (channels.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Pilih minimal satu saluran (Push/Email)',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final severity = _selectedLevel == 'Bahaya'
                                  ? 'DANGER'
                                  : _selectedLevel == 'Waspada'
                                  ? 'WARNING'
                                  : 'INFO';

                              final success = await provider.broadcastAlert(
                                title: _titleCtrl.text.trim(),
                                message: _messageCtrl.text.trim(),
                                severity: severity,
                                channels: channels,
                                pushEnabled: _sendPush,
                              );

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Peringatan berhasil disiarkan',
                                    ),
                                  ),
                                );
                                // clear message but keep title as template
                                _messageCtrl.clear();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      provider.errorMessage ??
                                          'Gagal mengirim peringatan',
                                    ),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size(double.infinity, 45),
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
                              'SIARKAN SEKARANG',
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
          const SizedBox(height: 24),
          const Text(
            'Riwayat Broadcast Kebencanaan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Consumer<AdminProvider>(
            builder: (context, provider, _) {
              final list = provider.alertHistory;
              if (provider.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (list.isEmpty) {
                return const Text('Belum ada riwayat broadcast.');
              }
              return Column(
                children: list.map((alert) {
                  final severity = alert.severity.toUpperCase();
                  final tag = severity == 'DANGER'
                      ? 'Bahaya'
                      : severity == 'WARNING'
                      ? 'Waspada'
                      : 'Aman';
                  final color = severity == 'DANGER'
                      ? Colors.red
                      : severity == 'WARNING'
                      ? AppTheme.statusWaspada
                      : Colors.green;
                  final dateStr = alert.sentAt
                      .toLocal()
                      .toString()
                      .split('.')
                      .first;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.campaign, color: color),
                      title: Text(
                        alert.title.isNotEmpty ? alert.title : alert.message,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        dateStr,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // History items rendered above from provider
}
