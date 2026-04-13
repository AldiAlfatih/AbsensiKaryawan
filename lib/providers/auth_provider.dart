import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

// ── Service providers ────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(FirebaseDatabase.instance);
});

// ── Auth state ───────────────────────────────────────────

/// Emits the Firebase [User] or null on auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── User profile (real-time stream) ─────────────────────

/// Streams the current user's [AppUser] profile from /users/{uid}.
final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(databaseServiceProvider).streamUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (e, _) => Stream.value(null),
  );
});

// ── NIK → email helper ───────────────────────────────────

/// Converts a NIK to a Firebase Auth email.
/// e.g. "EMP001" → "EMP001@gaps.com"
String nikToEmail(String nik) =>
    '${nik.trim().toUpperCase()}${AppConstants.emailDomain}';

// ── Sign-in notifier ─────────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._authService, this._dbService)
    : super(const AsyncValue.data(null));

  final AuthService _authService;
  final DatabaseService _dbService;

  // ── Login ────────────────────────────────────────────────

  /// Signs in using [nik] and [password].
  /// Firebase Auth email is constructed internally as [nik]@gaps.com.
  /// Returns the [AppUser] profile on success, null on failure.
  Future<AppUser?> signIn({
    required String nik,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _authService.signIn(
        email: nikToEmail(nik),
        password: password,
      );
      final profile = await _dbService.getUser(credential.user!.uid);
      state = const AsyncValue.data(null);
      return profile;
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(
        AuthService.friendlyError(e),
        StackTrace.current,
      );
      return null;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return null;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  // ── Admin: Create Employee ───────────────────────────────

  /// Creates a new employee Firebase Auth account and writes to /users/{uid}.
  /// Firebase email = [nik]@gaps.com — never shown to the end user.
  /// Returns the new [AppUser] on success, null on failure.
  Future<AppUser?> createEmployee({
    required String name,
    required String nik,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final email = nikToEmail(nik);
      final credential = await _authService.createAccount(
        email: email,
        password: password,
      );
      final user = AppUser(
        uid: credential.user!.uid,
        name: name.trim(),
        nik: nik.trim().toUpperCase(),
        email: email,
        role: AppConstants.roleEmployee,
        totalPoints: 0,
      );
      await _dbService.setUser(user);
      state = const AsyncValue.data(null);
      return user;
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(
        AuthService.friendlyError(e),
        StackTrace.current,
      );
      return null;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return null;
    }
  }

  // ── Dev seed ─────────────────────────────────────────────

  /// Seeds demo accounts and /settings/global defaults.
  /// Emails: ADM001@gaps.com / EMP001@gaps.com, password: password123
  Future<void> seedDemoAccounts() async {
    state = const AsyncValue.loading();
    try {
      // Admin (NIK: ADM001)
      await _seedAccount(
        nik: 'ADM001',
        name: 'Admin Utama',
        role: AppConstants.roleAdmin,
      );

      // Now that we have logged in as Admin during the _seedAccount step,
      // we have the 'auth != null' permission to write to settings/global.
      await _dbService.initSettings(
        AppSettings(
          pointValue: AppConstants.defaultPointValue,
          allowedRadius: AppConstants.defaultGeofenceRadius,
        ),
      );

      // Employee (NIK: EMP001)
      await _seedAccount(
        nik: 'EMP001',
        name: 'Budi Santoso',
        role: AppConstants.roleEmployee,
      );

      await _authService.signOut();
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(
        AuthService.friendlyError(e),
        StackTrace.current,
      );
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> _seedAccount({
    required String nik,
    required String name,
    required String role,
    String password = '12345678',
  }) async {
    final email = nikToEmail(nik);
    UserCredential cred;
    try {
      cred = await _authService.createAccount(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        cred = await _authService.signIn(email: email, password: password);
      } else {
        rethrow;
      }
    }
    await _dbService.setUser(
      AppUser(
        uid: cred.user!.uid,
        name: name,
        nik: nik,
        email: email,
        role: role,
        totalPoints: 0,
      ),
    );
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
      return AuthNotifier(
        ref.watch(authServiceProvider),
        ref.watch(databaseServiceProvider),
      );
    });
