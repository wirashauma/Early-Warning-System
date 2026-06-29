import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../models/alert_model.dart';
import '../models/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ews_appbar.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<AlertModel>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _fetchAlerts();
  }

  Future<List<AlertModel>> _fetchAlerts() async {
    return _apiService.fetchActiveAlerts();
  }

  void _refreshAlerts() {
    setState(() {
      _alertsFuture = _fetchAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EWSAppBar(onRefresh: _refreshAlerts),
      backgroundColor: AppTheme.pageBg,
      body: RefreshIndicator(
        onRefresh: () async => _refreshAlerts(),
        child: FutureBuilder<List<AlertModel>>(
          future: _alertsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppTheme.statusBahaya,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat alert terbaru:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.statusBahaya,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refreshAlerts,
                          child: Text(context.t('retry')),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final alerts = snapshot.data ?? const <AlertModel>[];

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [_buildHeader(), _buildAlertsList(alerts)],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: Colors.white,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifikasi & Alert',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pantau notifikasi banjir dan update sistem',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(List<AlertModel> alerts) {
    if (alerts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(context.t('noActiveAlerts'))),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: alerts.map((alert) {
          final severity = alert.severity.toUpperCase();
          final color = severity == 'DANGER'
              ? AppTheme.statusBahaya
              : severity == 'WARNING'
              ? AppTheme.statusWaspada
              : AppTheme.accentBlue;
          final icon = severity == 'DANGER'
              ? Icons.error_outline
              : severity == 'WARNING'
              ? Icons.warning_outlined
              : Icons.info_outlined;
          final time = alert.sentAt.toLocal().toString().split('.').first;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(26),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title.isNotEmpty ? alert.title : 'Alert',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      severity,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
