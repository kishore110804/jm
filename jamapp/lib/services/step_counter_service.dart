import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StepCounterService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Step count variables
  int _steps = 0;
  int _lastSavedSteps = 0;
  DateTime _lastSyncTime = DateTime.now();
  Timer? _syncTimer;
  Timer? _simulationTimer;
  bool _isSimulating = false;

  // Singleton pattern
  static final StepCounterService _instance = StepCounterService._internal();
  factory StepCounterService() => _instance;
  StepCounterService._internal();

  // Current state getters
  int get steps => _steps;

  // Initialize the step counter
  Future<bool> initStepCounter() async {
    await _loadSavedSteps();
    _startPeriodicSync();

    // In a real app, you would connect to the step sensor here
    // For this implementation, we'll simulate step counting
    _startStepSimulation();

    return true;
  }

  // Load saved step count from SharedPreferences
  Future<void> _loadSavedSteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _steps = prefs.getInt('steps_$todayDate') ?? 0;

      // If no steps for today, initialize with a random number
      // This is just for demo purposes
      if (_steps == 0) {
        _steps = Random().nextInt(5000) + 2000; // Between 2000-7000 steps
      }

      _lastSavedSteps = _steps;

      final lastSyncTimeMillis = prefs.getInt('last_sync_time');
      if (lastSyncTimeMillis != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncTimeMillis);
      }

      if (kDebugMode) {
        print('📊 Loaded saved steps: $_steps (last sync: $_lastSyncTime)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading saved steps: $e');
      }
    }
  }

  // Save steps to SharedPreferences
  Future<void> _saveSteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await prefs.setInt('steps_$todayDate', _steps);

      // If we've accumulated enough new steps, sync to Firebase
      if (_steps - _lastSavedSteps >= 100) {
        await _syncStepsToFirebase();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving steps: $e');
      }
    }
  }

  // Start periodic sync to Firebase
  void _startPeriodicSync() {
    // Cancel any existing timer
    _syncTimer?.cancel();

    // Sync every 15 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _syncStepsToFirebase();
    });
  }

  // Start step simulation - ONLY FOR DEMO PURPOSES
  // In a real app, you would use device sensors
  void _startStepSimulation() {
    if (_isSimulating) return;
    _isSimulating = true;

    // Generate 5-15 steps every minute at random intervals
    _simulationTimer = Timer.periodic(const Duration(seconds: 15), (
      timer,
    ) async {
      if (Random().nextBool()) {
        // 50% chance of generating steps
        final newSteps = Random().nextInt(10) + 5; // 5-15 steps
        _steps += newSteps;

        if (kDebugMode) {
          print('👣 Simulated $newSteps new steps. Total: $_steps');
        }

        await _saveSteps();
      }
    });
  }

  void stopStepSimulation() {
    _simulationTimer?.cancel();
    _isSimulating = false;
  }

  // Sync steps to Firebase
  Future<void> _syncStepsToFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);

      // Update last sync time
      _lastSyncTime = now;
      _lastSavedSteps = _steps;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_sync_time',
        _lastSyncTime.millisecondsSinceEpoch,
      );

      // Reference to today's step document
      final stepDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fitness_data')
          .doc(today);

      // Get the current document if it exists
      final stepDoc = await stepDocRef.get();

      if (stepDoc.exists) {
        // Update existing document
        final data = stepDoc.data() as Map<String, dynamic>;
        final int currentSteps = data['steps'] ?? 0;

        // Only update if we have more steps
        if (_steps > currentSteps) {
          await stepDocRef.update({
            'steps': _steps,
            'lastUpdated': now.millisecondsSinceEpoch,
          });
        }
      } else {
        // Create new document for today
        await stepDocRef.set({
          'date': today,
          'steps': _steps,
          'target': 10000, // Default target
          'lastUpdated': now.millisecondsSinceEpoch,
        });
      }

      // Also update user's total stats
      await _updateUserTotalStats(user.uid, _steps);

      if (kDebugMode) {
        print('✅ Steps synced to Firebase: $_steps');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error syncing steps to Firebase: $e');
      }
    }
  }

  // Update user's total fitness stats
  Future<void> _updateUserTotalStats(String userId, int steps) async {
    try {
      final statsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('fitness');

      final statsDoc = await statsRef.get();

      if (statsDoc.exists) {
        final data = statsDoc.data() as Map<String, dynamic>;
        final int totalSteps = data['totalSteps'] ?? 0;

        // Only update if we have more steps
        if (steps > totalSteps) {
          await statsRef.update({
            'totalSteps': steps,
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          });
        }
      } else {
        // Create stats document if it doesn't exist
        await statsRef.set({
          'totalSteps': steps,
          'totalWorkouts': 0,
          'streakDays': 1,
          'bestStreak': 1,
          'created': DateTime.now().millisecondsSinceEpoch,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user stats: $e');
      }
    }
  }

  // Force a manual sync
  Future<bool> forceSync() async {
    try {
      // In a real app with sensors, you would update the step count here
      // For our simulator, we'll just add 20-30 random steps
      _steps += Random().nextInt(10) + 20;

      await _saveSteps();
      await _syncStepsToFirebase();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get step history for the past days
  Future<List<Map<String, dynamic>>> getStepHistory(int days) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final now = DateTime.now();
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('fitness_data')
              .where(
                'date',
                isGreaterThanOrEqualTo: DateFormat(
                  'yyyy-MM-dd',
                ).format(now.subtract(Duration(days: days))),
              )
              .orderBy('date', descending: true)
              .limit(days)
              .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting step history: $e');
      }
      return [];
    }
  }

  // Add steps manually - useful for testing or manual entry
  Future<void> addStepsManually(int additionalSteps) async {
    if (additionalSteps <= 0) return;

    _steps += additionalSteps;
    await _saveSteps();
    await _syncStepsToFirebase();
  }

  // Clean up resources
  void dispose() {
    _syncTimer?.cancel();
    _simulationTimer?.cancel();
    _isSimulating = false;
  }
}
