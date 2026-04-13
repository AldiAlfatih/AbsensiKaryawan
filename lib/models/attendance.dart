import 'package:firebase_database/firebase_database.dart';

/// Represents a single attendance record stored at /attendance/{pushId}.
///
/// DB schema:
/// {
///   "user_id":             string,
///   "timestamp":           int (ms since epoch),
///   "geo_point": {
///     "latitude":          double,
///     "longitude":         double
///   },
///   "distance_from_office": double  (meters),
///   "is_mock_location":    bool
/// }
class Attendance {
  final String id;
  final String userId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double distanceFromOffice;
  final bool isMockLocation;
  final String campusId;
  final bool isLate;
  final bool isCheckout;
  final int? checkOutTimestamp;

  const Attendance({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.distanceFromOffice,
    this.isMockLocation = false,
    this.campusId = 'Unknown',
    this.isLate = false,
    this.isCheckout = false,
    this.checkOutTimestamp,
  });

  factory Attendance.fromSnapshot(DataSnapshot snap) {
    final raw = snap.value as Map;
    final data = Map<String, dynamic>.from(raw);
    final geoPoint = data['geo_point'] != null
        ? Map<String, dynamic>.from(data['geo_point'] as Map)
        : <String, dynamic>{};

    return Attendance(
      id: snap.key ?? '',
      userId: data['user_id'] as String? ?? '',
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['timestamp'] as num).toInt())
          : DateTime.now(),
      latitude: (geoPoint['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (geoPoint['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceFromOffice:
          (data['distance_from_office'] as num?)?.toDouble() ?? 0.0,
      isMockLocation: data['is_mock_location'] as bool? ?? false,
      campusId: data['campus_id'] as String? ?? 'Unknown',
      isLate: data['is_late'] as bool? ?? false,
      isCheckout: data['is_checkout'] as bool? ?? false,
      checkOutTimestamp: data['check_out_timestamp'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'geo_point': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'distance_from_office': distanceFromOffice,
        'is_mock_location': isMockLocation,
        'campus_id': campusId,
        'is_late': isLate,
        'is_checkout': isCheckout,
        if (checkOutTimestamp != null) 'check_out_timestamp': checkOutTimestamp,
      };
}
