import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../core/router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _seedLoading = false;
  String? _seedMessage;

  @override
  void dispose() {
    _nikCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final profile = await ref.read(authNotifierProvider.notifier).signIn(
          nik: _nikCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;
    if (profile == null) return; // error handled via authNotifierProvider state

    if (profile.isAdmin) {
      context.go(AppRoutes.adminDashboard);
    } else {
      context.go(AppRoutes.employeeDashboard);
    }
  }

  Future<void> _seedAccounts() async {
    setState(() {
      _seedLoading = true;
      _seedMessage = null;
    });
    await ref.read(authNotifierProvider.notifier).seedDemoAccounts();
    if (!mounted) return;
    setState(() {
      _seedLoading = false;
      _seedMessage =
          'Akun demo berhasil dibuat!\n'
          'Admin  → NIK: ADM001 / password123\n'
          'Karyawan → NIK: EMP001 / password123';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final errorMsg = authState.hasError ? authState.error.toString() : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ── Logo & Header ───────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4361EE), Color(0xFF7B5EFB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: AppRadius.lg,
                          boxShadow: AppShadows.button,
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                      ).animate().scale(
                            begin: const Offset(0.8, 0.8),
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 20),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
                      const SizedBox(height: 6),
                      Text(
                        'Masuk dengan NIK dan password Anda',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                        textAlign: TextAlign.center,
                      ).animate(delay: 150.ms).fadeIn(),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // ── NIK field ───────────────────────────────────────
                Text('NIK (Nomor Induk Karyawan)',
                        style: Theme.of(context).textTheme.titleMedium)
                    .animate(delay: 200.ms)
                    .fadeIn()
                    .slideX(begin: -0.1),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nikCtrl,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: EMP001',
                    prefixIcon: Icon(Icons.badge_outlined,
                        color: AppColors.textSecondary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'NIK wajib diisi';
                    }
                    if (v.trim().length < 3) {
                      return 'NIK minimal 3 karakter';
                    }
                    return null;
                  },
                ).animate(delay: 220.ms).fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 20),

                // ── Password field ──────────────────────────────────
                Text('Password',
                        style: Theme.of(context).textTheme.titleMedium)
                    .animate(delay: 260.ms)
                    .fadeIn()
                    .slideX(begin: -0.1),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ).animate(delay: 280.ms).fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 12),

                // ── Error message ───────────────────────────────────
                if (errorMsg != null)
                  _ErrorCard(message: errorMsg)
                      .animate()
                      .fadeIn()
                      .slideY(begin: -0.2),

                const SizedBox(height: 28),

                // ── Login button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.sm),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ).animate(delay: 320.ms).fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // ── Dev seed helper ─────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Mode Pengembang',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textHint,
                                ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _seedLoading ? null : _seedAccounts,
                        icon: _seedLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textSecondary),
                              )
                            : const Icon(Icons.auto_fix_high_rounded,
                                size: 18),
                        label: const Text('Buat Akun Demo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.sm),
                        ),
                      ),
                      if (_seedMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: AppRadius.xs,
                          ),
                          child: Text(
                            _seedMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.success),
                          ),
                        ).animate().fadeIn(),
                      ],
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: AppRadius.xs,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
