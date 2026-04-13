import 'package:firebase_database/firebase_database.dart';

/// Global settings read from /settings/global in Realtime Database.
///
/// DB schema:
/// settings/global: {
///   "point_value":    int    (default 35000),
///   "allowed_radius": double (default 50.0 meters)
/// }
class AppSettings {
  final int pointValue;
  final double allowedRadius;

  const AppSettings({
    this.pointValue = 35000,
    this.allowedRadius = 50.0,
  });

  factory AppSettings.fromSnapshot(DataSnapshot snap) {
    if (!snap.exists || snap.value == null) {
      return const AppSettings();
    }
    final data = Map<String, dynamic>.from(snap.value as Map);
    return AppSettings(
      pointValue: (data['point_value'] as num?)?.toInt() ?? 35000,
      allowedRadius:
          (data['allowed_radius'] as num?)?.toDouble() ?? 50.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'point_value': pointValue,
        'allowed_radius': allowedRadius,
      };
}
