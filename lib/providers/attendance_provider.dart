import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance.dart';
import '../models/app_settings.dart';
import '../services/location_service.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';

// ── Location service provider ────────────────────────────

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// ── Today's check-in status ──────────────────────────────

/// Fetches today's full check-in record.
final todayCheckInRecordProvider = FutureProvider<Attendance?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;

  return ref
      .watch(databaseServiceProvider)
      .getCheckInRecordToday(user.uid);
});

/// Whether the current user has already checked in today (successful, non-mock).
final hasCheckedInTodayProvider = FutureProvider<bool>((ref) async {
  final record = await ref.watch(todayCheckInRecordProvider.future);
  return record != null;
});

// ── Attendance history for current user ──────────────────

/// Real-time stream of the current user's attendance history.
final myAttendanceProvider = StreamProvider<List<Attendance>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value([]);

  return ref
      .watch(databaseServiceProvider)
      .streamAttendanceForUser(user.uid);
});

// ── Check-in action ──────────────────────────────────────

sealed class CheckInState {
  const CheckInState();
}

class CheckInIdle extends CheckInState {
  const CheckInIdle();
}

class CheckInLoading extends CheckInState {
  const CheckInLoading();
}

class CheckInSuccess extends CheckInState {
  const CheckInSuccess();
}

class CheckInError extends CheckInState {
  final String message;
  final CheckInErrorType type;
  const CheckInError(this.message, this.type);
}

enum CheckInErrorType {
  permissionDenied,
  permissionPermanentlyDenied,
  locationServiceDisabled,
  mockGps,
  outsideGeofence,
  alreadyCheckedIn,
  unknown,
}

class CheckInNotifier extends StateNotifier<CheckInState> {
  CheckInNotifier(this._ref) : super(const CheckInIdle());

  final Ref _ref;

  Future<void> checkIn() async {
    if (state is CheckInLoading) return;
    state = const CheckInLoading();

    final dbService = _ref.read(databaseServiceProvider);
    final locationService = _ref.read(locationServiceProvider);
    final user = _ref.read(authStateProvider).valueOrNull;

    if (user == null) {
      state = const CheckInError(
        'Sesi tidak valid. Silakan login ulang.',
        CheckInErrorType.unknown,
      );
      return;
    }

    // Read allowed_radius from settings/global (fallback to default if unavailable)
    final settings = _ref.read(settingsProvider).valueOrNull ??
        const AppSettings();

    // Already checked in today?
    final alreadyIn = await dbService.hasCheckedInToday(user.uid);
    if (alreadyIn) {
      state = const CheckInError(
        'Kamu sudah absen hari ini!',
        CheckInErrorType.alreadyCheckedIn,
      );
      return;
    }

    // Run the location validation with the DB-configured radius
    final result = await locationService.validateCheckIn(
      allowedRadiusMeters: settings.allowedRadius,
    );

    switch (result) {
      case LocationSuccess(:final position, :final distanceMeters, :final campusId):
        final now = DateTime.now();
        final isLate = now.hour > 8 || (now.hour == 8 && now.minute > 30); // Late after 08:30

        await dbService.addAttendance(Attendance(
          id: '',
          userId: user.uid,
          timestamp: now,
          latitude: position.latitude,
          longitude: position.longitude,
          distanceFromOffice: distanceMeters,
          isMockLocation: false,
          campusId: campusId,
          isLate: isLate,
          isCheckout: false, // Initial check-in is not a checkout
        ));
        
        // If late, maybe we don't give points, or give 0 points? 
        // For now, let's keep giving 1 point but Admin can review `isLate` flag.
        await dbService.incrementPoints(user.uid);
        _ref.invalidate(hasCheckedInTodayProvider);
        _ref.invalidate(currentUserProfileProvider);
        state = const CheckInSuccess();

      case LocationFailure(:final message, :final status):
        state = CheckInError(message, _mapPermStatus(status));

      case MockDetected():
        state = const CheckInError(
          'Terdeteksi GPS palsu! Absensi tidak dapat diproses.',
          CheckInErrorType.mockGps,
        );

      case OutsideGeofence(:final distanceMeters):
        final dist = distanceMeters.toStringAsFixed(0);
        final radius = settings.allowedRadius.toStringAsFixed(0);
        state = CheckInError(
          'Kamu berada $dist meter dari kantor. Batas: $radius meter.',
          CheckInErrorType.outsideGeofence,
        );
    }
  }

  Future<void> checkOut(String recordId) async {
    if (state is CheckInLoading) return;
    state = const CheckInLoading();

    final dbService = _ref.read(databaseServiceProvider);
    
    try {
      await dbService.processCheckout(recordId);
      _ref.invalidate(todayCheckInRecordProvider);
      _ref.invalidate(hasCheckedInTodayProvider);
      _ref.invalidate(currentUserProfileProvider);
      state = const CheckInSuccess();
    } catch (e) {
      state = CheckInError('Gagal melakukan Check-Out: $e', CheckInErrorType.unknown);
    }
  }

  void reset() => state = const CheckInIdle();

  static CheckInErrorType _mapPermStatus(LocationPermissionStatus s) {
    switch (s) {
      case LocationPermissionStatus.denied:
        return CheckInErrorType.permissionDenied;
      case LocationPermissionStatus.permanentlyDenied:
        return CheckInErrorType.permissionPermanentlyDenied;
      case LocationPermissionStatus.serviceDisabled:
        return CheckInErrorType.locationServiceDisabled;
      case LocationPermissionStatus.granted:
        return CheckInErrorType.unknown;
    }
  }
}

final checkInProvider =
    StateNotifierProvider<CheckInNotifier, CheckInState>((ref) {
  return CheckInNotifier(ref);
});
