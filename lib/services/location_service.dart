import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../core/constants.dart';

/// Result of a location permission/availability check.
enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

/// Result of an attempt to get the device location.
sealed class LocationResult {
  const LocationResult();
}

/// Location validated successfully — carries position + distance from office.
class LocationSuccess extends LocationResult {
  final Position position;
  final double distanceMeters;
  final String campusId;
  const LocationSuccess(this.position, this.distanceMeters, this.campusId);
}

class LocationFailure extends LocationResult {
  final String message;
  final LocationPermissionStatus status;
  const LocationFailure(this.message, this.status);
}

class MockDetected extends LocationResult {
  final Position position;
  const MockDetected(this.position);
}

class OutsideGeofence extends LocationResult {
  final Position position;
  final double distanceMeters;
  const OutsideGeofence(this.position, this.distanceMeters);
}

/// Provides location services: permission checks, mock detection, geofencing.
class LocationService {
  /// Request and check location permission via Geolocator.
  Future<LocationPermissionStatus> checkAndRequestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      return LocationPermissionStatus.permanentlyDenied;
    }
    if (perm == LocationPermission.denied) {
      return LocationPermissionStatus.denied;
    }
    return LocationPermissionStatus.granted;
  }

  /// Checks whether the device is using a mock/fake GPS location.
  ///
  /// On Android: uses [Position.isMocked].
  /// On iOS: always returns false (platform limitation).
  Future<bool> isMockLocation(Position position) async {
    return position.isMocked;
  }

  /// Gets the current device [Position] with high accuracy.
  Future<Position> getCurrentPosition() async {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// Full check-in validation pipeline:
  /// 1. Permission check
  /// 2. Get position
  /// 3. Mock location detection  → [MockDetected] (carries position)
  /// 4. Geofence check (Haversine) using [allowedRadiusMeters]
  ///    → [OutsideGeofence] (carries position + distance)
  ///    → [LocationSuccess] (carries position + distance)
  ///
  /// [allowedRadiusMeters] defaults to [AppConstants.defaultGeofenceRadius]
  /// but should be overridden with the value from [settings/global].
  Future<LocationResult> validateCheckIn({double? allowedRadiusMeters}) async {
    final radius = allowedRadiusMeters ?? AppConstants.defaultGeofenceRadius;

    // 1. Permission
    final permStatus = await checkAndRequestPermission();
    if (permStatus != LocationPermissionStatus.granted) {
      return LocationFailure(_permissionMessage(permStatus), permStatus);
    }

    // 2. Get position
    late Position position;
    try {
      position = await getCurrentPosition();
    } catch (e) {
      return LocationFailure(
        'Gagal mendapatkan lokasi: ${e.toString()}',
        LocationPermissionStatus.granted,
      );
    }

    // 3. Mock detection — return position so it can be logged if needed
    if (await isMockLocation(position)) {
      return MockDetected(position);
    }

    // 4. Geofence — cek 3 titik lokasi kantor
    // Hitung jarak ke Kampus 1
    final distanceToKampus1 = haversineDistance(
      lat1: position.latitude,
      lng1: position.longitude,
      lat2: AppConstants.kampus1Lat,
      lng2: AppConstants.kampus1Lng,
    );

    // Hitung jarak ke Kampus 2
    final distanceToKampus2 = haversineDistance(
      lat1: position.latitude,
      lng1: position.longitude,
      lat2: AppConstants.kampus2Lat,
      lng2: AppConstants.kampus2Lng,
    );

    // Hitung jarak ke Kantor 3 (BTN Rama Residence)
    final distanceToKantor3 = haversineDistance(
      lat1: position.latitude,
      lng1: position.longitude,
      lat2: AppConstants.kantor3Lat,
      lng2: AppConstants.kantor3Lng,
    );

    // Hitung jarak ke Kantor 4 (Rumah Mala)
    final distanceToKantor4 = haversineDistance(
      lat1: position.latitude,
      lng1: position.longitude,
      lat2: AppConstants.kantor4Lat,
      lng2: AppConstants.kantor4Lng,
    );

    // Hitung jarak ke Kantor 5 (Bank Indonesia Sulsel)
    final distanceToBISulsel = haversineDistance(
      lat1: position.latitude,
      lng1: position.longitude,
      lat2: AppConstants.biSulselLat,
      lng2: AppConstants.biSulselLng,
    );

    // Tentukan kantor terdekat dari pilihan
    final distances = {
      'Kampus 1': distanceToKampus1,
      'Kampus 2': distanceToKampus2,
      'Kantor 3 (BTN Rama Residence)': distanceToKantor3,
      'Kantor 4 (Rumah Mala)': distanceToKantor4,
      'Bank Indonesia (Sulsel)': distanceToBISulsel,
    };
    final closest = distances.entries.reduce(
      (a, b) => a.value < b.value ? a : b,
    );
    final distance = closest.value;
    final campusId = closest.key;

    if (distance > radius) {
      return OutsideGeofence(position, distance);
    }

    return LocationSuccess(position, distance, campusId);

  }

  /// Haversine formula — returns distance in meters between two lat/lng pairs.
  static double haversineDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  static String _permissionMessage(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.denied:
        return 'Izin lokasi ditolak. Harap izinkan akses lokasi.';
      case LocationPermissionStatus.permanentlyDenied:
        return 'Izin lokasi diblokir permanen. Buka pengaturan untuk mengaktifkan.';
      case LocationPermissionStatus.serviceDisabled:
        return 'GPS tidak aktif. Harap aktifkan layanan lokasi.';
      case LocationPermissionStatus.granted:
        return '';
    }
  }
}
