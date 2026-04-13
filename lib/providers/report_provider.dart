import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/report.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

part 'report_provider.g.dart';

/// Stream of all pending reports intended for admins.
@riverpod
Stream<List<Report>> pendingReports(PendingReportsRef ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamPendingReports();
}

/// Notifier to handle submitting and resolving reports.
@riverpod
class ReportController extends _$ReportController {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Employee submits a report.
  Future<void> submitReport(String message) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseServiceProvider);
      final user = ref.read(userProfileProvider).value;

      if (user == null) {
        throw Exception('User not logged in');
      }

      final report = Report(
        id: '', // Will be assigned by Firebase push()
        userId: user.uid,
        userName: user.name,
        message: message,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await db.submitReport(report);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Admin resolves a report.
  Future<void> resolveReport(String reportId, String adminResponse) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseServiceProvider);
      await db.resolveReport(reportId, adminResponse);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
