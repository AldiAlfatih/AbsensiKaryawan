import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
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
                            'Kelola absensi karyawan',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ).animate().fadeIn(),
                    ),
                    // Admin avatar / logout
                    _AdminAvatar(
                      onLogout: () async {
                        final nav = GoRouter.of(context);
                        await ref
                            .read(authNotifierProvider.notifier)
                            .signOut();
                        nav.go(AppRoutes.login);
                      },
                    ).animate(delay: 100.ms).fadeIn(),
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
                child: Text(
                  'Daftar Karyawan',
                  style: Theme.of(context).textTheme.titleLarge,
                ).animate(delay: 220.ms).fadeIn(),
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
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
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
  final VoidCallback onLogout;
  const _AdminAvatar({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onLogout,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.adminLight,
          borderRadius: AppRadius.sm,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
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
                  color: AppColors.error,
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
