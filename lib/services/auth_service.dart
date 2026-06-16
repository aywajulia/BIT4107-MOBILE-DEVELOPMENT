/// auth_service.dart
/// Location: lib/services/auth_service.dart
///
/// Handles all Firebase Authentication operations:
///   • signUp   — creates a new account
///   • login    — signs in existing user
///   • logout   — signs out current user
///   • currentUser — returns the logged-in user

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Single FirebaseAuth instance used throughout the app
  static final _auth = FirebaseAuth.instance;

  // ── Sign up ────────────────────────────────────────────────────────────────

  /// Creates a new Firebase user with [email] and [password].
  /// Throws FirebaseAuthException if email is already in use
  /// or if the password is too weak.
  static Future<User?> signUp(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user;
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  /// Signs in an existing user.
  /// Throws FirebaseAuthException if credentials are wrong.
  static Future<User?> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  /// Signs out the currently logged-in user from Firebase.
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns the currently signed-in Firebase User, or null.
  static User? get currentUser => _auth.currentUser;

  /// Returns true if someone is logged in.
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Converts a FirebaseAuthException error code into a
  /// human-readable message to show the user.
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}