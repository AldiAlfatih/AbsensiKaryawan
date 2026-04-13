import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/attendance.dart';
import '../../providers/attendance_provider.dart';

class EmployeeHistoryScreen extends ConsumerWidget {
  const EmployeeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(myAttendanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        backgroundColor: AppColors.surface,
        leading: const BackButton(),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (context, i) {
              return _AttendanceItem(item: list[i])
                  .animate(delay: (i * 40).ms)
                  .fadeIn()
                  .slideX(begin: 0.1);
            },
          );
        },
      ),
    );
  }
}

class _AttendanceItem extends StatelessWidget {
  final Attendance item;
  const _AttendanceItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEE, d MMM yyyy', 'id_ID').format(item.timestamp);
    final timeStr = DateFormat('HH:mm').format(item.timestamp);
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: AppRadius.sm,
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Jam $timeStr  •  $distStr dari kantor',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: AppRadius.full,
            ),
            child: Text(
              statusLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Riwayat',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Absensi pertama Anda akan muncul di sini',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
