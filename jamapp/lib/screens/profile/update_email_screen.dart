// Allows users to update their email addresses with verification
import 'package:firebase_auth/firebase_auth.dart';

class EmailUpdateService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> updateEmail(String newEmail) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      await currentUser.updateEmail(newEmail);
      await currentUser.sendEmailVerification();

      return {
        'success': true,
        'message': 'Email updated successfully. Please verify your new email.',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'requires-recent-login':
          message = 'Please sign in again to update your email';
          break;
        default:
          message = 'Failed to update email: ${e.message}';
      }

      return {'success': false, 'message': message, 'error': e};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e,
      };
    }
  }
}
