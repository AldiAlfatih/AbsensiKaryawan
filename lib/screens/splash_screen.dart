import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../core/router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

/// Splash screen shown while Firebase resolves the auth state.
/// Automatically navigates to the correct route.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Give the logo animation time to play before navigating
    Future.delayed(const Duration(milliseconds: 1800), _resolveRoute);
  }

  Future<void> _resolveRoute() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      context.go(AppRoutes.login);
      return;
    }

    // Fetch role to decide where to navigate
    final profile = await ref
        .read(databaseServiceProvider)
        .getUser(user.uid);

    if (!mounted) return;

    if (profile == null) {
      context.go(AppRoutes.login);
    } else if (profile.isAdmin) {
      context.go(AppRoutes.adminDashboard);
    } else {
      context.go(AppRoutes.employeeDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo container
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: AppRadius.xl,
              ),
              child: ClipRRect(
                borderRadius: AppRadius.xl,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),

            Text(
              'Geo Attendance Positioning System',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
            )
                .animate(delay: 350.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 64),

            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.6)),
              ),
            ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
