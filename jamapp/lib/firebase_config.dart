import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

// Initialize Firebase with proper configuration
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Note: To properly fix the AppCheck warning, you would normally add:
    //
    // await FirebaseAppCheck.instance.activate(
    //   webRecaptchaSiteKey: 'your-recaptcha-key',
    //   androidProvider: kDebugMode
    //     ? AndroidProvider.debug
    //     : AndroidProvider.playIntegrity,
    // );
    //
    // However, this requires Firebase App Check to be set up in your project
    // and the firebase_app_check package to be added to pubspec.yaml.
    // The warning won't affect functionality - it's just a security recommendation.

    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }
}
