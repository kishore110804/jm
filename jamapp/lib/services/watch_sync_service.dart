import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

// Handles synchronization between phones and watch devices, managing workout data transfer
class WatchSyncService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Timer for automatic syncing
  Timer? _syncTimer;

  // Start periodic syncing
  void startAutoSync({Duration interval = const Duration(minutes: 15)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncData());

    // Do an immediate sync
    syncData();
  }

  // Stop periodic syncing
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Manually trigger sync
  Future<bool> syncData() async {
    try {
      if (_auth.currentUser == null) return false;

      // 1. Sync user profile data
      bool profileSynced = await _syncUserProfile();

      // 2. Sync workout data
      bool workoutSynced = await _syncWorkoutData();

      // 3. Sync fitness goals
      bool goalsSynced = await _syncFitnessGoals();

      // 4. Refresh auth token for watch
      await _authService.generateWatchToken();

      return profileSynced && workoutSynced && goalsSynced;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Watch sync error: $e');
      }
      return false;
    }
  }

  // Sync user profile
  Future<bool> _syncUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', jsonEncode(doc.data()));

      return true;
    } catch (e) {
      return false;
    }
  }

  // Sync workout data
  Future<bool> _syncWorkoutData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get recent workouts
      QuerySnapshot workouts =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('workouts')
              .orderBy('timestamp', descending: true)
              .limit(20)
              .get();

      List<Map<String, dynamic>> workoutData =
          workouts.docs.map((d) => d.data() as Map<String, dynamic>).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recent_workouts', jsonEncode(workoutData));

      // Also get any pending workouts from watch to sync back to cloud
      String? pendingWorkoutsJson = prefs.getString('pending_watch_workouts');
      if (pendingWorkoutsJson != null) {
        try {
          List<dynamic> pendingWorkouts = List<dynamic>.from(
            jsonDecode(pendingWorkoutsJson),
          );

          // Upload each pending workout
          for (var workout in pendingWorkouts) {
            if (workout is Map<String, dynamic>) {
              await _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('workouts')
                  .add(workout);
            } else {
              if (kDebugMode) {
                print('⚠️ Skipping invalid workout data: $workout');
              }
            }
          }

          // Clear pending workouts after successful sync
          await prefs.remove('pending_watch_workouts');
        } catch (jsonError) {
          if (kDebugMode) {
            print('❌ Error parsing pending workouts JSON: $jsonError');
          }
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error syncing workout data: $e');
      }
      return false;
    }
  }

  // Sync fitness goals
  Future<bool> _syncFitnessGoals() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot goals =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('settings')
              .doc('goals')
              .get();

      if (goals.exists) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fitness_goals', jsonEncode(goals.data()));
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Record offline workout from watch
  Future<bool> saveWatchWorkout(Map<String, dynamic> workoutData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? existingData = prefs.getString('pending_watch_workouts');

      List<dynamic> pendingWorkouts = [];
      if (existingData != null) {
        try {
          // Safer JSON decoding with error handling
          pendingWorkouts = List<dynamic>.from(jsonDecode(existingData));
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing pending workouts: $e');
          }
          // Reset to empty list if JSON is invalid
          pendingWorkouts = [];
        }
      }

      // Add timestamp if not present
      if (!workoutData.containsKey('timestamp')) {
        workoutData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      }

      // Make sure we have a valid workout type
      if (!workoutData.containsKey('type')) {
        workoutData['type'] = 'unknown';
      }

      // Add to pending workouts
      pendingWorkouts.add(workoutData);

      // Save back to SharedPreferences
      await prefs.setString(
        'pending_watch_workouts',
        jsonEncode(pendingWorkouts),
      );

      // Try to sync immediately if possible
      syncData().catchError((error) {
        if (kDebugMode) {
          print('❌ Error syncing data: $error');
        }
        return false; // Return value is correct now
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving watch workout: $e');
      }
      return false;
    }
  }
}
