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
    String? bio,
    String? photoURL,
    String? age,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Update in Firestore
      final Map<String, dynamic> userData = {
        'displayName': name,
        'username': username,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Only add optional fields if they are provided
      if (bio != null) userData['bio'] = bio;
      if (photoURL != null) userData['photoURL'] = photoURL;
      if (age != null && age.isNotEmpty) {
        // Convert age to integer if possible
        int? ageInt = int.tryParse(age);
        userData['age'] = ageInt ?? age;
      }

      await _firestore.collection('users').doc(user.uid).update(userData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user profile: $e');
      }
      throw Exception('Failed to update profile: $e');
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
}
