import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/attendance.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

// ── Provider: All attendance for all employees ────────────
final allAttendanceProvider = StreamProvider.autoDispose<List<Attendance>>((ref) {
  return ref.watch(databaseServiceProvider).streamAllAttendance();
});

class AdminRecapScreen extends ConsumerStatefulWidget {
  const AdminRecapScreen({super.key});

  @override
  ConsumerState<AdminRecapScreen> createState() => _AdminRecapScreenState();
}

class _AdminRecapScreenState extends ConsumerState<AdminRecapScreen> {
  DateTime _filterDate = DateTime.now();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate,
      firstDate: DateTime(now.year - 3, 1),
      lastDate: now,
      helpText: 'Filter Bulan & Tahun',
      fieldLabelText: 'Tanggal (DD/MM/YYYY)',
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && mounted) {
      setState(() => _filterDate = DateTime(picked.year, picked.month, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(allEmployeesProvider);
    final attendanceAsync = ref.watch(allAttendanceProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final monthStr = DateFormat('MMMM yyyy', 'id_ID').format(_filterDate);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rekap Absensi',
                          style: Theme.of(context).textTheme.headlineLarge)
                      .animate()
                      .fadeIn(),
                  const SizedBox(height: 4),
                  Text('Ringkasan kehadiran per karyawan',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary))
                      .animate(delay: 50.ms)
                      .fadeIn(),
                ],
              ),
            ),

            // ── Filter Bulan ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: InkWell(
                onTap: _pickDate,
                borderRadius: AppRadius.sm,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.sm,
                    border:
                        Border.all(color: AppColors.primaryLight, width: 1.5),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Text('Periode: $monthStr',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ]),
                      const Icon(Icons.edit_calendar_rounded,
                          color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ).animate(delay: 100.ms).fadeIn(),
            ),

            // ── List Rekap ────────────────────────────────────
            Expanded(
              child: employeesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (employees) => attendanceAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (allAttendance) {
                    // Filter attendance untuk bulan yang dipilih
                    final monthAtt = allAttendance.where((a) {
                      return a.timestamp.year == _filterDate.year &&
                          a.timestamp.month == _filterDate.month;
                    }).toList();

                    // Hitung jumlah hari kerja bulan ini (Senin-Jumat)
                    final workDays = _countWorkDays(_filterDate);

                    if (employees.isEmpty) {
                      return Center(
                        child: Text('Belum ada karyawan',
                            style: Theme.of(context).textTheme.bodyMedium),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      itemCount: employees.length,
                      itemBuilder: (context, i) {
                        final emp = employees[i];
                        final empAtt = monthAtt
                            .where((a) =>
                                a.userId == emp.uid && !a.isMockLocation)
                            .toList();
                        final hadir = empAtt.length;
                        final telat = empAtt
                            .where((a) =>
                                a.isLate == true)
                            .length;
                        final tidakHadir =
                            (workDays - hadir).clamp(0, workDays);
                        final estimasi =
                            (settings?.pointValue ?? 35000) * emp.totalPoints;

                        return _RecapCard(
                          employee: emp,
                          hadir: hadir,
                          telat: telat,
                          tidakHadir: tidakHadir,
                          workDays: workDays,
                          estimasiGaji: fmt.format(estimasi),
                        )
                            .animate(delay: (i * 60).ms)
                            .fadeIn()
                            .slideY(begin: 0.1);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hitung jumlah hari kerja (Senin-Jumat) dalam suatu bulan.
  int _countWorkDays(DateTime month) {
    final now = DateTime.now();
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final effectiveLastDay = (month.year == now.year && month.month == now.month)
        ? now.day
        : lastDay;
    int count = 0;
    for (int d = 1; d <= effectiveLastDay; d++) {
      final day = DateTime(month.year, month.month, d).weekday;
      if (day != DateTime.saturday && day != DateTime.sunday) count++;
    }
    return count;
  }
}

class _RecapCard extends StatelessWidget {
  final AppUser employee;
  final int hadir;
  final int telat;
  final int tidakHadir;
  final int workDays;
  final String estimasiGaji;

  const _RecapCard({
    required this.employee,
    required this.hadir,
    required this.telat,
    required this.tidakHadir,
    required this.workDays,
    required this.estimasiGaji,
  });

  @override
  Widget build(BuildContext context) {
    final pctHadir = workDays > 0 ? hadir / workDays : 0.0;
    final initials = employee.name.isNotEmpty
        ? employee.name.split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    Color pctColor;
    if (pctHadir >= 0.8) {
      pctColor = AppColors.success;
    } else if (pctHadir >= 0.6) {
      pctColor = AppColors.warning;
    } else {
      pctColor = AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nama karyawan
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Text(initials,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('NIK: ${employee.nik}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: pctColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  '${(pctHadir * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: pctColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar kehadiran
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pctHadir.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(pctColor),
            ),
          ),
          const SizedBox(height: 14),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatChip(
                label: 'Hadir',
                value: '$hadir/$workDays',
                color: AppColors.success,
                bgColor: AppColors.successLight,
                icon: Icons.check_circle_outline_rounded,
              ),
              _StatChip(
                label: 'Terlambat',
                value: '$telat',
                color: AppColors.warning,
                bgColor: AppColors.warningLight,
                icon: Icons.schedule_rounded,
              ),
              _StatChip(
                label: 'Absen',
                value: '$tidakHadir',
                color: AppColors.error,
                bgColor: AppColors.errorLight,
                icon: Icons.cancel_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Estimasi gaji
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Poin: ${employee.totalPoints} poin',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(estimasiGaji,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w800, fontSize: 14)),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                      fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
