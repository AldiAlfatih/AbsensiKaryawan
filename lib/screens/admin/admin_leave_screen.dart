import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/leave_provider.dart';
import '../../models/leave.dart';

class AdminLeaveScreen extends ConsumerStatefulWidget {
  const AdminLeaveScreen({super.key});

  @override
  ConsumerState<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends ConsumerState<AdminLeaveScreen> {
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
          title: const Text('Validasi Cuti & Izin'),
          backgroundColor: AppColors.surface,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Butuh Validasi'),
              Tab(text: 'Riwayat Semua'),
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
    final leaveAsync = ref.watch(pendingLeavesProvider);

    return leaveAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (leaves) {
        if (leaves.isEmpty) {
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
                  'Tidak ada pengajuan izin tertunda.',
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
          itemCount: leaves.length,
          itemBuilder: (context, index) {
            final leave = leaves[index];
            return _LeaveItemCard(
              leave: leave,
              index: index,
              onApprove: () => _resolveLeave(context, ref, leave.id, 'approved'),
              onReject: () => _resolveLeave(context, ref, leave.id, 'rejected'),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(WidgetRef ref) {
    final historyAsync = ref.watch(allLeavesProvider);
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
                  return _LeaveItemCard(leave: filtered[index], index: index, isHistory: true);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _resolveLeave(BuildContext context, WidgetRef ref, String leaveId, String status) {
    ref.read(leaveControllerProvider.notifier).resolveLeave(leaveId, status);
  }
}

class _LeaveItemCard extends StatelessWidget {
  final Leave leave;
  final int index;
  final bool isHistory;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _LeaveItemCard({
    required this.leave,
    required this.index,
    this.isHistory = false,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(leave.startDate));
    final endStr = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(leave.endDate));

    final statusColor = leave.status == 'approved'
        ? AppColors.success
        : leave.status == 'rejected'
            ? AppColors.error
            : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.card,
        border: Border.all(color: !isHistory ? AppColors.primaryLight : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHistory ? (leave.status == 'approved' ? AppColors.successLight : (leave.status == 'rejected' ? AppColors.errorLight : AppColors.primaryLight)) : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.event_note_rounded, color: isHistory ? statusColor : AppColors.primary),
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
                          leave.userName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (isHistory)
                          Text(
                            leave.status.toUpperCase(),
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
                      'Tipe: ${leave.type}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      startStr == endStr ? startStr : '$startStr - $endStr',
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
              leave.reason,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (!isHistory && onApprove != null && onReject != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
                    ),
                    child: const Text('Setujui'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideY(begin: 0.1);
  }
}
