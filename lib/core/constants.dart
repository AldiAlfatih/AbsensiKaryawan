// ─────────────────────────────────────────────────────────
// APP CONSTANTS
// Edit OFFICE_LATITUDE & OFFICE_LONGITUDE to match your
// actual office location.
// ─────────────────────────────────────────────────────────

class AppConstants {
  AppConstants._();

  // ── Office Geofence ──────────────────────────────────────
  /// Latitude of the office (center of geofence).
  static const double officeLatitude = -6.200000;

  /// Longitude of the office (center of geofence).
  static const double officeLongitude = 106.816666;

  /// Fallback radius used if /settings/global is unavailable.
  /// The live value is read from the database (settings/global/allowed_radius).
  static const double defaultGeofenceRadius = 50.0;

  /// Fallback point value if /settings/global is unavailable.
  static const int defaultPointValue = 35000;

  // ── Realtime Database paths ──────────────────────────────
  static const String usersPath = 'users';
  static const String attendancePath = 'attendance';
  static const String settingsGlobalPath = 'settings/global';

  // ── Auth ─────────────────────────────────────────────────
  /// Email domain appended to NIK for Firebase Auth.
  /// Login email = "${nik}${emailDomain}"
  static const String emailDomain = '@absensi.com';

  // ── Roles ────────────────────────────────────────────────
  static const String roleAdmin = 'admin';
  static const String roleEmployee = 'employee';

  // ── App info ─────────────────────────────────────────────
  static const String appName = 'AbsensiKu';
  static const String appVersion = '1.0.0';
}
