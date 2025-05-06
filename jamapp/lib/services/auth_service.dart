import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      if (kDebugMode) {
        print('Sign in error: $e');
      }
      return null;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      return result.user;
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
      return null;
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        return {
          'email': user.email,
          'name': user.displayName,
          'photoURL': user.photoURL,
        };
      }

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching user profile: $e');
      }
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String name,
    required String username,
    String? age,
    String? photoURL, // Change parameter type to accept nullable String
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    // Convert age to int if provided
    int? ageInt;
    if (age != null && age.isNotEmpty) {
      ageInt = int.tryParse(age);
    }

    // Update Firestore document
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'displayName': name,
      'username': username,
      if (ageInt != null) 'age': ageInt,
      if (photoURL != null)
        'photoURL': photoURL, // Only update if photoURL is provided
      'profileComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update auth profile
    await user.updateDisplayName(name);
    if (photoURL != null) {
      await user.updatePhotoURL(photoURL);
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Delete user data from Firestore first
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete any subcollections if needed
      // Example: Delete workouts subcollection
      final workoutsQuery =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('workouts')
              .get();

      for (var doc in workoutsQuery.docs) {
        await doc.reference.delete();
      }

      // Finally delete the Firebase Auth user
      await user.delete();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting account: $e');
      }
      // Depending on the error, user might need to reauthenticate
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        throw Exception('Please sign in again before deleting your account');
      }
      throw Exception('Failed to delete account: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // Generate token for watch authentication
  Future<String?> generateWatchToken() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      // Get token from Firebase
      String? idToken = await user.getIdToken();
      if (idToken == null) return null;

      // Store token in SharedPreferences for watch access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('watch_auth_token', idToken);

      return idToken;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating watch token: $e');
      }
      return null;
    }
  }

  // Validate a pairing code for watch authentication
  Future<Map<String, dynamic>?> validatePairingCode(String code) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = Timestamp.now();

      // Find the code in Firestore
      final codeQuery =
          await firestore
              .collection('pairing_codes')
              .where('code', isEqualTo: code)
              .where('expiryTime', isGreaterThan: now)
              .limit(1)
              .get();

      // If code exists and hasn't expired
      if (codeQuery.docs.isNotEmpty) {
        final codeDoc = codeQuery.docs.first;
        final userId = codeDoc.data()['userId'];

        // Get the user data
        final userDoc = await firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          // Return user data for authentication
          return {'userId': userId, 'userData': userDoc.data(), 'valid': true};
        }
      }

      return {'valid': false};
    } catch (e) {
      print('Error validating pairing code: $e');
      return {'valid': false, 'error': e.toString()};
    }
  }

  // Cleanup expired pairing codes
  Future<void> cleanupExpiredPairingCodes() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = Timestamp.now();

      // Find expired codes
      final expiredCodesQuery =
          await firestore
              .collection('pairing_codes')
              .where('expiryTime', isLessThan: now)
              .get();

      // Delete each expired code
      for (var doc in expiredCodesQuery.docs) {
        await doc.reference.delete();
      }

      if (kDebugMode) {
        print(
          'Cleaned up ${expiredCodesQuery.docs.length} expired pairing codes',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up expired pairing codes: $e');
      }
    }
  }
}
