import 'package:firebase_database/firebase_database.dart';

import '../core/constants.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/attendance.dart';
import '../models/leave.dart';
import '../models/report.dart';

// ─────────────────────────────────────────────────────────
// REALTIME DATABASE TREE STRUCTURE
//
// /users/{uid}
//   name:         string
//   NIK:          string
//   role:         "admin" | "employee"
//   total_points: int
//
// /attendance/{pushId}
//   user_id:             string
//   timestamp:           int          ← ms since epoch
//   geo_point:
//     latitude:          double
//     longitude:         double
//   distance_from_office: double      ← meters
//   is_mock_location:    bool
//
// /settings/global
//   point_value:    int               ← default 35000
//   allowed_radius: double            ← default 50.0 meters
// ─────────────────────────────────────────────────────────

/// Handles all Firebase Realtime Database read/write operations.
class DatabaseService {
  DatabaseService(this._db);

  final FirebaseDatabase _db;

  // ── Convenient references ────────────────────────────────

  DatabaseReference get _usersRef => _db.ref(AppConstants.usersPath);
  DatabaseReference get _attendanceRef => _db.ref(AppConstants.attendancePath);
  DatabaseReference get _settingsRef => _db.ref(AppConstants.settingsGlobalPath);
  DatabaseReference get _reportsRef => _db.ref(AppConstants.reportsPath);
  DatabaseReference get _leavesRef => _db.ref(AppConstants.leavesPath);

  DatabaseReference _userRef(String uid) =>
      _db.ref('${AppConstants.usersPath}/$uid');

  // ── Settings operations ──────────────────────────────────

  /// Fetch settings once (with fallback defaults).
  Future<AppSettings> getSettings() async {
    final snap = await _settingsRef.get();
    return AppSettings.fromSnapshot(snap);
  }

  /// Real-time stream of global settings.
  Stream<AppSettings> streamSettings() {
    return _settingsRef.onValue.map((e) => AppSettings.fromSnapshot(e.snapshot));
  }

  /// Write default settings to /settings/global (called once during seeding).
  Future<void> initSettings(AppSettings settings) async {
    await _settingsRef.set(settings.toMap());
  }

  /// Update existing settings parameters.
  Future<void> updateSettings(AppSettings settings) async {
    await _settingsRef.update(settings.toMap());
  }

  // ── User operations ──────────────────────────────────────

  /// Fetch a user profile once by uid. Returns null if not found.
  Future<AppUser?> getUser(String uid) async {
    final snap = await _userRef(uid).get();
    if (!snap.exists || snap.value == null) return null;
    return AppUser.fromMap(uid, snap.value as Map<Object?, Object?>);
  }

