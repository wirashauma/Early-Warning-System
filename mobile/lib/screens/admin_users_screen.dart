import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/admin_provider.dart';
import '../models/auth_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loadedOnce = false;

  Future<void> _confirmDeleteUser(
    BuildContext context,
    String id,
    String name,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Hapus Pengguna'),
              content: Text(
                'Apakah Anda yakin ingin menghapus pengguna "$name"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Hapus',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    final provider = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Menghapus pengguna...')),
    );

    final success = await provider.deleteUser(id);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pengguna berhasil dihapus.'
              : provider.errorMessage ?? 'Gagal menghapus pengguna.',
        ),
      ),
    );
  }

  Future<void> _showCreateUserSheet(BuildContext context) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'USER';
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tambah Pengguna',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Nama'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama wajib diisi.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email wajib diisi.';
                            }
                            if (!value.contains('@')) {
                              return 'Masukkan email yang valid.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password wajib diisi.';
                            }
                            if (value.trim().length < 6) {
                              return 'Password minimal 6 karakter.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'No. WA',
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: role,
                          decoration: const InputDecoration(labelText: 'Role'),
                          items: const [
                            DropdownMenuItem(
                              value: 'ADMIN',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'USER',
                              child: Text('User'),
                            ),
                          ],
                          onChanged: (selected) {
                            if (selected != null) {
                              setSheetState(() => role = selected);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    final messenger = ScaffoldMessenger.of(context);
                                    final provider = context.read<AdminProvider>();
                                    setSheetState(() => isSubmitting = true);
                                    final success = await provider.createUser(
                                      name: nameController.text.trim(),
                                      email: emailController.text.trim(),
                                      password: passwordController.text.trim(),
                                      role: role,
                                      phone: phoneController.text.trim().isEmpty
                                          ? null
                                          : phoneController.text.trim(),
                                    );
                                    setSheetState(() => isSubmitting = false);
                                    if (success) {
                                      provider.loadUsers().catchError((e) {
                                        debugPrint('loadUsers failed: $e');
                                        return const <dynamic>[];
                                      });
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Pengguna baru berhasil ditambahkan.',
                                            ),
                                          ),
                                        );
                                      }
                                      Navigator.of(sheetContext).pop();
                                    } else {
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              provider.errorMessage ??
                                                  'Gagal membuat pengguna.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Tambah Pengguna'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
  }

  Future<void> _showEditUserSheet(
    BuildContext context,
    Map<String, dynamic> user,
  ) async {
    final nameController = TextEditingController(
      text: user['name']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: user['email']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: user['phone']?.toString() ?? '',
    );
    String role = (user['role']?.toString().toUpperCase() == 'ADMIN')
        ? 'ADMIN'
        : 'USER';
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Pengguna',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Nama'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama wajib diisi.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email wajib diisi.';
                            }
                            if (!value.contains('@')) {
                              return 'Masukkan email yang valid.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'No. WA',
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: role,
                          decoration: const InputDecoration(labelText: 'Role'),
                          items: const [
                            DropdownMenuItem(
                              value: 'ADMIN',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'USER',
                              child: Text('User'),
                            ),
                          ],
                          onChanged: (selected) {
                            if (selected != null) {
                              setSheetState(() => role = selected);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    final messenger = ScaffoldMessenger.of(context);
                                    final provider = context.read<AdminProvider>();
                                    setSheetState(() => isSubmitting = true);
                                    final success = await provider.updateUser(
                                      id: user['id']?.toString() ?? '',
                                      name: nameController.text.trim(),
                                      email: emailController.text.trim(),
                                      role: role,
                                      phone: phoneController.text.trim().isEmpty
                                          ? null
                                          : phoneController.text.trim(),
                                      institution: user['institution']
                                          ?.toString(),
                                    );
                                    setSheetState(() => isSubmitting = false);
                                    if (success) {
                                      provider.loadUsers().catchError((e) {
                                        debugPrint('loadUsers failed: $e');
                                        return const <dynamic>[];
                                      });
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Pengguna berhasil diperbarui.',
                                            ),
                                          ),
                                        );
                                      }
                                      Navigator.of(sheetContext).pop();
                                    } else {
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              provider.errorMessage ??
                                                  'Gagal memperbarui pengguna.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Simpan Perubahan'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Keluar Aplikasi'),
              content: const Text(
                'Apakah Anda yakin ingin keluar dari aplikasi?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    context.read<AuthProvider>().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          await context.read<AdminProvider>().loadUsers();
        } catch (e) {
          debugPrint('[AdminUsersScreen] loadUsers failed: $e');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final users = adminProvider.users
        .whereType<Map<String, dynamic>>()
        .toList();
    final adminCount = users
        .where(
          (u) => (u['role'] ?? '').toString().toUpperCase().contains('ADMIN'),
        )
        .length;
    final userCount = users.length - adminCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          if (adminProvider.errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFCA5A5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                adminProvider.errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manajemen Pengguna',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateUserSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Pengguna'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildStatBadge(
                  'Total Akun',
                  '${users.length}',
                  Colors.black87,
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  'Role Admin',
                  '$adminCount',
                  const Color(0xFF0066FF),
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  'Role User',
                  '$userCount',
                  const Color(0xFF10B981),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Daftar Akun Otorisasi Sistem',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: adminProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data pengguna dari backend.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];
                      final role = (u['role'] ?? '').toString();
                      final isAdmin = role.toUpperCase().contains('ADMIN');
                      final name = (u['name'] ?? '-').toString();
                      final email = (u['email'] ?? '-').toString();
                      final phone = (u['phone'] ?? '-').toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
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
                                  Row(
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAdmin
                                              ? const Color(0xFFEFF6FF)
                                              : const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          role.isEmpty ? 'User' : role,
                                          style: TextStyle(
                                            color: isAdmin
                                                ? const Color(0xFF0066FF)
                                                : const Color(0xFF10B981),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'No. WA: $phone',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xFF64748B),
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      _showEditUserSheet(context, u),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  onPressed: () => _confirmDeleteUser(
                                    context,
                                    u['id']?.toString() ?? '',
                                    name,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Keluar Aplikasi'),
                onPressed: () => _showLogoutDialog(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String title, String value, Color txtColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: txtColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
