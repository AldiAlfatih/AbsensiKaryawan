import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/attendance.dart';
import '../../providers/attendance_provider.dart';

class EmployeeHistoryScreen extends ConsumerStatefulWidget {
  const EmployeeHistoryScreen({super.key});

  @override
  ConsumerState<EmployeeHistoryScreen> createState() => _EmployeeHistoryScreenState();
}

class _EmployeeHistoryScreenState extends ConsumerState<EmployeeHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 3, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Pilih Tanggal',
      fieldLabelText: 'Tanggal (DD/MM/YYYY)',
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      if (mounted) {
        setState(() => _selectedDate = picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(myAttendanceProvider);
    final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        backgroundColor: AppColors.surface,
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          // Filter Box
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: InkWell(
              onTap: _selectDate,
              borderRadius: AppRadius.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.sm,
                  border: Border.all(color: AppColors.primaryLight, width: 1.5),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Tanggal: $dateStr', 
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ]
                    ),
                    const Icon(Icons.edit_calendar_rounded, color: AppColors.primary),
                  ]
                )
              )
            ).animate().fadeIn().slideY(begin: -0.1),
          ),
          
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                // FILTERING LOGIC
                final filtered = list.where((item) {
                  if (item.timestamp.millisecondsSinceEpoch == 0) return false;
                  return item.timestamp.year == _selectedDate.year && 
                         item.timestamp.month == _selectedDate.month && 
                         item.timestamp.day == _selectedDate.day;
                }).toList();

                if (filtered.isEmpty) {
                  return _EmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    return _AttendanceItem(item: filtered[i])
                        .animate(delay: (i * 40).ms)
                        .fadeIn()
                        .slideX(begin: 0.1);
                  },
                );
              },
            ),
          ),
        ],
      )
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
