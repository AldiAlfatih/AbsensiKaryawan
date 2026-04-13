import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/attendance.dart';
import '../../providers/admin_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_service.dart';

class AdminEmployeeDetailScreen extends ConsumerStatefulWidget {
  final String uid;
  const AdminEmployeeDetailScreen({super.key, required this.uid});

  @override
  ConsumerState<AdminEmployeeDetailScreen> createState() => _AdminEmployeeDetailScreenState();
}

class _AdminEmployeeDetailScreenState extends ConsumerState<AdminEmployeeDetailScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Make sure the selected employee UID is set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedEmployeeUidProvider.notifier).state = widget.uid;
    });
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    // Generate up to 24 months back
    final months = List.generate(24, (i) => DateTime(now.year, now.month - i, 1));
    
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 16),
            Text('Pilih Periode', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: months.length,
                itemBuilder: (ctx, i) {
                  final date = months[i];
                  final label = DateFormat('MMMM yyyy', 'id_ID').format(date);
                  final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month;
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    title: Text(label, style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    )),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                    onTap: () => Navigator.pop(ctx, date),
                  );
                }
              )
            ),
          ]
        )
      )
    );
    
    if (selected != null) {
      if (mounted) setState(() => _selectedDate = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(selectedEmployeeProfileProvider);
    final historyAsync = ref.watch(selectedEmployeeAttendanceProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final monthStr = DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate);

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

                    if (profile != null) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteUser(context, ref, profile),
                          icon: const Icon(Icons.delete_forever_rounded),
                          label: const Text('Hapus Akun Karyawan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ).animate(delay: 180.ms).fadeIn(),
                    ]
                  ],
                ),
              ),
            ),

            // ── History header ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Absensi',
                      style: Theme.of(context).textTheme.titleLarge,
                    ).animate(delay: 200.ms).fadeIn(),
                    
                    InkWell(
                      onTap: _selectMonth,
                      borderRadius: AppRadius.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: AppRadius.sm,
                        ),
                        child: Row(
                          children: [
                            Text(
                              monthStr,
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 16),
                          ],
                        ),
                      ),
                    ).animate(delay: 200.ms).fadeIn(),
                  ],
                ),
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
                final filtered = list.where((item) {
                  final d = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
                  return d.year == _selectedDate.year && d.month == _selectedDate.month;
                }).toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_rounded,
                              size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text('Belum ada riwayat di bulan ini',
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
                        item: filtered[i],
                        index: i,
                      ),
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

  void _deleteUser(BuildContext context, WidgetRef ref, AppUser profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Permanen?'),
        content: Text('Anda yakin ingin menghapus data ${profile.name}? Data profil akan terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(databaseServiceProvider);
              await db.deleteUser(profile.uid);
              if (context.mounted) Navigator.pop(context); // Kembali ke list
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Hapus Karyawan'),
          ),
        ],
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

class _AdminAttendanceItem extends ConsumerWidget {
  final Attendance item;
  final int index;
  const _AdminAttendanceItem({required this.item, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => _deleteAttendance(context, ref, item),
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    ).animate(delay: (index * 40).ms).fadeIn().slideX(begin: 0.05);
  }

  void _deleteAttendance(BuildContext context, WidgetRef ref, Attendance item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data Absen?'),
        content: const Text('Data absen ini akan dihapus permanen, dan 1 poin milik karyawan akan ditarik kembali.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(databaseServiceProvider);
              await db.deleteAttendanceRecord(item.id);
              await db.incrementPoints(item.userId, delta: -1);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Hapus & Cabut Poin'),
          ),
        ],
      ),
    );
  }
}

