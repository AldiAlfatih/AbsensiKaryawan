import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/report_provider.dart';
import '../../models/report.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
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
      if (mounted) setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Tiket Laporan Kendala'),
          backgroundColor: AppColors.surface,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Riwayat Laporan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPendingTab(ref),
            _buildHistoryTab(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab(WidgetRef ref) {
    final reportsAsync = ref.watch(pendingReportsProvider);

    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 64, color: AppColors.successLight),
                const SizedBox(height: 16),
                Text(
                  'Semua Aman',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tidak ada laporan kendala dari karyawan.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ).animate().fadeIn().slideY(begin: 0.1),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _ReportItemCard(
              report: report,
              index: index,
              onResolve: () => _showResolveDialog(context, ref, report.id),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(WidgetRef ref) {
    final historyAsync = ref.watch(allReportsProvider);
    final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Riwayat Global', style: Theme.of(context).textTheme.titleMedium),
              InkWell(
                onTap: _selectDate,
                borderRadius: AppRadius.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.sm),
                  child: Row(
                    children: [
                      Text(dateStr, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (list) {
              final filtered = list.where((item) {
                final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
                return date.year == _selectedDate.year && 
                       date.month == _selectedDate.month && 
                       date.day == _selectedDate.day;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded, size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text('Kosong', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Tidak ada riwayat di tanggal ini.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ).animate().fadeIn().slideY(begin: 0.1),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return _ReportItemCard(report: filtered[index], index: index, isHistory: true);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showResolveDialog(BuildContext context, WidgetRef ref, String reportId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tindak Lanjuti Laporan'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Tulis balasan atau tindak lanjut admin di sini...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(reportControllerProvider.notifier)
                  .resolveReport(reportId, ctrl.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Kirim & Tutup Tiket'),
          ),
        ],
      ),
    );
  }
}

class _ReportItemCard extends StatelessWidget {
  final Report report;
  final int index;
  final bool isHistory;
  final VoidCallback? onResolve;

  const _ReportItemCard({
    required this.report,
    required this.index,
    this.isHistory = false,
    this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(report.timestamp);
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(date);
    
    final statusColor = report.status == 'resolved' ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.card,
        border: Border.all(color: !isHistory ? AppColors.warningLight : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: isHistory ? (report.status == 'resolved' ? AppColors.successLight : AppColors.warningLight) : AppColors.warningLight,
                child: Icon(
                  isHistory ? (report.status == 'resolved' ? Icons.check_circle_rounded : Icons.warning_rounded) : Icons.warning_rounded,
                  color: isHistory ? (report.status == 'resolved' ? AppColors.success : AppColors.warning) : AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          report.userName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (isHistory)
                          Text(
                            report.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.sm,
            ),
            child: Text(
              report.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (isHistory && report.adminResponse != null && report.adminResponse!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.sm,
              ),
              child: Text(
                'Tanggapan: ${report.adminResponse}',
                style: const TextStyle(fontSize: 13, color: AppColors.primary),
              ),
            ),
          ],
          if (!isHistory && onResolve != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onResolve,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
                ),
                child: const Text('Tindak Lanjuti'),
              ),
            ),
          ],
        ],
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideY(begin: 0.1);
  }
}
