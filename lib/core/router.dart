
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/employee/employee_dashboard.dart';
import '../screens/employee/employee_history.dart';
import '../screens/employee/employee_report_screen.dart';
import '../screens/employee/employee_leave_screen.dart';
import '../screens/employee/employee_leaderboard.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_employee_detail.dart';
import '../screens/admin/admin_create_employee.dart';

// ── Route paths ──────────────────────────────────────────

class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String login = '/login';
  static const String employeeDashboard = '/employee';
  static const String employeeHistory = '/employee/history';
  static const String employeeReport = '/employee/report';
  static const String employeeLeave = '/employee/leave';
  static const String employeeLeaderboard = '/employee/leaderboard';
  static const String adminDashboard = '/admin';
  static const String adminEmployeeDetail = '/admin/employee/:uid';
  static const String adminCreateEmployee = '/admin/create';

  static String adminEmployeeDetailPath(String uid) =>
      '/admin/employee/$uid';
}

// ── Router provider ──────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.employeeDashboard,
        builder: (context, state) => const EmployeeDashboard(),
      ),
      GoRoute(
        path: AppRoutes.employeeHistory,
        builder: (context, state) => const EmployeeHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.employeeReport,
        builder: (context, state) => const EmployeeReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.employeeLeave,
        builder: (context, state) => const EmployeeLeaveScreen(),
      ),
      GoRoute(
        path: AppRoutes.employeeLeaderboard,
        builder: (context, state) => const EmployeeLeaderboard(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: AppRoutes.adminEmployeeDetail,
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return AdminEmployeeDetailScreen(uid: uid);
        },
      ),
      GoRoute(
        path: AppRoutes.adminCreateEmployee,
        builder: (context, state) => const AdminCreateEmployeeScreen(),
      ),
    ],
    // Auth redirect guard
    redirect: (context, routerState) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isSplash = routerState.matchedLocation == AppRoutes.splash;
      final isLogin = routerState.matchedLocation == AppRoutes.login;

      // Still loading auth — stay on splash
      if (authState.isLoading) return null;

      // Not logged in → go to login (but not from splash before it resolves)
      if (!isLoggedIn && !isLogin && !isSplash) return AppRoutes.login;

      return null;
    },
  );
});
