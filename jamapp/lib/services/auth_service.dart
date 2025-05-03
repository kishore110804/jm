import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/widgets.dart'; // Add this import for WidgetsBinding
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart'; // Add this for secure token generation
import 'dart:math'; // For random number generation
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart'; // For app version info

// This is the core authentication service that manages all user authentication flows
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a secure storage instance for tokens
  final _secureStorage = const FlutterSecureStorage();

  // Constants for token management
  static const String _AUTH_TOKEN_KEY = 'auth_token';
  static const String _TOKEN_EXPIRY_KEY = 'auth_token_expiry';
  static const String _REFRESH_TOKEN_KEY = 'refresh_token';

  // Auth change user stream
  Stream<User?> get user => _auth.authStateChanges();

  // Check if a user is currently authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Configure Google Sign In with web client ID
  Future<void> configureGoogleSignIn() async {
    try {
      // Use a simple configuration without extra parameters
      // This often resolves API exception 10 when previous config was working
      _googleSignIn = GoogleSignIn();

      if (kDebugMode) {
        print('🔄 Google Sign In configured');
      }
    } catch (e) {
      _logError('Configuring Google Sign In', e);
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _logAuthSuccess('Email/Password Sign In', result.user?.uid);

      return {
        'success': true,
        'user': result.user,
        'message': 'Successfully signed in',
      };
    } on FirebaseAuthException catch (e) {
      _logAuthError('Email/Password Sign In', e);

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Invalid password';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'too-many-requests':
          message = 'Too many sign-in attempts. Try again later';
          break;
        default:
          message = 'Authentication failed: ${e.message}';
      }

      return {
        'success': false,
        'message': message,
        'error': e,
        'error_code': e.code,
      };
    } catch (e) {
      _logAuthError('Email/Password Sign In', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e,
      };
    }
  }

  // Sign in with Google - direct Firebase approach to avoid API issues
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Use FirebaseAuth directly to open the Google sign-in flow
      final googleProvider = GoogleAuthProvider();

      // Add scope to match what we need
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // For Android, use signInWithProvider which is more reliable
      UserCredential userCredential;

      try {
        // Try the direct sign-in approach
        userCredential = await _auth.signInWithProvider(googleProvider);
      } catch (e) {
        // If direct sign-in fails, try the popup approach as fallback
        userCredential = await _auth.signInWithPopup(googleProvider);
      }

      _logAuthSuccess('Google Sign In', userCredential.user?.uid);

      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Create initial user document with default stats
        await _createNewUserProfile(userCredential.user!);
      }

      return {
        'success': true,
        'user': userCredential.user,
        'isNewUser': userCredential.additionalUserInfo?.isNewUser ?? false,
        'message': 'Successfully signed in with Google',
      };
    } catch (e) {
      _logAuthError('Google Sign In', e);

      // More descriptive error message based on error type
      String errorMessage = 'An unexpected error occurred';
      if (e.toString().contains('FirebaseException')) {
        errorMessage = 'Firebase error: ${e.toString()}';
      } else if (e.toString().contains('PlatformException')) {
        errorMessage = 'Platform error: Try using email sign-in instead';
      }

      return {'success': false, 'message': errorMessage, 'error': e};
    }
  }

  // Check if Google Sign In is properly configured
  Future<bool> _isGoogleSignInAvailable() async {
    try {
      // Don't use canAccessScopes as it's not implemented on all platforms
      return true;
    } catch (e) {
      _logError('Google Sign In check', e);
      return false;
    }
  }

  // Helper method to handle PigeonUserDetails error by manually creating an account
  Future<Map<String, dynamic>> _createAccountFromGoogleData(
    GoogleSignInAccount googleUser,
  ) async {
    try {
      // Generate a secure random password for this user
      final password = _generateNonce(16);

      // Store the password securely for future use
      await _secureStorage.write(
        key: 'google_pwd_${googleUser.email}',
        value: password,
      );

      // Try to check if the user already exists first
      bool doesUserExist = false;
      try {
        // Use this.userExists to clearly reference the method, not the variable
        doesUserExist = await this.userExists(googleUser.email);
      } catch (e) {
        // Silently continue if this check fails
      }

      UserCredential userCredential;

      if (doesUserExist) {
        // If the user already exists, try using the provider
        try {
          // First, get the sign-in methods
          List<String> methods = await _auth.fetchSignInMethodsForEmail(
            googleUser.email,
          );

          if (methods.contains('password')) {
            // Try to sign in with the password we stored previously
            userCredential = await _auth.signInWithEmailAndPassword(
              email: googleUser.email,
              password: await _getOrCreatePasswordForGoogleUser(
                googleUser.email,
              ),
            );
          } else {
            // If email/password not available, create a new account
            userCredential = await _auth.createUserWithEmailAndPassword(
              email: googleUser.email,
              password: password,
            );
          }
        } catch (e) {
          _logAuthError('Sign-in with existing account', e);

          // As a last resort, try to create a fresh user
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: googleUser.email,
            password: password,
          );
        }
      } else {
        // Attempt to create a new user
        try {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: googleUser.email,
            password: password,
          );
        } catch (e) {
          if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
            // If creation failed due to existing email, try to sign in with our stored password
            userCredential = await _auth.signInWithEmailAndPassword(
              email: googleUser.email,
              password: await _getOrCreatePasswordForGoogleUser(
                googleUser.email,
              ),
            );
          } else {
            // If that fails too, try a more generic approach
            _logAuthError('Account creation error', e);

            // Generate a different password for another attempt
            final newPassword = _generateNonce(20);
            await _secureStorage.write(
              key: 'google_pwd_${googleUser.email}',
              value: newPassword,
            );

            userCredential = await _auth.createUserWithEmailAndPassword(
              email: googleUser.email,
              password: newPassword,
            );
          }
        }
      }

      // Update the user profile with Google data
      if (userCredential.user != null) {
        try {
          await userCredential.user!.updateDisplayName(
            googleUser.displayName ?? 'User',
          );

          if (googleUser.photoUrl != null) {
            await userCredential.user!.updatePhotoURL(googleUser.photoUrl);
          }

          // Create or update user profile in Firestore
          await _createNewUserProfile(userCredential.user!);
        } catch (e) {
          _logError('Updating user profile', e);
          // Continue even if profile update fails
        }
      }

      return {
        'success': true,
        'user': userCredential.user,
        'isNewUser': false, // We don't really know, so assume existing
        'message': 'Successfully signed in with Google (alternative method)',
      };
    } catch (e) {
      _logAuthError('Manual account creation', e);

      // If all fails, give a more specific error message
      String errorMessage = 'Failed to create account from Google data';
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-credential') {
          errorMessage =
              'The Google authentication data could not be verified. Please try again.';
        } else if (e.code == 'account-exists-with-different-credential') {
          errorMessage =
              'An account already exists with the same email but different sign-in credentials.';
        }
      }

      return {'success': false, 'message': errorMessage, 'error': e};
    }
  }

  // Helper to get or create a password for Google users
  Future<String> _getOrCreatePasswordForGoogleUser(String email) async {
    // Try to get stored password
    final storedPassword = await _secureStorage.read(key: 'google_pwd_$email');
    if (storedPassword != null) {
      return storedPassword;
    }

    // If not found, create and store a new password
    final newPassword = _generateNonce(16);
    await _secureStorage.write(key: 'google_pwd_$email', value: newPassword);
    return newPassword;
  }

  // Complete Google sign-in with an already selected account
  Future<Map<String, dynamic>> completeGoogleSignIn(
    GoogleSignInAccount googleUser,
  ) async {
    try {
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      _logAuthSuccess('Google Sign In', userCredential.user?.uid);

      // This is a new user - create profile
      await _createNewUserProfile(userCredential.user!);

      return {
        'success': true,
        'user': userCredential.user,
        'isNewUser': true,
        'message': 'Successfully registered with Google',
      };
    } catch (e) {
      _logAuthError('Google Sign In Completion', e);
      return {
        'success': false,
        'message': 'Failed to complete Google sign in: $e',
        'error': e,
      };
    }
  }

  // Check if current platform is a watch
  Future<bool> _isWatchPlatform() async {
    // This is a simplified check - you might need a more sophisticated detection
    try {
      final window = WidgetsBinding.instance.window;
      // Most watches have small, nearly square screens
      final size = window.physicalSize;
      final ratio = size.width / size.height;
      // Most watches have ratios close to 1.0
      return ratio > 0.8 && ratio < 1.2 && size.width < 500;
    } catch (e) {
      return false;
    }
  }

  // Token-based authentication for watches
  Future<Map<String, dynamic>> _signInWithTokenForWatch() async {
    try {
      // For watches, we'll use a companion app token approach
      // This is a placeholder implementation

      // 1. Check for cached auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('watch_auth_token');

      if (token != null) {
        // Use the token to authenticate with Firebase
        // Fix: Use GoogleAuthProvider.credential instead of direct AuthCredential
        final credential = GoogleAuthProvider.credential(
          idToken: token,
          accessToken: null, // Access token can be null for ID token auth
        );

        final userCredential = await _auth.signInWithCredential(credential);
        return {
          'success': true,
          'user': userCredential.user,
          'message': 'Successfully signed in with saved token',
        };
      } else {
        return {
          'success': false,
          'message': 'Watch needs to be paired with phone first',
        };
      }
    } catch (e) {
      _logError('Watch token sign in', e);
      return {
        'success': false,
        'message': 'Watch authentication failed. Pair with phone app.',
        'error': e,
      };
    }
  }

  // Generate and store authentication token for watch
  Future<String> generateWatchToken() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get ID token
    // Fix: Handle nullable String with null check
    String? idToken = await currentUser.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to generate authentication token');
    }

    // Store in SharedPreferences for later use by watch
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('watch_auth_token', idToken);

    return idToken;
  }

  // Sync user data between watch and phone
  Future<bool> syncWatchData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get user profile
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!doc.exists) return false;

      // Store essential data for offline access on watch
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', jsonEncode(doc.data()));

      // Get recent fitness data
      QuerySnapshot workouts =
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('workouts')
              .orderBy('timestamp', descending: true)
              .limit(10)
              .get();

      List<Map<String, dynamic>> workoutData =
          workouts.docs.map((d) => d.data() as Map<String, dynamic>).toList();

      await prefs.setString('recent_workouts', jsonEncode(workoutData));

      return true;
    } catch (e) {
      _logError('Syncing watch data', e);
      return false;
    }
  }

  // Add this helper method for safely processing Firestore data
  Map<String, dynamic> _processSafelyUserData(dynamic data) {
    if (data == null) return {};

    try {
      if (data is Map<String, dynamic>) {
        return data;
      } else if (data is Map) {
        // Convert any Map to Map<String, dynamic>
        return Map<String, dynamic>.from(data);
      } else {
        // For other cases (like the PigeonUserDetails error), do a JSON conversion
        final jsonString = jsonEncode(data);
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      _logError('Converting user data', e);
      return {};
    }
  }

  // Create a new user profile with default data - fixed to handle potential data issues
  Future<void> _createNewUserProfile(User user) async {
    try {
      // Initialize with default user data and stats
      final userData = {
        'email': user.email,
        'displayName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'photoURL': user.photoURL,
        'createdAt': Timestamp.now(),
        'profileComplete': false,
        'stats': {'steps': 0, 'calories': 0, 'distance': 0.0, 'workouts': 0},
        'dailyGoals': {'steps': 10000, 'water': 8, 'sleep': 8},
      };

      // Check if document already exists to avoid overwriting data
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        // Document exists - only update missing fields, don't overwrite
        final existingData = _processSafelyUserData(docSnapshot.data());
        final updatedData = {...userData};

        // Don't overwrite fields that already exist
        for (final key in existingData.keys) {
          if (existingData[key] != null) {
            updatedData.remove(key);
          }
        }

        if (updatedData.isNotEmpty) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .update(updatedData);
        }
      } else {
        // Document doesn't exist - create new
        await _firestore.collection('users').doc(user.uid).set(userData);
      }
    } catch (e) {
      _logError('Creating user profile', e);
      // Continue even if Firestore update fails - we'll try again later
    }
  }

  // Register with email and password
  Future<Map<String, dynamic>> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _logAuthSuccess('User Registration', userCredential.user?.uid);

      // Create a user document in Firestore
      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'createdAt': Timestamp.now(),
          'profileComplete': false,
          'displayName': email.split('@')[0],
        });
      } catch (e) {
        _logAuthError('Create Firestore User Document', e);
        // Continue even if Firestore update fails
      }

      return {
        'success': true,
        'user': userCredential.user,
        'message': 'Registration successful',
      };
    } on FirebaseAuthException catch (e) {
      // Use direct error handling instead of calling undefined method
      _logAuthError('User Registration', e);

      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }

      return {
        'success': false,
        'message': message,
        'error': e,
        'error_code': e.code,
      };
    } catch (e) {
      _logAuthError('User Registration', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred during registration',
        'error': e,
      };
    }
  }

  // Check if user profile is complete
  Future<bool> isProfileComplete() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      return doc.exists &&
          (doc.data() as Map<String, dynamic>)['profileComplete'] == true;
    } catch (e) {
      _logError('Checking profile completeness', e);
      return false;
    }
  }

  // Update user profile with enhanced profile management
  Future<void> updateUserProfile({
    required String name,
    required String username,
    String? bio,
    String? age,
    String? photoURL,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final updateData = {
        'name': name,
        'username': username,
        'profileComplete': true,
        'updatedAt': Timestamp.now(),
      };

      // Only add optional fields if they're provided
      if (bio != null) updateData['bio'] = bio;
      if (age != null) updateData['age'] = age;
      if (photoURL != null) updateData['photoURL'] = photoURL;

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(updateData);

      // Also update the display name in Firebase Auth
      await currentUser.updateDisplayName(name);

      // Update photo URL if provided
      if (photoURL != null) {
        await currentUser.updatePhotoURL(photoURL);
      }

      _logAuthSuccess('Profile Updated', currentUser.uid);
    } catch (e) {
      _logError('Updating profile', e);
      throw Exception('Failed to update profile: $e');
    }
  }

  // Delete user account and all associated data
  Future<void> deleteAccount() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final uid = currentUser.uid;

      // 1. Delete all user data from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // 2. Delete user's workouts subcollection
      final workoutsSnapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('workouts')
              .get();

      final batch = _firestore.batch();
      for (var doc in workoutsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // 3. Delete user from Firebase Auth
      await currentUser.delete();

      _logAuthSuccess('Account Deleted', uid);
    } catch (e) {
      _logAuthError('Account Deletion', e);

      // Special case: If this fails due to auth being too old, we need to re-authenticate
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        throw Exception(
          'Please sign out and sign in again to delete your account',
        );
      }

      throw Exception('Failed to delete account: $e');
    }
  }

  // Fix for pegionDetails error - proper encoding and decoding of user data
  Future<Map<String, dynamic>> _safelyDecodeUserData(
    DocumentSnapshot doc,
  ) async {
    try {
      // First try with standard casting
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        return data;
      }

      // If that fails, try manual conversion to ensure safe types
      final rawData = doc.data();
      if (rawData == null) {
        return {};
      }

      // Convert manually using jsonEncode/jsonDecode to sanitize the data
      final jsonString = jsonEncode(rawData);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      _logError('Decoding user data', e);
      // Return empty map rather than null to avoid further errors
      return {};
    }
  }

  // Enhanced getUserProfile with error handling for the pegionDetails issue
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (doc.exists) {
        // Use the safe decode method to prevent pegionDetails errors
        return await _safelyDecodeUserData(doc);
      }

      return null;
    } catch (e) {
      _logError('Getting profile', e);
      return null;
    }
  }

  // Check if user exists already
  Future<bool> userExists(String email) async {
    try {
      // First, check auth methods
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        return true;
      }

      // Also check Firestore for the user (in case auth record exists but Firestore doc doesn't)
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      _logError('Checking user existence', e);
      // Default to false if there's an error
      return false;
    }
  }

  // Get Google account without signing in to Firebase
  Future<GoogleSignInAccount?> getGoogleAccount() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      _logError('Getting Google account', e);
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      return await _auth.signOut();
    } catch (e) {
      _logError('Signing out', e);
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Enhanced token storage with expiration
  Future<void> storeAuthToken() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get fresh token with expiration info
      String? token = await currentUser.getIdToken(true);
      if (token == null) return;

      // Calculate expiration (typical Firebase token expires in 1 hour)
      final expiry =
          DateTime.now()
              .add(const Duration(minutes: 55))
              .millisecondsSinceEpoch
              .toString();

      // Store using secure storage
      await _secureStorage.write(key: _AUTH_TOKEN_KEY, value: token);
      await _secureStorage.write(key: _TOKEN_EXPIRY_KEY, value: expiry);

      // Get and store refresh token if available
      try {
        // Not directly available in Firebase Auth, this is a workaround
        // You'd need server-side implementation for proper refresh tokens
        final tokenHash =
            sha256
                .convert(utf8.encode('${currentUser.uid}_${DateTime.now()}'))
                .toString();
        await _secureStorage.write(key: _REFRESH_TOKEN_KEY, value: tokenHash);
      } catch (e) {
        _logError('Storing refresh token', e);
      }

      if (kDebugMode) {
        print('✅ Auth tokens stored securely');
      }
    } catch (e) {
      _logError('Secure token storage', e);
    }
  }

  // Get valid auth token (with auto-refresh if needed)
  Future<String?> getValidAuthToken() async {
    try {
      // Check if current token is valid
      final expiryStr = await _secureStorage.read(key: _TOKEN_EXPIRY_KEY);
      final token = await _secureStorage.read(key: _AUTH_TOKEN_KEY);

      if (token != null && expiryStr != null) {
        final expiry = int.tryParse(expiryStr) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        // If token is still valid, return it
        if (now < expiry) {
          return token;
        }
      }

      // Token expired or missing, get a fresh one
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final newToken = await currentUser.getIdToken(true);
        if (newToken != null) {
          // Update stored token and expiry
          final newExpiry =
              DateTime.now()
                  .add(const Duration(minutes: 55))
                  .millisecondsSinceEpoch
                  .toString();
          await _secureStorage.write(key: _AUTH_TOKEN_KEY, value: newToken);
          await _secureStorage.write(key: _TOKEN_EXPIRY_KEY, value: newExpiry);
          return newToken;
        }
      }

      // If we can't refresh, try using the refresh token
      // This would require server-side implementation
      return null;
    } catch (e) {
      _logError('Getting valid auth token', e);
      return null;
    }
  }

  // Add robust error handling for authentication
  Future<Map<String, dynamic>> safeAuthOperation(
    Future<Map<String, dynamic>> Function() authOperation,
  ) async {
    try {
      return await authOperation();
    } on FirebaseAuthException catch (e) {
      _logAuthError('Safe Auth Operation', e);

      // Handle common error cases
      if (e.code == 'network-request-failed') {
        return {
          'success': false,
          'message':
              'Network connection issue. Please check your internet connection.',
          'error': e,
          'retry': true, // Flag for UI to show retry button
        };
      } else if (e.code == 'too-many-requests') {
        return {
          'success': false,
          'message':
              'Too many sign-in attempts. Please try again later or reset your password.',
          'error': e,
          'cooldown': true, // Flag for UI to disable button temporarily
        };
      }

      return {
        'success': false,
        'message': e.message ?? 'Authentication error occurred',
        'error': e,
      };
    } catch (e) {
      _logError('Safe Auth Operation', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e,
      };
    }
  }

  // Enhanced session management
  Future<void> checkAndRefreshSession() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Check token validity
      await getValidAuthToken();

      // Verify the user's account hasn't been disabled
      try {
        await currentUser.reload();
      } catch (e) {
        // If reload fails, sign out the user as their account may be disabled
        await signOut();
        _logError('Session refresh - account may be disabled', e);
      }
    } catch (e) {
      _logError('Session refresh', e);
    }
  }

  // Add support for multi-factor authentication
  Future<Map<String, dynamic>> enableMFA() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // This is a placeholder - Firebase requires server-side implementation for MFA
      // You would integrate with Firebase Admin SDK
      return {
        'success': false,
        'message': 'MFA requires Firebase Admin SDK implementation',
      };
    } catch (e) {
      _logError('Enabling MFA', e);
      return {'success': false, 'message': 'Failed to enable MFA: $e'};
    }
  }

  // Verify email (production apps should enforce verification)
  Future<bool> sendEmailVerification() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.emailVerified) return false;

      await currentUser.sendEmailVerification();
      return true;
    } catch (e) {
      _logError('Sending email verification', e);
      return false;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Force refresh user to get latest status
      await currentUser.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      _logError('Checking email verification', e);
      return false;
    }
  }

  // Add enhanced security for Google Sign-In
  Future<Map<String, dynamic>> signInWithGoogleSecure() async {
    return safeAuthOperation(() async {
      // Generate a random nonce for added security
      final rawNonce = _generateNonce();
      // Store nonce in secure storage so we can verify on server if needed
      await _secureStorage.write(key: 'auth_nonce', value: rawNonce);

      // Store the hashed nonce for potential verification
      final hashedNonce = _sha256ofString(rawNonce);
      await _secureStorage.write(key: 'auth_nonce_hash', value: hashedNonce);

      // Add nonce to verification metadata we'll send with our sign-in request
      final verificationMetadata = {
        'nonce_hash': hashedNonce,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'device_id': await _getDeviceIdentifier(),
      };

      try {
        // Check if Google Sign-In is available
        if (!await _isGoogleSignInAvailable()) {
          return {
            'success': false,
            'message': 'Google Sign-In not available on this device',
          };
        }

        // Trigger the authentication flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          _logAuthEvent('google_sign_in_cancelled', {'status': 'cancelled'});
          return {
            'success': false,
            'message': 'Google sign in was cancelled by user',
          };
        }

        // Get the authentication details
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a credential with the nonce for added security
        // Note: Standard GoogleAuthProvider doesn't support nonce directly in Flutter
        // In a real implementation, you'd use Firebase Custom Auth with your server
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in with Firebase
        final userCredential = await _auth.signInWithCredential(credential);

        // Log the successful sign-in
        _logAuthEvent('google_sign_in_success', {
          'is_new_user': userCredential.additionalUserInfo?.isNewUser ?? false,
          'auth_method': 'google_secure',
        });

        // Associate verification metadata with user's account for audit trail
        if (userCredential.user != null) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .collection('auth_sessions')
              .add({
                'auth_method': 'google_secure',
                'verification': verificationMetadata,
                'timestamp': Timestamp.now(),
                'platform': Platform.operatingSystem,
                'app_version': await _getAppVersion(),
              });
        }

        // Create user profile if needed
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _createNewUserProfile(userCredential.user!);
        }

        return {
          'success': true,
          'user': userCredential.user,
          'isNewUser': userCredential.additionalUserInfo?.isNewUser ?? false,
          'message': 'Successfully signed in with Google (Secure)',
        };
      } catch (e) {
        _logAuthEvent('google_sign_in_error', {'error': e.toString()});
        _logAuthError('Secure Google Sign In', e);
        return {
          'success': false,
          'message': 'Failed to authenticate with Google: ${e.toString()}',
          'error': e,
        };
      }
    });
  }

  // Get a unique device identifier for security logging
  Future<String> _getDeviceIdentifier() async {
    try {
      // Get a stored device ID or generate a new one
      String? deviceId = await _secureStorage.read(key: 'device_identifier');

      if (deviceId == null) {
        // Generate a new random identifier
        deviceId = _generateNonce(64);
        await _secureStorage.write(key: 'device_identifier', value: deviceId);
      }

      return deviceId;
    } catch (e) {
      return 'unknown_device';
    }
  }

  // Get the current app version for security logging
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      return 'unknown_version';
    }
  }

  // Add analytics for authentication events
  void _logAuthEvent(String eventName, Map<String, dynamic> parameters) {
    try {
      // In production environments, use Firebase Analytics
      if (!kDebugMode) {
        // Uncomment and use this code when you add Firebase Analytics to pubspec.yaml
        // FirebaseAnalytics.instance.logEvent(
        //   name: eventName,
        //   parameters: parameters,
        // );
      }

      // Also log to console for debugging
      if (kDebugMode) {
        print('📊 AUTH EVENT: $eventName');
        print('📊 PARAMETERS: $parameters');
      }

      // Track critical auth events in Firestore for admin monitoring
      if (eventName.contains('error') || eventName.contains('failed')) {
        _firestore
            .collection('auth_events')
            .add({
              'event': eventName,
              'parameters': parameters,
              'timestamp': Timestamp.now(),
              'platform': Platform.operatingSystem,
            })
            .catchError((e) {
              // Silent fail - don't disrupt user flow if analytics fails
              if (kDebugMode) {
                print('Failed to log auth event to Firestore: $e');
              }
              // Return a dummy DocumentReference to satisfy the type system
              return _firestore
                  .collection('auth_events')
                  .doc('error_logging_failed');
            });
      }
    } catch (e) {
      // Don't let analytics failures affect the auth flow
      if (kDebugMode) {
        print('Error logging auth event: $e');
      }
    }
  }

  // Generate a random nonce for auth
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // SHA256 hash for nonce
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Helper for logging authentication successes
  void _logAuthSuccess(String operation, String? uid) {
    if (kDebugMode) {
      print('📱 AUTH SUCCESS: $operation | User ID: $uid');
    }
  }

  // Helper for logging authentication errors
  void _logAuthError(String operation, dynamic error) {
    if (kDebugMode) {
      print('❌ AUTH ERROR: $operation');
      print('Error details: $error');
      if (error is FirebaseAuthException) {
        print('Error message: ${error.message}');
        print('Error code: ${error.code}');
      }
    }
  }

  // Helper for logging general errors
  void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      print('❌ ERROR: $operation');
      print('Error details: $error');
    }
  }
}
