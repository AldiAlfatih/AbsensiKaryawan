import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/attendance.dart';
import '../models/leave.dart';
import '../models/report.dart';
import 'auth_provider.dart';

// ── All employees stream ──────────────────────────────────

final allEmployeesProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(databaseServiceProvider).streamAllEmployees();
});

// ── Selected employee for detail view ────────────────────

final selectedEmployeeUidProvider = StateProvider<String?>((ref) => null);

final selectedEmployeeProfileProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(selectedEmployeeUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(databaseServiceProvider).streamUser(uid);
});

final selectedEmployeeAttendanceProvider =
    StreamProvider<List<Attendance>>((ref) {
  final uid = ref.watch(selectedEmployeeUidProvider);
  if (uid == null) return Stream.value([]);
  return ref
      .watch(databaseServiceProvider)
      .streamAttendanceForUser(uid);
});

// ── Global History Providers ──────────────────────────────

final allReportsProvider = StreamProvider<List<Report>>((ref) {
  return ref.watch(databaseServiceProvider).streamAllReports();
});

final allLeavesProvider = StreamProvider<List<Leave>>((ref) {
  return ref.watch(databaseServiceProvider).streamAllLeaves();
});

// ── Selected Employee History Providers ──────────────────

final selectedEmployeeReportsProvider = StreamProvider<List<Report>>((ref) {
  final uid = ref.watch(selectedEmployeeUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(databaseServiceProvider).streamReportsForUser(uid);
});

final selectedEmployeeLeavesProvider = StreamProvider<List<Leave>>((ref) {
  final uid = ref.watch(selectedEmployeeUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(databaseServiceProvider).streamLeavesForUser(uid);
});
