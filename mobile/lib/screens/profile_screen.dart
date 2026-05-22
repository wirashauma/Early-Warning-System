import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/auth_widgets.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const ProfileScreen({super.key, this.onLogout});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifFlood = true;
  bool _notifStatus = true;
  bool _notifEmail = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      body: user == null ? _buildNotLoggedIn(context) : _buildProfile(context, user),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppTheme.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, size: 56, color: AppTheme.accentBlue),
              ),
              const SizedBox(height: 20),
              const Text('Belum Masuk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                'Masuk ke akun Anda untuk mengakses profil, riwayat notifikasi, dan pengaturan personal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textGrey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              AuthButton(
                label: 'Masuk ke Akun',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen(
                    onLoginSuccess: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      setState(() {});
                    },
                  )),
                ).then((_) => setState(() {})),
              ),
              const SizedBox(height: 12),
              AuthButton(
                label: 'Daftar Akun Baru',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterScreen(
                    onLoginSuccess: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      setState(() {});
                    },
                  )),
                ).then((_) => setState(() {})),
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, UserModel user) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppTheme.primaryBlue,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.edit, size: 14, color: AppTheme.primaryBlue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(user.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.role == 'admin' ? AppTheme.statusWaspada.withValues(alpha: 0.2) : AppTheme.statusNormal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: user.role == 'admin' ? AppTheme.statusWaspada : AppTheme.statusNormal,
                        ),
                      ),
                      child: Text(
                        user.role == 'admin' ? ' 👑  Administrator' : ' 👤  Pengguna',
                        style: TextStyle(
                          color: user.role == 'admin' ? AppTheme.statusWaspada : AppTheme.statusNormal,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoSection(user),
                const SizedBox(height: 16),
                _buildNotificationSection(),
                const SizedBox(height: 16),
                _buildMenuSection(context),
                const SizedBox(height: 16),
                _buildLogoutButton(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(UserModel user) {
    return _SectionCard(
      title: 'Informasi Akun',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _InfoRow(Icons.person, 'Nama Lengkap', user.name),
          _InfoRow(Icons.email_outlined, 'Email', user.email),
          _InfoRow(Icons.phone_outlined, 'Telepon', user.phone?.isNotEmpty == true ? user.phone! : '-'),
          _InfoRow(Icons.location_on_outlined, 'Alamat', user.address?.isNotEmpty == true ? user.address! : '-'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditProfile(user),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Profil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return _SectionCard(
      title: 'Pengaturan Notifikasi',
      icon: Icons.notifications_outlined,
      child: Column(
        children: [
          _SwitchRow(
            icon: Icons.water_damage_outlined,
            label: 'Alert Banjir',
            subtitle: 'Notifikasi ketika status berubah',
            value: _notifFlood,
            color: AppTheme.accentBlue,
            onChanged: (v) => setState(() => _notifFlood = v),
          ),
          _SwitchRow(
            icon: Icons.bar_chart_outlined,
            label: 'Update Status Sensor',
            subtitle: 'Info pembaruan data sensor',
            value: _notifStatus,
            color: AppTheme.statusWaspada,
            onChanged: (v) => setState(() => _notifStatus = v),
          ),
          _SwitchRow(
            icon: Icons.email_outlined,
            label: 'Notifikasi Email',
            subtitle: 'Kirim alert ke email terdaftar',
            value: _notifEmail,
            color: AppTheme.statusNormal,
            onChanged: (v) => setState(() => _notifEmail = v),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final menus = [
      _MenuItem(Icons.history, 'Riwayat Alert', 'Lihat riwayat peringatan banjir', () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Riwayat Alert'),
            content: const Text('Belum ada riwayat alert. Alert akan muncul di sini ketika status banjir berubah.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
          ),
        );
      }),
      _MenuItem(Icons.map_outlined, 'Sensor Terdekat', 'Pantau sensor di sekitar Anda', () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sensor Aktif'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(' 📍  Sensor Hulu — Batang Arau', style: TextStyle(fontSize: 13)),
                SizedBox(height: 6),
                Text(' 📍  Sensor Tengah — Batang Arau', style: TextStyle(fontSize: 13)),
                SizedBox(height: 6),
                Text(' 📍  Sensor Hilir — Batang Arau', style: TextStyle(fontSize: 13)),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
          ),
        );
      }),
      _MenuItem(Icons.help_outline, 'Bantuan & FAQ', 'Panduan penggunaan aplikasi', () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Bantuan'),
            content: const Text('Untuk bantuan, kunjungi tab Edukasi atau hubungi kami di support@ewsfloodguard.id'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
          ),
        );
      }),
      _MenuItem(Icons.shield_outlined, 'Kebijakan Privasi', 'Cara kami melindungi data Anda', () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Kebijakan Privasi'),
            content: const Text('Data Anda disimpan secara aman di Firebase dan tidak dibagikan kepada pihak ketiga tanpa izin Anda.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
          ),
        );
      }),
      _MenuItem(Icons.info_outline, 'Tentang Aplikasi', 'Versi 1.0.0 • EWS Flood Guard', () {
        showAboutDialog(
          context: context,
          applicationName: 'EWS Flood Guard',
          applicationVersion: '1.0.0',
          applicationIcon: const Icon(Icons.water_drop, color: Color(0xFF3B82F6), size: 40),
          children: const [Text('Sistem Peringatan Dini Banjir berbasis sensor IoT untuk wilayah Batang Arau, Padang, Sumatera Barat.')],
        );
      }),
    ];
    return _SectionCard(
      title: 'Lainnya',
      icon: Icons.more_horiz,
      child: Column(
        children: menus.map((m) => _MenuTile(item: m)).toList(),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar dari Akun'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusBahaya,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('© 2026 EWS Flood Guard. All rights reserved.', style: TextStyle(color: AppTheme.textGrey, fontSize: 11)),
      ],
    );
  }

  void _showEditProfile(UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final addressCtrl = TextEditingController(text: user.address);
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(sheetCtx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                AuthTextField(label: 'Nama Lengkap', hint: 'Nama Anda', controller: nameCtrl,
                    validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null),
                const SizedBox(height: 14),
                AuthTextField(label: 'Nomor Telepon', hint: '08xxxxxxxxxx', controller: phoneCtrl,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                AuthTextField(label: 'Alamat', hint: 'Alamat tinggal Anda', controller: addressCtrl, maxLines: 2),
                const SizedBox(height: 24),
                AuthButton(
                  label: 'Simpan Perubahan',
                  isLoading: context.watch<AuthProvider>().isLoading,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final authProvider = context.read<AuthProvider>();
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final ok = await authProvider.updateProfile(
                      name: nameCtrl.text, phone: phoneCtrl.text, address: addressCtrl.text,
                    );
                    if (!mounted) return;
                    if (ok) {
                      Navigator.pop(sheetCtx);
                      setState(() {});
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Profil berhasil diperbarui'), backgroundColor: AppTheme.statusNormal),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Apakah Anda yakin ingin keluar? Anda perlu login kembali untuk mengakses fitur personal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              authProvider.logout();
              setState(() {});
              widget.onLogout?.call();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Berhasil keluar dari akun'), backgroundColor: AppTheme.statusNormal),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusBahaya, foregroundColor: Colors.white),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentBlue, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textGrey, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.icon, required this.label, required this.subtitle, required this.value, required this.color, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primaryBlue),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.title, this.subtitle, this.onTap);
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(item.icon, color: AppTheme.textGrey, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  Text(item.subtitle, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textGrey, size: 20),
          ],
        ),
      ),
    );
  }
}