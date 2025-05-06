import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PairingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a random 6-digit pairing code
  String _generatePairingCode() {
    final Random random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }

  // Create a new pairing code for the current user
  Future<Map<String, dynamic>> generatePairingCode() async {
    try {
      // Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Generate a new code
      final String code = _generatePairingCode();

      // Set expiration time (5 minutes from now)
      final expiryTime = DateTime.now().add(const Duration(minutes: 5));
      final expiryTimestamp = Timestamp.fromDate(expiryTime);

      // First check if user already has a pairing code
      final existingCodeQuery =
          await _firestore
              .collection('pairing_codes')
              .where('userId', isEqualTo: user.uid)
              .get();

      // Delete old codes if they exist
      for (var doc in existingCodeQuery.docs) {
        await doc.reference.delete();
      }

      // Store the new code in Firestore
      await _firestore.collection('pairing_codes').add({
        'code': code,
        'userId': user.uid,
        'expiryTime': expiryTimestamp,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'code': code, 'expiryTime': expiryTime};
    } catch (e) {
      print('Error generating pairing code: $e');
      throw e;
    }
  }

  // Check if a pairing code is valid
  Future<bool> validatePairingCode(String code) async {
    try {
      final now = DateTime.now();

      final codeQuery =
          await _firestore
              .collection('pairing_codes')
              .where('code', isEqualTo: code)
              .get();

      if (codeQuery.docs.isEmpty) return false;

      final codeDoc = codeQuery.docs.first;
      final expiryTime = (codeDoc.data()['expiryTime'] as Timestamp).toDate();

      // Check if code is still valid
      return now.isBefore(expiryTime);
    } catch (e) {
      print('Error validating pairing code: $e');
      return false;
    }
  }

  // Cleanup expired codes - this would be called periodically or on app start
  Future<void> cleanupExpiredCodes() async {
    try {
      final now = Timestamp.fromDate(DateTime.now());

      final expiredCodesQuery =
          await _firestore
              .collection('pairing_codes')
              .where('expiryTime', isLessThan: now)
              .get();

      for (var doc in expiredCodesQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error cleaning up expired codes: $e');
    }
  }
}
