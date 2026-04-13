import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/leave_provider.dart';

class AdminLeaveScreen extends ConsumerWidget {
  const AdminLeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaveAsync = ref.watch(pendingLeavesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Validasi Cuti & Izin'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: leaveAsync.when(
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
                final startStr = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(leave.startDate));
                final endStr = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(leave.endDate));

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.md,
                    boxShadow: AppShadows.card,
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.event_note_rounded, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  leave.userName,
                                  style: Theme.of(context).textTheme.titleMedium,
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _resolveLeave(context, ref, leave.id, 'rejected'),
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
                              onPressed: () => _resolveLeave(context, ref, leave.id, 'approved'),
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
                  ),
                ).animate(delay: (index * 100).ms).fadeIn().slideY(begin: 0.1);
              },
            );
          },
        ),
      ),
    );
  }

  void _resolveLeave(BuildContext context, WidgetRef ref, String leaveId, String status) {
    ref.read(leaveControllerProvider.notifier).resolveLeave(leaveId, status);
  }
}
