// Performs security checks on authentication attempts and monitors for suspicious activities
// This file is intended to enhance security measures for authentication processes.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class SecurityService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Monitor authentication attempts for suspicious activities
  Future<void> monitorAuthAttempts(String operation, dynamic error) async {
    try {
      final user = _auth.currentUser;
      final uid = user?.uid ?? 'unknown_user';
      final timestamp = DateTime.now().toIso8601String();

      final logData = {
        'operation': operation,
        'error': error.toString(),
        'uid': uid,
        'timestamp': timestamp,
        'platform': 'flutter',
      };

      await _firestore.collection('auth_logs').add(logData);
    } catch (e) {
      // Log failure silently
      print('Failed to log authentication attempt: $e');
    }
  }

  // Generate a random nonce for security purposes
  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // SHA256 hash for nonce
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Store security-related data securely
  Future<void> storeSecurityData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      print('Failed to store security data: $e');
    }
  }

  // Retrieve security-related data securely
  Future<String?> retrieveSecurityData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      print('Failed to retrieve security data: $e');
      return null;
    }
  }
}
