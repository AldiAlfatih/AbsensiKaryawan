import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

/// Admin screen to create a new employee account.
/// NIK is stored as-is; Firebase Auth email = NIK@gaps.com (hidden).
class AdminCreateEmployeeScreen extends ConsumerStatefulWidget {
  const AdminCreateEmployeeScreen({super.key});

  @override
  ConsumerState<AdminCreateEmployeeScreen> createState() =>
      _AdminCreateEmployeeScreenState();
}

class _AdminCreateEmployeeScreenState
    extends ConsumerState<AdminCreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _success = false;
  String? _createdNik;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nikCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final result = await ref
        .read(authNotifierProvider.notifier)
        .createEmployee(
          name: _nameCtrl.text.trim(),
          nik: _nikCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _success = true;
        _createdNik = result.nik;
      });
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _nikCtrl.clear();
    _passwordCtrl.clear();
    _confirmCtrl.clear();
    setState(() {
      _success = false;
      _createdNik = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final errorMsg = authState.hasError ? authState.error.toString() : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tambah Karyawan'),
        backgroundColor: AppColors.surface,
        leading: const BackButton(),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _success
            ? _SuccessView(nik: _createdNik!, onAddAnother: _reset)
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: AppRadius.md,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Email Firebase akan dibuat otomatis:\nNIK@gaps.com',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),

                    const SizedBox(height: 28),

                    // ── Full Name ─────────────────────────────────────────
                    _FieldLabel(label: 'Nama Lengkap'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Nama karyawan',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Nama wajib diisi';
                        if (v.trim().length < 3)
                          return 'Nama minimal 3 karakter';
                        return null;
                      },
                    ).animate(delay: 50.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // ── NIK ───────────────────────────────────────────────
                    _FieldLabel(label: 'NIK (Nomor Induk Karyawan)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nikCtrl,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: EMP002',
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'NIK wajib diisi';
                        if (v.trim().length < 3)
                          return 'NIK minimal 3 karakter';
                        if (v.contains(' '))
                          return 'NIK tidak boleh mengandung spasi';
                        return null;
                      },
                    ).animate(delay: 80.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // ── Password ──────────────────────────────────────────
                    _FieldLabel(label: 'Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePass,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'Min. 6 karakter',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Password wajib diisi';
                        if (v.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ).animate(delay: 110.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // ── Confirm Password ──────────────────────────────────
                    _FieldLabel(label: 'Konfirmasi Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _createAccount(),
                      decoration: InputDecoration(
                        hintText: 'Ulangi password',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Konfirmasi password wajib diisi';
                        if (v != _passwordCtrl.text)
                          return 'Password tidak cocok';
                        return null;
                      },
                    ).animate(delay: 140.ms).fadeIn(),

                    const SizedBox(height: 16),

                    // ── Error message ─────────────────────────────────────
                    if (errorMsg != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: AppRadius.xs,
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMsg,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2),

                    const SizedBox(height: 28),

                    // ── Submit button ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _createAccount,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.person_add_rounded, size: 20),
                        label: Text(
                          isLoading ? 'Membuat akun...' : 'Buat Akun Karyawan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.sm,
                          ),
                        ),
                      ),
                    ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.1),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Field label helper ──────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleMedium);
  }
}

// ── Success view ────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final String nik;
  final VoidCallback onAddAnother;

  const _SuccessView({required this.nik, required this.onAddAnother});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 48,
          ),
        ).animate().scale(
          begin: const Offset(0.5, 0.5),
          duration: 500.ms,
          curve: Curves.elasticOut,
        ),
        const SizedBox(height: 24),
        Text(
          'Akun Berhasil Dibuat!',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ).animate(delay: 150.ms).fadeIn(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: AppRadius.md,
          ),
          child: Column(
            children: [
              Text(
                'NIK Karyawan',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.success),
              ),
              const SizedBox(height: 4),
              Text(
                nik,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Kembali'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.sm,
                  ),
                  minimumSize: const Size(0, 52),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAddAnother,
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Tambah Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.sm,
                  ),
                  minimumSize: const Size(0, 52),
                ),
              ),
            ),
          ],
        ).animate(delay: 300.ms).fadeIn(),
      ],
    );
  }
}
