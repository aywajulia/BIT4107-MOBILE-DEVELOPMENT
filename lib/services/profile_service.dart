/// profile_service.dart
/// Location: lib/services/profile_service.dart
///
/// Handles saving and loading user profile data
/// from Cloud Firestore.
///
/// Firestore structure:
///   users/
///     {uid}/          ← document per user (uid from Firebase Auth)
///       name
///       email
///       height
///       weight
///       targetWeight
///       activityLevel
///       updatedAt

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  // Firestore instance
  static final _db = FirebaseFirestore.instance;

  // ── Save profile ───────────────────────────────────────────────────────────

  /// Saves or overwrites the user's profile in Firestore.
  /// Uses the Firebase Auth uid as the document id so each
  /// user has exactly one profile document.
  static Future<void> saveProfile({
    required String name,
    required String email,
    String? height,
    String? weight,
    String? targetWeight,
    String? activityLevel,
  }) async {
    // Get the uid of the currently logged-in user
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // not logged in — do nothing

    // Write to Firestore — set() overwrites or creates the document
    await _db.collection('users').doc(uid).set({
      'name':          name,
      'email':         email,
      'height':        height ?? '',
      'weight':        weight ?? '',
      'targetWeight':  targetWeight ?? '',
      'activityLevel': activityLevel ?? 'Beginner',
      // serverTimestamp() uses Firebase's server clock — not the device clock
      'updatedAt':     FieldValue.serverTimestamp(),
    });
  }

  // ── Load profile ───────────────────────────────────────────────────────────

  /// Loads the user's profile from Firestore.
  /// Returns a Map of the profile fields, or null if no profile exists yet.
  static Future<Map<String, dynamic>?> loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    // Get the document for this user
    final doc = await _db.collection('users').doc(uid).get();

    // doc.exists is false if the user has never saved a profile
    return doc.exists ? doc.data() : null;
  }

  // ── Delete profile ─────────────────────────────────────────────────────────

  /// Deletes the user's profile document from Firestore.
  /// Called when the user deletes their account.
  static Future<void> deleteProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).delete();
  }
}