import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/report.dart';
import '../../providers/report_provider.dart';

class EmployeeReportScreen extends ConsumerStatefulWidget {
  const EmployeeReportScreen({super.key});

  @override
  ConsumerState<EmployeeReportScreen> createState() =>
      _EmployeeReportScreenState();
}

class _EmployeeReportScreenState extends ConsumerState<EmployeeReportScreen>
    with SingleTickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  late TabController _tabCtrl;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 3, 1),
      lastDate: now,
      helpText: 'Filter Bulan & Tahun',
      fieldLabelText: 'Tanggal (DD/MM/YYYY)',
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, 1));
    }
  }

  Future<void> _submit() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan kendala tidak boleh kosong')),
      );
      return;
    }

    await ref.read(reportControllerProvider.notifier).submitReport(text);

    if (!mounted) return;
    final state = ref.read(reportControllerProvider);

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim laporan: ${state.error}'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim, mohon tunggu balasan Admin'),
          backgroundColor: AppColors.success,
        ),
      );
      _msgCtrl.clear();
      _tabCtrl.animateTo(1); // switch to history tab
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportControllerProvider);
    final isLoading = state.isLoading;
    final myReportsAsync = ref.watch(myReportsProvider);
    final monthStr = DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lapor Kendala'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note_rounded), text: 'Buat Laporan'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Riwayat'),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── TAB 1: Buat Laporan ──────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ada masalah saat absen?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ).animate().fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 8),
                  Text(
                    'Tuliskan detail masalah Anda. Admin akan melakukan review dan memberikan balasan.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ).animate(delay: 50.ms).fadeIn(),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _msgCtrl,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Tulis kronologi kendala Anda di sini...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.md,
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.md,
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.md,
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                    ),
                  ).animate(delay: 100.ms).fadeIn(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _submit,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('Kirim Laporan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.sm),
                        elevation: 0,
                      ),
                    ),
                  ).animate(delay: 150.ms).fadeIn(),
                ],
              ),
            ),
          ),

          // ── TAB 2: Riwayat Laporan ───────────────────────
          SafeArea(
            child: Column(
              children: [
                // Filter bulan
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: AppRadius.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.sm,
                        border: Border.all(
                            color: AppColors.primaryLight, width: 1.5),
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
                  ),
                ),

                // List riwayat
                Expanded(
                  child: myReportsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Error: $e')),
                    data: (list) {
                      final filtered = list.where((r) {
                        final d = DateTime.fromMillisecondsSinceEpoch(
                            r.timestamp);
                        return d.year == _selectedDate.year &&
                            d.month == _selectedDate.month;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inbox_rounded,
                                  size: 64,
                                  color: AppColors.textHint),
                              const SizedBox(height: 16),
                              Text('Tidak ada laporan di bulan ini',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppColors.textSecondary)),
                            ],
                          ).animate().fadeIn(),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          return _ReportHistoryItem(report: filtered[i])
                              .animate(delay: (i * 50).ms)
                              .fadeIn()
                              .slideX(begin: 0.05);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportHistoryItem extends StatelessWidget {
  final Report report;
  const _ReportHistoryItem({required this.report});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy • HH:mm', 'id_ID')
        .format(DateTime.fromMillisecondsSinceEpoch(report.timestamp));
    final isResolved = report.status == 'resolved';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.card,
        border: Border.all(
          color: isResolved
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isResolved
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  isResolved ? 'Terselesaikan' : 'Menunggu',
                  style: TextStyle(
                    color: isResolved ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(report.message,
              style: Theme.of(context).textTheme.bodyMedium),
          if (isResolved && report.adminResponse != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: AppRadius.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.support_agent_rounded,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Balasan Admin',
                            style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(report.adminResponse!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.success)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
