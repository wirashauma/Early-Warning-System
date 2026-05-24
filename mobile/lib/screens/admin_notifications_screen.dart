import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/admin_provider.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          context.read<AdminProvider>().loadAlertHistory();
        } catch (e) {
          debugPrint('[AdminNotificationsScreen] loadAlertHistory failed: $e');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          final list = provider.alertHistory;
          final totalCount = list.length;
          final dangerCount = list
              .where((a) => a.severity.toUpperCase() == 'DANGER')
              .length;
          final warningCount = list
              .where((a) =>
                  a.severity.toUpperCase() == 'WARNING' ||
                  a.severity.toUpperCase() == 'ALERT')
              .length;

          return Column(
            children: [
              // Summary badges — driven by real data
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildInboxBadge(
                      'Total Inbox',
                      '$totalCount',
                      Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    _buildInboxBadge(
                      'Alert Bahaya',
                      '$dangerCount',
                      Colors.red,
                    ),
                    const SizedBox(width: 8),
                    _buildInboxBadge(
                      'Alert Waspada',
                      '$warningCount',
                      AppTheme.statusWaspada,
                    ),
                  ],
                ),
              ),
              // Content area
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 48,
                                  color: Color(0xFF94A3B8),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Belum ada riwayat notifikasi.',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.loadAlertHistory(),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final alert = list[index];
                                final severity =
                                    alert.severity.toUpperCase();
                                final color = severity == 'DANGER'
                                    ? Colors.redAccent
                                    : severity == 'WARNING' ||
                                            severity == 'ALERT'
                                        ? AppTheme.statusWaspada
                                        : Colors.green;
                                final dateStr = alert.sentAt
                                    .toLocal()
                                    .toString()
                                    .split('.')
                                    .first;

                                return _buildNotifyCard(
                                  alert.title.isNotEmpty
                                      ? alert.title
                                      : alert.message,
                                  alert.message,
                                  dateStr,
                                  color,
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInboxBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifyCard(
    String title,
    String body,
    String time,
    Color accent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 4, backgroundColor: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}