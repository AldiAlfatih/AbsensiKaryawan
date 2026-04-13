import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/leave.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';

class EmployeeLeaveScreen extends ConsumerStatefulWidget {
  const EmployeeLeaveScreen({super.key});

  @override
  ConsumerState<EmployeeLeaveScreen> createState() => _EmployeeLeaveScreenState();
}

class _EmployeeLeaveScreenState extends ConsumerState<EmployeeLeaveScreen> {
  final _reasonCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _type = 'Sakit';

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDates(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 7)), // allow backdate 1 week
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  Future<void> _submitLeave() async {
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keterangan tidak boleh kosong!')),
      );
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final leave = Leave(
      id: '', // db generates
      userId: user.uid,
      userName: user.name,
      type: _type,
      reason: _reasonCtrl.text.trim(),
      startDate: _startDate.millisecondsSinceEpoch,
      endDate: _endDate.millisecondsSinceEpoch,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await ref.read(leaveControllerProvider.notifier).submitLeave(leave);

    if (!mounted) return;
    
    final state = ref.read(leaveControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${state.error}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan berhasil dikirim! Menunggu persetujuan Admin.')),
      );
      _reasonCtrl.clear();
      Navigator.pop(context); // Optional: close form after success
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrlState = ref.watch(leaveControllerProvider);
    final historyAsync = ref.watch(myLeavesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Izin & Cuti'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLeaveForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Pengajuan'),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy_rounded, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('Belum ada riwayat pengajuan cuti/izin.', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ).animate().fadeIn(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final leave = list[i];
              final startStr = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(leave.startDate));
              final endStr = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(leave.endDate));
              
              Color statusColor;
              IconData statusIcon;
              if (leave.status == 'approved') {
                statusColor = AppColors.success;
                statusIcon = Icons.check_circle_rounded;
              } else if (leave.status == 'rejected') {
                statusColor = AppColors.error;
                statusIcon = Icons.cancel_rounded;
              } else {
                statusColor = AppColors.warning;
                statusIcon = Icons.pending_actions_rounded;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.md,
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: AppRadius.sm,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(leave.type, style: Theme.of(context).textTheme.titleMedium),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.full,
                                ),
                                child: Text(
                                  leave.status.toUpperCase(),
                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            startStr == endStr ? startStr : '$startStr - $endStr',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            leave.reason,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(delay: (i*40).ms).fadeIn().slideY(begin: 0.1);
            },
          );
        },
      ),
    );
  }

  void _showLeaveForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final startStr = DateFormat('dd MMM yyyy').format(_startDate);
          final endStr = DateFormat('dd MMM yyyy').format(_endDate);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buat Pengajuan Baru', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  
                  // Tipe
                  Text('Tipe Pengajuan', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Sakit', label: Text('Sakit')),
                      ButtonSegment(value: 'Izin', label: Text('Izin')),
                      ButtonSegment(value: 'Cuti', label: Text('Cuti')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (val) => setModalState(() => _type = val.first),
                  ),
                  const SizedBox(height: 20),

                  // Tanggal
                  Text('Rentang Tanggal', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      await _selectDates(ctx);
                      setModalState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: AppRadius.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(startStr == endStr ? startStr : '$startStr  —  $endStr', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(Icons.date_range_rounded, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Alasan
                  Text('Keterangan / Alasan', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Tuliskan alasan lengkap dengan jelas...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _submitLeave();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('Kirim Pengajuan'),
                    ),
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
