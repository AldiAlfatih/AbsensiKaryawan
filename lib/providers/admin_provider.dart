import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/attendance.dart';
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
