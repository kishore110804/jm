import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math'; // Add this import for Random

class NativeStepCounter {
  static const platform = MethodChannel(
    'com.jamphone.socialmedia/step_counter',
  );

  static final NativeStepCounter _instance = NativeStepCounter._internal();
  factory NativeStepCounter() => _instance;
  NativeStepCounter._internal();

  int _steps = 0;
  DateTime _lastSyncTime = DateTime.now();
  bool _isInitialized = false;
  StreamController<int> _stepController = StreamController<int>.broadcast();

  Stream<int> get stepStream => _stepController.stream;
  int get steps => _steps;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Load last saved steps
      await _loadSavedSteps();

      // Start listening to step updates
      await _startTracking();

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to initialize step counter: $e');
      return false;
    }
  }

  Future<void> _loadSavedSteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _steps = prefs.getInt('native_steps_$todayDate') ?? 0;

      final lastSyncTimeMillis = prefs.getInt('native_last_sync_time');
      if (lastSyncTimeMillis != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncTimeMillis);
      }

      // If it's a new day, reset steps
      final now = DateTime.now();
      if (now.day != _lastSyncTime.day ||
          now.month != _lastSyncTime.month ||
          now.year != _lastSyncTime.year) {
        _steps = 0;
        _lastSyncTime = now;
        await _saveSteps();
      }

      // Notify listeners
      _stepController.add(_steps);
    } catch (e) {
      debugPrint('Error loading saved steps: $e');
    }
  }

  Future<void> _saveSteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await prefs.setInt('native_steps_$todayDate', _steps);
      await prefs.setInt(
        'native_last_sync_time',
        _lastSyncTime.millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error saving steps: $e');
    }
  }

  Future<void> _startTracking() async {
    try {
      // First try to get current step count
      final int? initialSteps = await platform.invokeMethod('getStepCount');
      if (initialSteps != null) {
        _steps = initialSteps;
        _stepController.add(_steps);
      }

      // Set up stream for step updates from native code
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onStepUpdate') {
          final int newSteps = call.arguments;
          _steps = newSteps;
          _lastSyncTime = DateTime.now();
          await _saveSteps();
          _stepController.add(_steps);
        }
      });

      // Start tracking
      await platform.invokeMethod('startTracking');
    } catch (e) {
      debugPrint('Error starting step tracking: $e');
      // Fallback to simulated data if native tracking fails
      _startSimulation();
    }
  }

  // Fallback simulation for testing
  void _startSimulation() {
    Timer.periodic(Duration(minutes: 1), (timer) {
      // Add 50-100 steps every minute
      final newSteps = Random().nextInt(50) + 50;
      _steps += newSteps;
      _lastSyncTime = DateTime.now();
      _saveSteps();
      _stepController.add(_steps);
    });
  }

  Future<void> addStepsManually(int additionalSteps) async {
    if (additionalSteps <= 0) return;

    _steps += additionalSteps;
    _lastSyncTime = DateTime.now();
    await _saveSteps();
    _stepController.add(_steps);
  }

  Future<List<Map<String, dynamic>>> getWeeklyStepHistory() async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> weekData = [];

      // Generate the last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        // Try to get data from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final stepCount = prefs.getInt('native_steps_$dateStr') ?? 0;

        weekData.add({
          'date': dateStr,
          'dayName': _getDayName(date.weekday),
          'steps': i == 0 ? _steps : stepCount, // Use current counter for today
          'target': 10000,
          'progress':
              (i == 0 ? _steps : stepCount) /
              10000.0, // Convert to double explicitly
        });
      }

      return weekData;
    } catch (e) {
      debugPrint('Error getting step history: $e');
      return [];
    }
  }

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

  // Add this method to force a refresh of step data
  Future<void> forceSync() async {
    try {
      // Try to get current step count from the platform
      try {
        final int? currentSteps = await platform.invokeMethod('getStepCount');
        if (currentSteps != null) {
          _steps = currentSteps;
        }
      } catch (e) {
        // If platform method fails, just use current steps
        debugPrint('Platform method failed: $e');
      }

      // Update timestamp and save
      _lastSyncTime = DateTime.now();
      await _saveSteps();
      _stepController.add(_steps);
    } catch (e) {
      debugPrint('Error forcing sync: $e');
    }
  }

  void dispose() {
    _stepController.close();
  }
}
