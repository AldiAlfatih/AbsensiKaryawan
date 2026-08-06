import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  // Explicitly specify the database URL because google-services.json was
  // generated before the Realtime Database was created, so it doesn't
  // contain the firebase_url field. This ensures the correct database is used.
  return DatabaseService(FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://absensikaryawan-3a199-default-rtdb.asia-southeast1.firebasedatabase.app',
  ));
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

      // BUG FIX: If profile doesn't exist in the DB (e.g. admin deleted the
      // employee record), sign out immediately to prevent the user from being
      // stuck in a broken auth-but-no-profile loop.
      if (profile == null) {
        await _authService.signOut();
        state = AsyncValue.error(
          'Akun tidak ditemukan. Hubungi Admin.',
          StackTrace.current,
        );
        return null;
      }

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
    FirebaseApp? secondaryApp;
    try {
      final email = nikToEmail(nik);

      // BUG FIX: createUserWithEmailAndPassword() automatically signs OUT the
      // current user (admin) and signs IN as the newly created account.
      // To prevent this, we create the account on an isolated secondary
      // Firebase App instance — the main app's auth session is untouched.
      secondaryApp = await Firebase.initializeApp(
        name: 'create_emp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
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
    } finally {
      // Always clean up the secondary Firebase App.
      await secondaryApp?.delete();
    }
  }

  // ── Dev seed ─────────────────────────────────────────────

  /// Seeds demo accounts and /settings/global defaults.
  /// Emails: ADM001@gaps.com / EMP001@gaps.com, password: password123
  Future<void> seedDemoAccounts() async {
    state = const AsyncValue.loading();
    try {
      // Step 1: Create Admin account (auto signs-in as ADM001)
      await _seedAccount(
        nik: 'ADM001',
        name: 'Admin Utama',
        role: AppConstants.roleAdmin,
      );

      // Step 2: Write global settings while still signed in as ADM001
      await _dbService.initSettings(
        AppSettings(
          pointValue: AppConstants.defaultPointValue,
          allowedRadius: AppConstants.defaultGeofenceRadius,
        ),
      );

      // Step 3: Sign out so the router doesn't redirect to admin dashboard
      // while we're still seeding the second account.
      await _authService.signOut();

      // Step 4: Create Employee account
      await _seedAccount(
        nik: 'EMP001',
        name: 'Budi Santoso',
        role: AppConstants.roleEmployee,
      );

      // Step 5: Sign out completely — user can now log in manually.
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
