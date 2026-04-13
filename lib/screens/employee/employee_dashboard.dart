import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class EmployeeDashboard extends ConsumerWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) => _EmployeeDashboardView(profile: profile),
    );
  }
}

class _EmployeeDashboardView extends ConsumerWidget {
  final AppUser? profile;
  const _EmployeeDashboardView({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInState = ref.watch(checkInProvider);
    final todayRecord = ref.watch(todayCheckInRecordProvider).valueOrNull;
    final alreadyIn = todayRecord != null;
    final points = profile?.totalPoints ?? 0;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final name = profile?.name ?? 'Karyawan';
    final now = DateTime.now();
    final greet = _greeting(now.hour);
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(hasCheckedInTodayProvider);
              ref.invalidate(currentUserProfileProvider);
            },
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── App bar ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(greet,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                            ],
                          ).animate().fadeIn(duration: 400.ms),
                        ),
                        _AvatarButton(
                          name: name,
                          onTap: () => _showMenu(context, ref),
                        ).animate(delay: 100.ms).fadeIn(),
                      ],
                    ),
                  ),
                ),

                // ── Date chip ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: AppRadius.full,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(dateStr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ).animate(delay: 150.ms).fadeIn(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ── Points card ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _PointsCard(
                      points: points,
                      pointValue: settings?.pointValue ?? AppConstants.defaultPointValue,
                    )
                        .animate(delay: 200.ms)
                        .fadeIn()
                        .slideY(begin: 0.15),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Check-in section ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Absensi Hari Ini',
                                style:
                                    Theme.of(context).textTheme.titleLarge)
                            .animate(delay: 260.ms)
                            .fadeIn(),
                        const SizedBox(height: 16),
                        _CheckInCard(
                          checkInState: checkInState,
                          alreadyIn: alreadyIn,
                          todayRecord: todayRecord,
                          onCheckIn: () =>
                              ref.read(checkInProvider.notifier).checkIn(),
                          onCheckOut: (recordId) =>
                              ref.read(checkInProvider.notifier).checkOut(recordId),
                          onReset: () =>
                              ref.read(checkInProvider.notifier).reset(),
                        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Quick actions ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _QuickActions(
                      onHistory: () =>
                          context.push(AppRoutes.employeeHistory),
                    ).animate(delay: 360.ms).fadeIn().slideY(begin: 0.1),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 11) return 'Selamat Pagi 🌤';
    if (hour < 15) return 'Selamat Siang ☀️';
    if (hour < 18) return 'Selamat Sore 🌇';
    return 'Selamat Malam 🌙';
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(
        profile: profile,
        onLogout: () async {
          Navigator.pop(context);
          await ref.read(authNotifierProvider.notifier).signOut();
          if (context.mounted) context.go(AppRoutes.login);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// CHECK-IN CARD — the centerpiece of the employee dashboard
// ─────────────────────────────────────────────────────────

class _CheckInCard extends StatelessWidget {
  final CheckInState checkInState;
  final bool alreadyIn;
  final Attendance? todayRecord;
  final VoidCallback onCheckIn;
  final void Function(String) onCheckOut;
  final VoidCallback onReset;

  const _CheckInCard({
    required this.checkInState,
    required this.alreadyIn,
    this.todayRecord,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          // Status indicator ring
          _StatusRing(
            checkInState: checkInState,
            alreadyIn: alreadyIn,
          ),
          const SizedBox(height: 20),

          // Status message
          _StatusMessage(
            checkInState: checkInState,
            alreadyIn: alreadyIn,
            todayRecord: todayRecord,
          ),

          const SizedBox(height: 24),

          // Action button
          _ActionButton(
            checkInState: checkInState,
            alreadyIn: alreadyIn,
            todayRecord: todayRecord,
            onCheckIn: onCheckIn,
            onCheckOut: () {
              if (todayRecord != null) onCheckOut(todayRecord!.id);
            },
            onReset: onReset,
          ),

          // Permission action (opens settings)
          if (checkInState is CheckInError &&
              (checkInState as CheckInError).type ==
                  CheckInErrorType.permissionPermanentlyDenied) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings_rounded, size: 16),
              label: const Text('Buka Pengaturan'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusRing extends StatelessWidget {
  final CheckInState checkInState;
  final bool alreadyIn;

  const _StatusRing({required this.checkInState, required this.alreadyIn});

  @override
  Widget build(BuildContext context) {
    Color ringColor;
    IconData icon;
    Color iconColor;

    if (checkInState is CheckInLoading) {
      return const SizedBox(
        width: 80,
        height: 80,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppColors.primary,
        ),
      );
    } else if (checkInState is CheckInSuccess || alreadyIn) {
      ringColor = AppColors.successLight;
      icon = Icons.check_circle_rounded;
      iconColor = AppColors.success;
    } else if (checkInState is CheckInError) {
      final type = (checkInState as CheckInError).type;
      if (type == CheckInErrorType.mockGps) {
        ringColor = AppColors.warningLight;
        icon = Icons.gps_off_rounded;
        iconColor = AppColors.warning;
      } else if (type == CheckInErrorType.outsideGeofence) {
        ringColor = AppColors.warningLight;
        icon = Icons.location_off_rounded;
        iconColor = AppColors.warning;
      } else if (type == CheckInErrorType.alreadyCheckedIn) {
        ringColor = AppColors.successLight;
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.success;
      } else {
        ringColor = AppColors.errorLight;
        icon = Icons.error_outline_rounded;
        iconColor = AppColors.error;
      }
    } else {
      ringColor = AppColors.primaryLight;
      icon = Icons.fingerprint_rounded;
      iconColor = AppColors.primary;
    }

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: ringColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 44, color: iconColor),
    ).animate(key: ValueKey(checkInState.runtimeType)).scale(
          begin: const Offset(0.8, 0.8),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }
}

class _StatusMessage extends StatelessWidget {
  final CheckInState checkInState;
  final bool alreadyIn;
  final Attendance? todayRecord;

  const _StatusMessage({required this.checkInState, required this.alreadyIn, this.todayRecord});

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;

    if (checkInState is CheckInLoading) {
      title = 'Memverifikasi...';
      subtitle = 'Sedang memeriksa lokasi dan GPS Anda';
    } else if (checkInState is CheckInSuccess) {
      title = 'Absensi Berhasil! 🎉';
      subtitle = 'Poin +1 telah ditambahkan ke akun Anda';
    } else if (checkInState is CheckInError) {
      final err = checkInState as CheckInError;
      if (err.type == CheckInErrorType.alreadyCheckedIn) {
        title = 'Sudah Absen Hari Ini';
        subtitle = 'Kamu sudah melakukan absensi untuk hari ini';
      } else {
        title = _errorTitle(err.type);
        subtitle = err.message;
      }
    } else if (alreadyIn && todayRecord != null) {
      if (todayRecord!.isCheckout) {
        title = 'Kerja Bagus Hari Ini! 🎉';
        subtitle = 'Kamu sudah Check-Out. Sampai jumpa besok!';
      } else {
        title = 'Sudah Absen Masuk ✅';
        final lateText = todayRecord!.isLate ? ' (Terlambat)' : '';
        subtitle = 'Lokasi: ${todayRecord!.campusId}$lateText\nJangan lupa Check-Out saat pulang.';
      }
    } else {
      title = 'Siap Absen?';
      subtitle = 'Tekan tombol di bawah untuk memulai verifikasi lokasi';
    }

    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _errorTitle(CheckInErrorType type) {
    switch (type) {
      case CheckInErrorType.mockGps:
        return 'GPS Palsu Terdeteksi ⚠️';
      case CheckInErrorType.outsideGeofence:
        return 'Di Luar Area Kantor 📍';
      case CheckInErrorType.permissionDenied:
        return 'Izin Lokasi Diperlukan';
      case CheckInErrorType.permissionPermanentlyDenied:
        return 'Izin Diblokir';
      case CheckInErrorType.locationServiceDisabled:
        return 'GPS Tidak Aktif';
      default:
        return 'Terjadi Kesalahan';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final CheckInState checkInState;
  final bool alreadyIn;
  final Attendance? todayRecord;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final VoidCallback onReset;

  const _ActionButton({
    required this.checkInState,
    required this.alreadyIn,
    this.todayRecord,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isError = checkInState is CheckInError;
    final isSuccess = checkInState is CheckInSuccess;
    final isLoading = checkInState is CheckInLoading;
    final isAlreadyIn = alreadyIn ||
        (isError &&
            (checkInState as CheckInError).type ==
                CheckInErrorType.alreadyCheckedIn);

    if (isAlreadyIn || isSuccess) {
      if (todayRecord != null && !todayRecord!.isCheckout) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onCheckOut,
            icon: const Icon(Icons.directions_run_rounded, size: 22),
            label: const Text(
              'Check Out Pulang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
            ),
          ),
        );
      } else {
        return Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: AppRadius.sm,
          ),
          alignment: Alignment.center,
          child: Text(
            'Check-Out Selesai ✓',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.success,
                ),
          ),
        );
      }
    }

    if (isError) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.sm),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onCheckIn,
        icon: const Icon(Icons.fingerprint_rounded, size: 22),
        label: const Text(
          'Check In Sekarang',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// POINTS CARD
// ─────────────────────────────────────────────────────────

class _PointsCard extends StatelessWidget {
  final int points;
  final int pointValue;
  const _PointsCard({required this.points, required this.pointValue});

  @override
  Widget build(BuildContext context) {
    final rupiah = points * pointValue;
    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4361EE), Color(0xFF7B5EFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.button,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Poin',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$points Poin',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '≈ ${fmt.format(rupiah)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: AppRadius.md,
            ),
            child: const Icon(Icons.star_rounded,
                color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// QUICK ACTIONS
// ─────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final VoidCallback onHistory;
  const _QuickActions({required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Menu Cepat',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.history_rounded,
                label: 'Riwayat\nAbsen',
                color: AppColors.primary,
                bgColor: AppColors.primaryLight,
                onTap: onHistory,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ActionTile(
                icon: Icons.emoji_events_rounded,
                label: 'Papan\nPeringkat',
                color: Colors.amber.shade700,
                bgColor: Colors.amber.shade100,
                onTap: () => context.push(AppRoutes.employeeLeaderboard),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.support_agent_rounded,
                label: 'Lapor\nKendala',
                color: AppColors.warning,
                bgColor: AppColors.warningLight,
                onTap: () => context.push(AppRoutes.employeeReport),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ActionTile(
                icon: Icons.event_note_rounded,
                label: 'Cuti &\nIzin',
                color: AppColors.success,
                bgColor: AppColors.successLight,
                onTap: () => context.push(AppRoutes.employeeLeave),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// AVATAR BUTTON
// ─────────────────────────────────────────────────────────

class _AvatarButton extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _AvatarButton({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4361EE), Color(0xFF7B5EFB)],
          ),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// PROFILE BOTTOM SHEET
// ─────────────────────────────────────────────────────────

class _ProfileSheet extends StatelessWidget {
  final AppUser? profile;
  final VoidCallback onLogout;

  const _ProfileSheet({required this.profile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: AppRadius.full,
            ),
          ),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              profile?.name.isNotEmpty == true
                  ? profile!.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(profile?.name ?? '-',
              style: Theme.of(context).textTheme.headlineSmall),
          Text(profile?.email ?? '-',
              style: Theme.of(context).textTheme.bodySmall),
          if ((profile?.nik ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'NIK: ${profile!.nik}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          const SizedBox(height: 24),
          Divider(indent: 20, endIndent: 20, color: AppColors.divider),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Keluar',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
            onTap: onLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
