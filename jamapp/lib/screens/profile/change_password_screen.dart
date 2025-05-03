// Interface for changing user passwords securely
import 'package:firebase_auth/firebase_auth.dart';

class PasswordService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Change user password
  Future<Map<String, dynamic>> changePassword(String newPassword) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      await currentUser.updatePassword(newPassword);

      return {'success': true, 'message': 'Password updated successfully'};
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'requires-recent-login':
          message =
              'Please log in again before attempting to change your password.';
          break;
        default:
          message = 'An error occurred: ${e.message}';
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
