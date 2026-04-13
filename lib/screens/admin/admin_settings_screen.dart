import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _pointValueCtrl = TextEditingController();
  double _radius = 50.0;
  bool _initialized = false;

  @override
  void dispose() {
    _pointValueCtrl.dispose();
    super.dispose();
  }

  void _initFields(AppSettings settings) {
    if (!_initialized) {
      _pointValueCtrl.text = settings.pointValue.toString();
      _radius = settings.allowedRadius;
      _initialized = true;
    }
  }

  Future<void> _saveSettings() async {
    final pv = int.tryParse(_pointValueCtrl.text.trim()) ?? AppConstants.defaultPointValue;
    
    final newSettings = AppSettings(
      pointValue: pv,
      allowedRadius: _radius,
    );

    await ref.read(settingsControllerProvider.notifier).updateSettings(newSettings);

    if (!mounted) return;
    final state = ref.read(settingsControllerProvider);

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: ${state.error}'), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan berhasil disimpan!'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final ctrlState = ref.watch(settingsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan Sistem'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (settings) {
            _initFields(settings);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Konfigurasi Jarak & Upah',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ).animate().fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 8),
                  Text(
                    'Perubahan ini akan langsung berlaku untuk semua karyawan tanpa perlu update aplikasi.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ).animate(delay: 50.ms).fadeIn().slideY(begin: 0.1),
                  
                  const SizedBox(height: 40),

                  // ── Radius Geofence ──────────────────────────────────────
                  Text(
                    'Batas Radius Absensi (Meter)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ).animate(delay: 100.ms).fadeIn(),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.md,
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ketat\n(10m)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                            Text('${_radius.toInt()} Meter', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            const Text('Longgar\n(200m)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                          ],
                        ),
                        Slider(
                          value: _radius,
                          min: 10,
                          max: 200,
                          divisions: 19,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _radius = v),
                        ),
                      ],
                    ),
                  ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // ── Nilai Poin ───────────────────────────────────────────
                  Text(
                    'Konversi Nilai 1 Poin (Rp)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ).animate(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.md,
                      boxShadow: AppShadows.card,
                    ),
                    child: TextField(
                      controller: _pointValueCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        border: InputBorder.none,
                      ),
                    ),
                  ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: ctrlState.isLoading ? null : _saveSettings,
                      icon: ctrlState.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: const Text('Simpan Pengaturan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
                        elevation: 0,
                      ),
                    ),
                  ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
