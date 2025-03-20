import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // Keys for preferences
  static const String _appModeKey = 'app_mode';

  // App modes
  static const String fitnessFocusMode = 'fitness_focus';
  static const String networkingFocusMode = 'networking_focus';

  // Default app mode
  static const String defaultMode = fitnessFocusMode;

  // Get the current app mode
  static Future<String> getAppMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_appModeKey) ?? defaultMode;
  }

  // Set the app mode
  static Future<bool> setAppMode(String mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_appModeKey, mode);
  }
}
