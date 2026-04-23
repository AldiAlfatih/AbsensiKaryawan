import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/export_service.dart';
import '../../core/constants.dart';
import '../../models/app_settings.dart';

import 'admin_reports_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_leave_screen.dart';
import 'admin_recap_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _AdminDashboardView(),
    const AdminReportsScreen(),
    const AdminLeaveScreen(),
    const AdminRecapScreen(),
    const AdminSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Karyawan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.support_agent_rounded),
              label: 'Laporan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_rounded),
              label: 'Cuti & Izin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Rekap',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboardView extends ConsumerStatefulWidget {
  const _AdminDashboardView();

  @override
  ConsumerState<_AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends ConsumerState<_AdminDashboardView> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(allEmployeesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminCreateEmployee),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text(
          'Tambah Karyawan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard Admin',
                            style:
                                Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sistem Pusat Kendali',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ).animate().fadeIn(),
                    ),
                    // Admin avatar / logout
                    Consumer(
                      builder: (context, ref, child) {
                        final profile = ref.watch(currentUserProfileProvider).valueOrNull;
                        return _AdminAvatar(
                          profile: profile,
                          onLogout: () async {
                            final nav = GoRouter.of(context);
                            await ref.read(authNotifierProvider.notifier).signOut();
                            nav.go(AppRoutes.login);
                          },
                        ).animate(delay: 100.ms).fadeIn();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats summary ────────────────────────────────
            SliverToBoxAdapter(
              child: employeesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
                data: (employees) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: _StatsBanner(employees: employees)
                      .animate(delay: 150.ms)
                      .fadeIn()
                      .slideY(begin: 0.1),
                ),
              ),
            ),

            // ── Search bar ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Cari karyawan...',
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.textSecondary),
                  ),
                ).animate(delay: 200.ms).fadeIn(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Section label ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daftar Karyawan',
                      style: Theme.of(context).textTheme.titleLarge,
                    ).animate(delay: 220.ms).fadeIn(),
                    
                    employeesAsync.maybeWhen(
                      data: (employees) {
                        return IconButton(
                          onPressed: () async {
                            final settings = ref.read(settingsProvider).valueOrNull ?? const AppSettings(pointValue: AppConstants.defaultPointValue, allowedRadius: 50.0);
                            await ExportService.exportEmployeeRecap(employees, settings);
                          },
                          icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                          tooltip: 'Ekspor Payroll (CSV)',
                        ).animate(delay: 220.ms).fadeIn();
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Employee list ────────────────────────────────
            employeesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
              data: (employees) {
                final filtered = _query.isEmpty
                    ? employees
                    : employees
                        .where((e) =>
                            e.name.toLowerCase().contains(_query) ||
                            e.email.toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Tidak ada karyawan ditemukan',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        return _EmployeeTile(
                          employee: filtered[i],
                          index: i,
                          onTap: () {
                            ref
                                .read(selectedEmployeeUidProvider.notifier)
                                .state = filtered[i].uid;
                            context.push(
                              AppRoutes.adminEmployeeDetailPath(
                                  filtered[i].uid),
                            );
                          },
                        );
                      },
                      childCount: filtered.length,
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
}

// ─────────────────────────────────────────────────────────
// STATS BANNER
// ─────────────────────────────────────────────────────────

class _StatsBanner extends StatelessWidget {
  final List<AppUser> employees;
  const _StatsBanner({required this.employees});

  @override
  Widget build(BuildContext context) {
    final totalPoints =
        employees.fold<int>(0, (sum, e) => sum + e.totalPoints);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Karyawan',
            value: '${employees.length}',
            icon: Icons.people_rounded,
            color: AppColors.primary,
            bgColor: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Total Poin',
            value: '$totalPoints',
            icon: Icons.star_rounded,
            color: AppColors.warning,
            bgColor: AppColors.warningLight,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: AppRadius.sm),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: Theme.of(context).textTheme.headlineSmall),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// EMPLOYEE TILE
// ─────────────────────────────────────────────────────────

class _EmployeeTile extends StatelessWidget {
  final AppUser employee;
  final int index;
  final VoidCallback onTap;

  const _EmployeeTile({
    required this.employee,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = employee.name.isNotEmpty
        ? employee.name.split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    ImageProvider? avatarImage;
    if (employee.photoUrl != null && employee.photoUrl!.isNotEmpty) {
      try {
        avatarImage = MemoryImage(base64Decode(employee.photoUrl!));
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(employee.email,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.full,
              ),
              child: Text(
                '${employee.totalPoints} poin',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ADMIN AVATAR
// ─────────────────────────────────────────────────────────

class _AdminAvatar extends StatelessWidget {
  final AppUser? profile;
  final VoidCallback onLogout;
  const _AdminAvatar({this.profile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImage;
    if (profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty) {
      try {
        avatarImage = MemoryImage(base64Decode(profile!.photoUrl!));
      } catch (_) {}
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      onSelected: (value) {
        if (value == 'logout') onLogout();
        if (value == 'edit') context.push(AppRoutes.editProfile);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded,
                  color: AppColors.adminAccent, size: 20),
              const SizedBox(width: 8),
              Text('Administrator',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.adminAccent,
                      )),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.manage_accounts_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              const Text('Edit Profil',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 12),
              const Text('Keluar Akun',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.adminLight,
          borderRadius: AppRadius.sm,
          image: avatarImage != null ? DecorationImage(image: avatarImage, fit: BoxFit.cover) : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (avatarImage == null)
              Center(
                child: Icon(Icons.admin_panel_settings_rounded,
                    color: AppColors.adminAccent, size: 24),
              ),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
