import 'package:firebase_database/firebase_database.dart';

import '../core/constants.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/attendance.dart';

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

  /// Check if a user has already successfully checked in today.
  /// Fetches records by user_id and filters by today's date client-side.
  Future<bool> hasCheckedInToday(String uid) async {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay =
        DateTime(now.year, now.month, now.day, 23, 59, 59)
            .millisecondsSinceEpoch;

    // Query by user_id, then filter timestamp client-side
    final snap = await _attendanceRef
        .orderByChild('user_id')
        .equalTo(uid)
        .get();

    if (!snap.exists || snap.value == null) return false;

    final data = snap.value as Map<Object?, Object?>;
    for (final entry in data.values) {
      final record = Map<String, dynamic>.from(entry as Map);
      final ts = (record['timestamp'] as num?)?.toInt() ?? 0;
      final isMock = record['is_mock_location'] as bool? ?? false;
      // Count only non-mock records within today's window
      if (!isMock && ts >= startOfDay && ts <= endOfDay) {
        return true;
      }
    }
    return false;
  }
}
