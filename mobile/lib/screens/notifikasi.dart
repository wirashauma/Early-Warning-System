import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
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
      if (!mounted) return;
      try {
        context.read<AdminProvider>().loadAlertHistory();
      } catch (e) {
        debugPrint('[NotifikasiPage] loadAlertHistory failed: $e');
      }
    });

    // listen to incoming foreground messages to refresh list
    _sub = NotificationService.instance.onMessageStream.listen((message) {
      if (!mounted) return;
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
        title: Text(
          context.t('notificationPageTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          final List<AlertModel> list = provider.alertHistory;
          final currentUser = context.watch<AuthProvider>().currentUser;
          final readAt = currentUser?.notificationReadAt;
          final readIds = currentUser?.readNotificationIds ?? [];

          final unreadCount = list.where((a) {
            if (readIds.contains(a.id)) return false;
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
                        '${context.t('unreadCount')}$unreadCount',
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
                            : Text(
                                context.t('markAllRead'),
                                style: const TextStyle(fontSize: 13),
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
                      ? Center(child: Text(context.t('noNotifications')))
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
        ? context.t('danger')
        : severity == 'WARNING'
        ? context.t('warning')
        : context.t('safe');
    final color = severity == 'DANGER'
        ? Colors.red
        : severity == 'WARNING'
        ? AppTheme.statusWaspada
        : Colors.green;
    final dateStr = alert.sentAt.toLocal().toString().split('.').first;

    final currentUser = context.watch<AuthProvider>().currentUser;
    final readAt = currentUser?.notificationReadAt;
    final readIds = currentUser?.readNotificationIds ?? [];
    final isRead = readIds.contains(alert.id) ||
        (readAt != null && !alert.sentAt.isAfter(readAt));

    void handleOpenDetail() {
      if (!isRead) {
        final auth = context.read<AuthProvider>();
        final admin = context.read<AdminProvider>();
        auth.markNotificationAsRead(alert.id).then((success) {
          if (success) {
            admin.loadAlertHistory();
          }
        });
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            alert.title.isNotEmpty ? alert.title : 'Detail Peringatan',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${context.t('level')}$tag',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  alert.message,
                  style: const TextStyle(height: 1.5, fontSize: 14, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 16),
                Text(
                  '${context.t('time')}$dateStr',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.t('close'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: handleOpenDetail,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
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
                    color: color.withAlpha(26),
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
                if (!isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Baru',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
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
                onPressed: handleOpenDetail,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFF93C5FD),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Buka Detail",
                  style: TextStyle(
                    color: isRead ? Colors.black87 : Colors.blue[700],
                    fontSize: 12,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
