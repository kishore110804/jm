import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class HealthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Simulated health data
  int _steps = 0;
  double _calories = 0;
  double _distance = 0;
  DateTime _lastUpdate = DateTime.now();
  bool _isAuthorized = false;

  // Singleton pattern
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  // Initialize
  Future<bool> initialize() async {
    await _loadSavedData();
    return true;
  }

  // Request authorization - simulated
  Future<bool> requestAuthorization() async {
    try {
      // Simulate requesting permission
      await Future.delayed(const Duration(milliseconds: 500));
      _isAuthorized = true;

      // Save authorization state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('health_authorized', _isAuthorized);

      return _isAuthorized;
    } catch (e) {
      if (kDebugMode) {
        print('Health permission error: $e');
      }
      return false;
    }
  }

  // Check if authorized
  Future<bool> isAuthorized() async {
    if (_isAuthorized) return true;

    final prefs = await SharedPreferences.getInstance();
    _isAuthorized = prefs.getBool('health_authorized') ?? false;
    return _isAuthorized;
  }

  // Load saved health data
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _steps = prefs.getInt('health_steps') ?? 0;
      _calories = prefs.getDouble('health_calories') ?? 0;
      _distance = prefs.getDouble('health_distance') ?? 0;

      final lastUpdateMillis = prefs.getInt('health_last_update');
      if (lastUpdateMillis != null) {
        _lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
      }

      _isAuthorized = prefs.getBool('health_authorized') ?? false;

      // If it's a new day, reset the counters
      final now = DateTime.now();
      if (now.day != _lastUpdate.day ||
          now.month != _lastUpdate.month ||
          now.year != _lastUpdate.year) {
        _steps = 0;
        _calories = 0;
        _distance = 0;
        _lastUpdate = now;
        await _saveData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading health data: $e');
      }
    }
  }

  // Save current health data
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('health_steps', _steps);
      await prefs.setDouble('health_calories', _calories);
      await prefs.setDouble('health_distance', _distance);
      await prefs.setInt(
        'health_last_update',
        _lastUpdate.millisecondsSinceEpoch,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving health data: $e');
      }
    }
  }

  // Get current health data
  Future<Map<String, dynamic>> getCurrentHealthData() async {
    await _generateNewData(); // Generate new data on request

    return {
      'steps': _steps,
      'calories': _calories.toInt(),
      'distance': _distance,
      'lastUpdate': _lastUpdate.millisecondsSinceEpoch,
    };
  }

  // Generate simulated health data
  Future<void> _generateNewData() async {
    if (!_isAuthorized) return;

    final now = DateTime.now();
    final minutesSinceLastUpdate = now.difference(_lastUpdate).inMinutes;

    if (minutesSinceLastUpdate < 2) return; // Only update every 2 minutes

    // Generate random increase in steps based on time passed
    final random = Random();
    final newSteps = random.nextInt(
      minutesSinceLastUpdate * 20,
    ); // Avg ~10 steps per minute

    _steps += newSteps;
    _calories += newSteps * 0.05; // ~0.05 calories per step
    _distance += newSteps * 0.0007; // ~0.7 meters per step
    _lastUpdate = now;

    await _saveData();
  }

  // Fetch health data and sync to Firebase
  Future<void> syncHealthData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _generateNewData();

      // Store in Firebase
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fitness_data')
          .doc(dateStr)
          .set({
            'date': dateStr,
            'steps': _steps,
            'calories': _calories.toInt(),
            'distance': _distance,
            'source': 'Device',
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Update user's total stats
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .doc('fitness')
          .set({
            'totalSteps': _steps,
            'totalCalories': _calories.toInt(),
            'totalDistance': _distance,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing health data: $e');
      }
    }
  }

  // Compare with friends
  Future<List<Map<String, dynamic>>> getFriendsComparison() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Get user's friends
      final friendsDoc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('social')
              .doc('friends')
              .get();

      if (!friendsDoc.exists) return [];

      final friendIds = List<String>.from(
        friendsDoc.data()?['friendIds'] ?? [],
      );

      if (friendIds.isEmpty) return [];

      // Get current user's today's stats
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final userStats =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('fitness_data')
              .doc(dateStr)
              .get();

      final mySteps = userStats.data()?['steps'] ?? _steps;

      // Get friends' profiles and stats
      List<Map<String, dynamic>> friends = [];

      for (String friendId in friendIds) {
        // Get friend profile
        final friendProfile =
            await _firestore.collection('users').doc(friendId).get();

        // Get friend stats
        final friendStats =
            await _firestore
                .collection('users')
                .doc(friendId)
                .collection('fitness_data')
                .doc(dateStr)
                .get();

        if (friendProfile.exists) {
          friends.add({
            'id': friendId,
            'name': friendProfile.data()?['displayName'] ?? 'Unknown',
            'username': friendProfile.data()?['username'] ?? 'Unknown',
            'photoURL': friendProfile.data()?['photoURL'],
            'steps': friendStats.data()?['steps'] ?? 0,
            'behind': mySteps > (friendStats.data()?['steps'] ?? 0),
            'difference': (mySteps - (friendStats.data()?['steps'] ?? 0)).abs(),
          });
        }
      }

      // Sort by steps (descending)
      friends.sort((a, b) => (b['steps'] as int).compareTo(a['steps'] as int));

      return friends;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting friends comparison: $e');
      }
      return [];
    }
  }

  // Get weekly step history
  Future<List<Map<String, dynamic>>> getWeeklyStepHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final now = DateTime.now();
      final List<Map<String, dynamic>> weekData = [];

      // Generate the last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        // Try to get data from Firebase
        final docSnapshot =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('fitness_data')
                .doc(dateStr)
                .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          weekData.add({
            'date': dateStr,
            'dayName': _getDayName(date.weekday),
            'steps': data['steps'] ?? 0,
            'target': data['target'] ?? 10000,
            'progress': (data['steps'] ?? 0) / (data['target'] ?? 10000),
          });
        } else {
          // If no data exists for this day
          weekData.add({
            'date': dateStr,
            'dayName': _getDayName(date.weekday),
            'steps': i == 0 ? _steps : 0, // Use current steps for today
            'target': 10000,
            'progress': i == 0 ? _steps / 10000 : 0,
          });
        }
      }

      return weekData;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting weekly history: $e');
      }
      return [];
    }
  }

  // Helper to get day name
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  // Get step target for today
  Future<int> getStepTarget() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 10000;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData.containsKey('dailyGoals')) {
          return userData['dailyGoals']['steps'] ?? 10000;
        }
      }

      return 10000; // Default target
    } catch (e) {
      return 10000; // Default on error
    }
  }

  // Update step target
  Future<bool> updateStepTarget(int newTarget) async {
    try {
      if (newTarget < 1000) newTarget = 1000; // Minimum target

      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('users').doc(user.uid).update({
        'dailyGoals.steps': newTarget,
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating step target: $e');
      }
      return false;
    }
  }

  // Reset steps for testing purposes
  Future<void> resetStepsForTesting() async {
    _steps = 0;
    _calories = 0;
    _distance = 0;
    _lastUpdate = DateTime.now();
    await _saveData();
    await syncHealthData();
  }

  // Add steps manually - helpful for testing
  Future<void> addStepsManually(int additionalSteps) async {
    if (additionalSteps <= 0) return;

    _steps += additionalSteps;
    _calories += additionalSteps * 0.05;
    _distance += additionalSteps * 0.0007;
    _lastUpdate = DateTime.now();

    await _saveData();
    await syncHealthData();
  }
}
