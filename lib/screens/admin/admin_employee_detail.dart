import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/attendance.dart';
import '../../providers/admin_provider.dart';
import '../../providers/settings_provider.dart';

class AdminEmployeeDetailScreen extends ConsumerWidget {
  final String uid;
  const AdminEmployeeDetailScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Make sure the selected employee UID is set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedEmployeeUidProvider.notifier).state = uid;
    });

    final profileAsync = ref.watch(selectedEmployeeProfileProvider);
    final historyAsync = ref.watch(selectedEmployeeAttendanceProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) =>
            Scaffold(body: Center(child: Text('Error: $e'))),
        data: (profile) => CustomScrollView(
          slivers: [
            // ── Hero header ──────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surface,
                padding: EdgeInsets.fromLTRB(
                    24, MediaQuery.of(context).padding.top + 16, 24, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const BackButton(),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        profile?.name.isNotEmpty == true
                            ? profile!.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                        ),
                      ),
                    ).animate().scale(begin: const Offset(0.8, 0.8)),
                    const SizedBox(height: 12),
                    Text(
                      profile?.name ?? '-',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ).animate(delay: 100.ms).fadeIn(),
                    Text(
                      profile?.email ?? '-',
                      style: Theme.of(context).textTheme.bodySmall,
                    ).animate(delay: 120.ms).fadeIn(),
                    if ((profile?.nik ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'NIK: ${profile!.nik}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // ── Points card ──────────────────────────
                    _EmployeePointsCard(
                      points: profile?.totalPoints ?? 0,
                      pointValue: settings?.pointValue ?? AppConstants.defaultPointValue,
                    )
                        .animate(delay: 160.ms)
                        .fadeIn()
                        .slideY(begin: 0.1),
                  ],
                ),
              ),
            ),

            // ── History header ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Text(
                  'Riwayat Absensi',
                  style: Theme.of(context).textTheme.titleLarge,
                ).animate(delay: 200.ms).fadeIn(),
              ),
            ),

            // ── History list ─────────────────────────────────
            historyAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_rounded,
                              size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text('Belum ada riwayat',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ).animate().fadeIn(),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _AdminAttendanceItem(
                        item: list[i],
                        index: i,
                      ),
                      childCount: list.length,
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
// EMPLOYEE POINTS CARD (admin view)
// ─────────────────────────────────────────────────────────

class _EmployeePointsCard extends StatelessWidget {
  final int points;
  final int pointValue;
  const _EmployeePointsCard({
    required this.points,
    required this.pointValue,
  });

  @override
  Widget build(BuildContext context) {
    final rupiah = points * pointValue;
    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4361EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lg,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akumulasi Poin',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '$points Poin',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: AppRadius.full,
                  ),
                  child: Text(
                    '≈ ${fmt.format(rupiah)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: AppRadius.md,
                ),
                child: const Icon(Icons.star_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                '1 poin = Rp ${NumberFormat('#,###', 'id_ID').format(pointValue)}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ATTENDANCE ITEM (admin view)
// ─────────────────────────────────────────────────────────

class _AdminAttendanceItem extends StatelessWidget {
  final Attendance item;
  final int index;
  const _AdminAttendanceItem({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEE, d MMM yyyy', 'id_ID').format(item.timestamp);
    final timeStr = DateFormat('HH:mm:ss').format(item.timestamp);
    final distStr = '${item.distanceFromOffice.toStringAsFixed(0)} m';

    final Color statusColor;
    final Color statusBg;
    final IconData statusIcon;
    final String statusLabel;

    if (item.isMockLocation) {
      statusColor = AppColors.error;
      statusBg = AppColors.errorLight;
      statusIcon = Icons.gps_off_rounded;
      statusLabel = 'GPS Palsu';
    } else {
      statusColor = AppColors.success;
      statusBg = AppColors.successLight;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Berhasil';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(color: statusBg, borderRadius: AppRadius.sm),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  'Jam $timeStr  •  $distStr dari kantor',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: AppRadius.full,
            ),
            child: Text(
              statusLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 40).ms).fadeIn().slideX(begin: 0.05);
  }
}
