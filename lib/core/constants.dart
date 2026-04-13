// ─────────────────────────────────────────────────────────
// APP CONSTANTS
// Edit OFFICE_LATITUDE & OFFICE_LONGITUDE to match your
// actual office location.
// ─────────────────────────────────────────────────────────

class AppConstants {
  AppConstants._();

  /// Kampus 1: Jl. Balai Kota No. 1, Parepare
  static const double kampus1Lat = -4.0167;
  static const double kampus1Lng = 119.6236;

  /// Kampus 2: Jl. Pemuda No. 6, Parepare
  static const double kampus2Lat = -4.0264;
  static const double kampus2Lng = 119.6289;

  /// Fallback radius used if /settings/global is unavailable.
  /// The live value is read from the database (settings/global/allowed_radius).
  static const double defaultGeofenceRadius = 50.0;

  /// Fallback point value if /settings/global is unavailable.
  static const int defaultPointValue = 35000;

  // ── Realtime Database paths ──────────────────────────────
  static const String usersPath = 'users';
  static const String attendancePath = 'attendance';
  static const String settingsGlobalPath = 'settings/global';
  static const String reportsPath = 'reports';
  static const String leavesPath = 'leaves';

  // ── Auth ─────────────────────────────────────────────────
  /// Email domain appended to NIK for Firebase Auth.
  /// Login email = "${nik}${emailDomain}"
  static const String emailDomain = '@gaps.com';

  // ── Roles ────────────────────────────────────────────────
  static const String roleAdmin = 'admin';
  static const String roleEmployee = 'employee';

  // ── App info ─────────────────────────────────────────────
  static const String appName = 'GAPS';
  static const String appVersion = '1.0.0';
}
