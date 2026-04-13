import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/leave.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

part 'leave_provider.g.dart';

// Stream pending leaves for Admins
@riverpod
Stream<List<Leave>> pendingLeaves(Ref ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamPendingLeaves();
}

// Stream my leaves for Employee log
@riverpod
Stream<List<Leave>> myLeaves(Ref ref) {
  final authState = ref.watch(authStateProvider);
  final db = ref.watch(databaseServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return db.streamLeavesForUser(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
}

@riverpod
class LeaveController extends _$LeaveController {
  @override
  FutureOr<void> build() {}

  Future<void> submitLeave(Leave leave) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseServiceProvider);
      await db.submitLeave(leave);
    });
  }

  Future<void> resolveLeave(String leaveId, String status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseServiceProvider);
      await db.resolveLeave(leaveId, status);
    });
  }
}
