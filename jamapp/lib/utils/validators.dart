// Input validation utilities for forms and user inputs

class InputValidator {
  // Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  // Validate password strength
  static bool isValidPassword(String password) {
    // Minimum 8 characters, at least one letter and one number
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  // Validate username format
  static bool isValidUsername(String username) {
    // Alphanumeric and underscores, 3-15 characters
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,15}$');
    return usernameRegex.hasMatch(username);
  }

  // Validate age input
  static bool isValidAge(String age) {
    final ageRegex = RegExp(r'^\d+$');
    if (!ageRegex.hasMatch(age)) return false;
    final ageValue = int.tryParse(age);
    return ageValue != null && ageValue > 0 && ageValue < 120;
  }

  // Validate bio length
  static bool isValidBio(String bio) {
    return bio.length <= 150; // Maximum 150 characters
  }
}
