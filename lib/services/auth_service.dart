import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Authentication — sign-in, sign-out, and auth state stream.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  /// Stream of Firebase [User] objects — null when signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current signed-in user or null.
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Create a new account (used by admin seeding flow).
  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out the current user.
  Future<void> signOut() => _auth.signOut();

  /// Returns a human-readable message for common Firebase auth errors.
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'NIK tidak terdaftar.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'invalid-email':
        return 'NIK tidak valid.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'invalid-credential':
        return 'NIK atau password salah.';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }
}
