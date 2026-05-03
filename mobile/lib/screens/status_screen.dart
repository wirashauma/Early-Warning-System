import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ews_appbar.dart';

class StatusScreen extends StatelessWidget {
  final VoidCallback? onRefresh;
  const StatusScreen({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EWSAppBar(onRefresh: onRefresh),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentStatus(),
            const SizedBox(height: 16),
            _buildStatusLevels(),
            const SizedBox(height: 16),
            _buildQuickDecision(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.statusNormal.withAlpha(26), AppTheme.statusNormal.withAlpha(13)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.statusNormal.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.statusNormal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('STATUS SAAT INI: NORMAL', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('126 cm', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.statusNormal)),
          const Text('Ketinggian Air - Batang Arau', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          const SizedBox(height: 12),
          const Text(
            'Kondisi sungai aman. Masyarakat dapat beraktivitas normal namun tetap memantau perkembangan melalui dashboard.',
            style: TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppTheme.textGrey),
              const SizedBox(width: 4),
              const Text('Update terakhir: 16 Mar 2026, 16:02', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLevels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LEVEL STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accentBlue, letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text('Panduan Level Status Banjir', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...[
          _StatusLevelData(
            title: 'Hijau (Normal)',
            color: AppTheme.statusNormal,
            icon: Icons.check_box_outlined,
            desc: 'Kondisi aman, ketinggian air di bawah ambang batas waspada.',
            range: '< 150 cm',
            action: 'Aktivitas normal, tetap pantau dashboard setiap 30 menit.',
            isActive: true,
          ),
          _StatusLevelData(
            title: 'Kuning (Waspada)',
            color: AppTheme.statusWaspada,
            icon: Icons.warning_amber_outlined,
            desc: 'Ketinggian air meningkat, masyarakat diminta waspada dan bersiap.',
            range: '150 - 199 cm',
            action: 'Siapkan tas darurat, dokumen penting, dan rute evakuasi keluarga.',
          ),
          _StatusLevelData(
            title: 'Oren (Siaga)',
            color: AppTheme.statusSiaga,
            icon: Icons.notifications_active_outlined,
            desc: 'Kondisi mendekati bahaya, masyarakat diminta bersiap untuk evakuasi segera.',
            range: '190 - 219 cm',
            action: 'Aktifkan rencana evakuasi dan prioritaskan kelompok rentan untuk bergerak lebih awal.',
          ),
          _StatusLevelData(
            title: 'Merah (Bahaya / Evakuasi)',
            color: AppTheme.statusBahaya,
            icon: Icons.dangerous_outlined,
            desc: 'Kondisi darurat, evakuasi segera diperlukan sesuai arahan petugas.',
            range: '≥ 220 cm',
            action: 'Segera evakuasi ke titik aman terdekat dan ikuti arahan petugas.',
          ),
        ].map((data) => _StatusLevelCard(data: data)),
      ],
    );
  }

  Widget _buildQuickDecision() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Keputusan Cepat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: [
              _QuickDecisionCard('Normal', AppTheme.statusNormal, 'Pantau rutin, tidak perlu evakuasi.'),
              _QuickDecisionCard('Waspada', AppTheme.statusWaspada, 'Siapkan rencana evakuasi keluarga.'),
              _QuickDecisionCard('Siaga', AppTheme.statusSiaga, 'Kurangi aktivitas luar, siap bergerak ke titik aman.'),
              _QuickDecisionCard('Bahaya', AppTheme.statusBahaya, 'Evakuasi segera ke titik aman resmi.'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusLevelData {
  final String title, desc, range, action;
  final Color color;
  final IconData icon;
  final bool isActive;

  _StatusLevelData({
    required this.title,
    required this.color,
    required this.icon,
    required this.desc,
    required this.range,
    required this.action,
    this.isActive = false,
  });
}

class _StatusLevelCard extends StatelessWidget {
  final _StatusLevelData data;

  const _StatusLevelCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.isActive ? data.color.withAlpha(13) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: data.isActive ? data.color.withAlpha(102) : const Color(0xFFE2E8F0),
          width: data.isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 24, height: 4, decoration: BoxDecoration(color: data.color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Icon(data.icon, color: data.color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(data.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: data.color)),
              ),
              if (data.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: data.color, borderRadius: BorderRadius.circular(10)),
                  child: const Text('AKTIF', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(data.desc, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.4)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ambang indikator', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppTheme.textGrey)),
                const SizedBox(height: 2),
                Text(data.range, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bolt, color: data.color, size: 14),
              const SizedBox(width: 4),
              const Text('Tindakan cepat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppTheme.accentBlue)),
            ],
          ),
          const SizedBox(height: 4),
          Text(data.action, style: TextStyle(color: data.color.withAlpha(204), fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}

class _QuickDecisionCard extends StatelessWidget {
  final String title, desc;
  final Color color;

  const _QuickDecisionCard(this.title, this.color, this.desc);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 10, color: AppTheme.textGrey, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
