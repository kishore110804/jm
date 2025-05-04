import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Add this import
import '../utils/theme_config.dart'; // Add this import
import '../services/health_service.dart';

class HealthProvider extends ChangeNotifier {
  final HealthService _healthService = HealthService();

  // Health data
  int _steps = 0;
  int _calories = 0;
  double _distance = 0.0;
  int _target = 10000;
  bool _isAuthorized = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _weeklyData = [];

  // Getters
  int get steps => _steps;
  int get calories => _calories;
  double get distance => _distance;
  int get target => _target;
  bool get isAuthorized => _isAuthorized;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get weeklyData => _weeklyData;
  double get progress => _steps / _target;

  // Initialize provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Initialize health service
    await _healthService.initialize();

    // Check authorization
    _isAuthorized = await _healthService.isAuthorized();

    // If authorized, load data
    if (_isAuthorized) {
      await refreshData();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Request authorization
  Future<bool> requestAuthorization() async {
    _isLoading = true;
    notifyListeners();

    _isAuthorized = await _healthService.requestAuthorization();

    if (_isAuthorized) {
      await refreshData();
    }

    _isLoading = false;
    notifyListeners();

    return _isAuthorized;
  }

  // Refresh all health data
  Future<void> refreshData() async {
    if (!_isAuthorized) return;

    _isLoading = true;
    notifyListeners();

    // Get current health data
    final healthData = await _healthService.getCurrentHealthData();
    _steps = healthData['steps'];
    _calories = healthData['calories'];
    _distance = healthData['distance'];

    // Get step target
    _target = await _healthService.getStepTarget();

    // Sync to Firebase
    await _healthService.syncHealthData();

    // Get weekly data
    _weeklyData = await _healthService.getWeeklyStepHistory();

    _isLoading = false;
    notifyListeners();
  }

  // Add steps manually (for testing)
  Future<void> addSteps(int additionalSteps) async {
    if (!_isAuthorized || additionalSteps <= 0) return;

    await _healthService.addStepsManually(additionalSteps);
    await refreshData();
  }

  // Update step target
  Future<bool> updateStepTarget(int newTarget) async {
    if (!_isAuthorized) return false;

    final success = await _healthService.updateStepTarget(newTarget);
    if (success) {
      _target = newTarget;
      notifyListeners();
    }

    return success;
  }

  // Get friend comparisons
  Future<List<Map<String, dynamic>>> getFriendsComparison() async {
    if (!_isAuthorized) return [];
    return _healthService.getFriendsComparison();
  }

  // Show dialog for manual step entry
  Future<void> showManualEntryDialog(BuildContext context) async {
    int? stepsToAdd;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Add Steps Manually',
              style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter the number of steps to add:',
                  style: GoogleFonts.poppins(
                    color: ThemeConfig.textIvory.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: ThemeConfig.primaryGreen,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'e.g. 500',
                    hintStyle: TextStyle(
                      color: ThemeConfig.textIvory.withOpacity(0.4),
                    ),
                  ),
                  onChanged: (value) {
                    stepsToAdd = int.tryParse(value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, stepsToAdd);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.primaryGreen,
                  foregroundColor: Colors.black,
                ),
                child: Text('Add Steps', style: GoogleFonts.poppins()),
              ),
            ],
          ),
    ).then((value) async {
      if (value != null && value > 0) {
        await addSteps(value);
      }
    });
  }
}
