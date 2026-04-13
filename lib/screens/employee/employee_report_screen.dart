import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/report_provider.dart';

class EmployeeReportScreen extends ConsumerStatefulWidget {
  const EmployeeReportScreen({super.key});

  @override
  ConsumerState<EmployeeReportScreen> createState() =>
      _EmployeeReportScreenState();
}

class _EmployeeReportScreenState extends ConsumerState<EmployeeReportScreen> {
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
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
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lapor Kendala'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                'Tuliskan detail masalah Anda (misal: "Lokasi tidak terdeteksi padahal sudah di kampus 1", atau "Fake GPS terdeteksi padahal tidak pakai"). Admin akan melakukan review.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ).animate(delay: 50.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 32),
              TextField(
                controller: _msgCtrl,
                maxLines: 5,
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
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ).animate(delay: 100.ms).fadeIn().scale(
                    begin: const Offset(0.95, 0.95),
                    duration: 300.ms,
                  ),
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Kirim Laporan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
                    elevation: 0,
                  ),
                ),
              ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
