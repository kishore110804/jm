import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/theme_config.dart';

class FirebaseDebugHelper {
  static Widget buildDebugPanel() {
    // Only show in debug mode
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔥 Firebase Debug Helper',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'To fix Google Sign In issues:',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            '1. Missing google-services.json file',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            '   - Create a Firebase project at firebase.google.com',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const Text(
            '   - Register your Android app with package name from AndroidManifest.xml',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const Text(
            '   - Download google-services.json to android/app/',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text(
            '2. SHA-1 fingerprint missing in Firebase Console',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(8),
            color: Colors.black,
            child: const Text(
              'cd android\n./gradlew signingReport',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.primaryGreen,
              minimumSize: const Size(double.infinity, 36),
            ),
            child: const Text(
              'Fix Authentication Issues',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