  /// Real-time stream of a single user profile.
  Stream<AppUser?> streamUser(String uid) {
    return _userRef(uid).onValue.map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return null;
      return AppUser.fromMap(uid, snap.value as Map<Object?, Object?>);
    });
  }

  /// Real-time stream of all employees (role == 'employee'), sorted by name.
  Stream<List<AppUser>> streamAllEmployees() {
    return _usersRef
        .orderByChild('role')
        .equalTo(AppConstants.roleEmployee)
        .onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return <AppUser>[];

      final users = <AppUser>[];
      final data = snap.value as Map<Object?, Object?>;
      for (final entry in data.entries) {
        final uid = entry.key as String;
        final val = entry.value as Map<Object?, Object?>;
        users.add(AppUser.fromMap(uid, val));
      }
      users.sort((a, b) => a.name.compareTo(b.name));
      return users;
    });
  }

  /// Create or overwrite a user node at /users/{uid}.
  Future<void> setUser(AppUser user) async {
    await _userRef(user.uid).set(user.toMap());
  }

  /// Update user profile attributes.
  Future<void> updateUserProfile(String uid, {String? name, String? photoUrl}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['photo_url'] = photoUrl;
    if (updates.isNotEmpty) {
      await _userRef(uid).update(updates);
    }
  }

  /// Delete a user from /users/{uid} (Soft Delete).
  Future<void> deleteUser(String uid) async {
    await _userRef(uid).remove();
  }

  /// Atomically increment total_points by [delta] using a transaction.
  Future<void> incrementPoints(String uid, {int delta = 1}) async {
    await _userRef(uid).child('total_points').runTransaction((current) {
      final currentVal = (current as num?)?.toInt() ?? 0;
      return Transaction.success(currentVal + delta);
    });
  }

  // ── Attendance operations ────────────────────────────────

  /// Push a new attendance record to /attendance/{pushId} (flat list).
  Future<void> addAttendance(Attendance attendance) async {
    await _attendanceRef.push().set(attendance.toMap());
  }

  /// Delete an attendance record. Used when invalidating a spoofed check-in.
  Future<void> deleteAttendanceRecord(String recordId) async {
    await _attendanceRef.child(recordId).remove();
  }

  /// Real-time stream of attendance records for a specific user, newest first.
  ///
  /// Queries /attendance by user_id. Requires index on 'user_id' in RTDB rules:
  /// { "attendance": { ".indexOn": ["user_id", "timestamp"] } }
  Stream<List<Attendance>> streamAttendanceForUser(String uid) {
    return _attendanceRef
        .orderByChild('user_id')
        .equalTo(uid)
        .onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return <Attendance>[];

      final records = <Attendance>[];
      final data = snap.value as Map<Object?, Object?>;
      for (final key in data.keys) {
        final childSnap = snap.child(key as String);
        records.add(Attendance.fromSnapshot(childSnap));
      }
      // Newest first
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    });
  }

  /// Real-time stream of ALL attendance records (for admin recap).
  Stream<List<Attendance>> streamAllAttendance() {
    return _attendanceRef.onValue.map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return <Attendance>[];

      final records = <Attendance>[];
      final data = snap.value as Map<Object?, Object?>;
      for (final key in data.keys) {
        final childSnap = snap.child(key as String);
        records.add(Attendance.fromSnapshot(childSnap));
      }
      return records;
    });
  }

  /// Gets the attendance record for today if the user has already checked in.
  Future<Attendance?> getCheckInRecordToday(String uid) async {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay =
        DateTime(now.year, now.month, now.day, 23, 59, 59)
            .millisecondsSinceEpoch;

    final snap = await _attendanceRef
        .orderByChild('user_id')
        .equalTo(uid)
        .get();

    if (!snap.exists || snap.value == null) return null;

    final data = snap.value as Map<Object?, Object?>;
    for (final entry in data.entries) {
      final key = entry.key as String;
      final childSnap = snap.child(key);
      final record = Attendance.fromSnapshot(childSnap);
      
      final ts = record.timestamp.millisecondsSinceEpoch;
      if (!record.isMockLocation && ts >= startOfDay && ts <= endOfDay) {
        return record;
      }
    }
    return null;
  }

  /// Check if a user has already successfully checked in today.
  Future<bool> hasCheckedInToday(String uid) async {
    final record = await getCheckInRecordToday(uid);
    return record != null;
  }

  /// Processes checkout for today's active record.
  Future<void> processCheckout(String recordId) async {
    await _attendanceRef.child(recordId).update({
      'is_checkout': true,
      'check_out_timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ── Report operations ────────────────────────────────────

  /// Submit a new report / ticket from an employee.
  Future<void> submitReport(Report report) async {
    await _reportsRef.push().set(report.toMap());
  }

  /// Real-time stream of all pending reports.
  Stream<List<Report>> streamPendingReports() {
    return _reportsRef
        .orderByChild('status')
        .equalTo('pending')
        .onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return <Report>[];

      final records = <Report>[];
      final data = snap.value as Map<Object?, Object?>;
      for (final key in data.keys) {
        records.add(Report.fromSnapshot(key as String, snap.child(key as String).value as Map<dynamic, dynamic>));
      }
      // Oldest first for queuing
      records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return records;
    });
  }

  /// Real-time stream of all reports in history (for admin global history).
  Stream<List<Report>> streamAllReports() {
    return _reportsRef.onValue.map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return <Report>[];

      final records = <Report>[];
      final data = snap.value as Map<Object?, Object?>;
      for (final key in data.keys) {
        records.add(Report.fromSnapshot(
            key as String, snap.child(key as String).value as Map<dynamic, dynamic>));
      }
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    });
  }

  /// Resolve a report with an admin response.
  Future<void> resolveReport(String reportId, String adminResponse) async {
    await _reportsRef.child(reportId).update({
      'status': 'resolved',
      'admin_response': adminResponse,
    });
  }

  /// Real-time stream of reports submitted by a specific user (for employee history).
  Stream<List<Report>> streamReportsForUser(String uid) {
    return _reportsRef
        .orderByChild('user_id')
        .equalTo(uid)
        .onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return <Report>[];

      final records = <Report>[];
      final data = snap.value as Map<Object?, Object?>;
      for (final key in data.keys) {
        records.add(Report.fromSnapshot(
            key as String, snap.child(key as String).value as Map<dynamic, dynamic>));
      }
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    });
  }


  // ── Leave operations ─────────────────────────────────────

  /// Submit a new leave request.
  Future<void> submitLeave(Leave leave) async {
    await _leavesRef.push().set(leave.toMap());
  }

  /// Real-time stream of pending leave requests for Admins.
  Stream<List<Leave>> streamPendingLeaves() {
    return _leavesRef
        .orderByChild('status')
        .equalTo('pending')
        .onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return <Leave>[];

      final records = <Leave>[];
      final data = snap.value as Map<Object?, Object?>;
      for (final key in data.keys) {
        records.add(Leave.fromSnapshot(key as String, snap.child(key as String).value as Map<dynamic, dynamic>));
      }
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    });
  }

  /// Real-time stream of all leave requests (for admin global history).
  Stream<List<Leave>> streamAllLeaves() {
    return _leavesRef.onValue.map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return <Leave>[];

      final records = <Leave>[];
      final data = snap.value as Map<Object?, Object?>;
      for (final key in data.keys) {
        records.add(Leave.fromSnapshot(key as String, snap.child(key as String).value as Map<dynamic, dynamic>));
      }
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    });
  }

  /// Get leave history for a specific employee.
  Stream<List<Leave>> streamLeavesForUser(String uid) {
    return _leavesRef
        .orderByChild('user_id')
        .equalTo(uid)
        .onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return <Leave>[];

      final records = <Leave>[];
      final data = snap.value as Map<Object?, Object?>;
      for (final key in data.keys) {
        records.add(Leave.fromSnapshot(key as String, snap.child(key as String).value as Map<dynamic, dynamic>));
      }
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    });
  }

  /// Resolve leave request.
  Future<void> resolveLeave(String leaveId, String status) async {
    await _leavesRef.child(leaveId).update({'status': status});
  }
}


