import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/auth_provider.dart';
import '../models/admin_provider.dart';
import '../models/alert_model.dart';
import '../services/notification_service.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});
  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  StreamSubscription? _sub;
  bool _markingAllRead = false;

  @override
  void initState() {
    super.initState();
    // load initial history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<AdminProvider>().loadAlertHistory();
      } catch (e) {
        debugPrint('[NotifikasiPage] loadAlertHistory failed: $e');
      }
    });

    // listen to incoming foreground messages to refresh list
    _sub = NotificationService.instance.onMessageStream.listen((message) {
      try {
        context.read<AdminProvider>().loadAlertHistory();
      } catch (e) {
        debugPrint('[NotifikasiPage] realtime refresh failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<AdminProvider>().loadAlertHistory();
  }

  Future<void> _markAllAsRead() async {
    if (_markingAllRead) return;

    final authProvider = context.read<AuthProvider>();
    final adminProvider = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _markingAllRead = true);
    final success = await authProvider.markNotificationsReadAll();

    if (!mounted) return;

    if (success) {
      await adminProvider.loadAlertHistory();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Semua notifikasi ditandai sudah dibaca.'),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ??
                'Gagal menandai notifikasi sebagai dibaca.',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() => _markingAllRead = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Notifikasi Peringatan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          final List<AlertModel> list = provider.alertHistory;
          final readAt = context
              .watch<AuthProvider>()
              .currentUser
              ?.notificationReadAt;
          final unreadCount = list.where((a) {
            final cutoff = readAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return a.sentAt.isAfter(cutoff);
          }).length;
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Belum dibaca: $unreadCount',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed: _markingAllRead ? null : _markAllAsRead,
                        child: _markingAllRead
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Tandai semua dibaca',
                                style: TextStyle(fontSize: 13),
                              ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : list.isEmpty
                      ? const Center(child: Text('Belum ada notifikasi'))
                      : ListView.builder(
                          itemCount: list.length,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemBuilder: (context, index) {
                            final alert = list[index];
                            return _buildNotificationCardFromModel(alert);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCardFromModel(AlertModel alert) {
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
    final dateStr = alert.sentAt.toLocal().toString().split('.').first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              Text(
                dateStr,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert.title.isNotEmpty ? alert.title : alert.message,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            alert.message,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(
                      alert.title.isNotEmpty
                          ? alert.title
                          : 'Detail Peringatan',
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tingkat: $tag',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            alert.message,
                            style: const TextStyle(height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Waktu: $dateStr',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Buka Detail",
                style: TextStyle(color: Colors.black87, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
