import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme_config.dart';

class SimpleAuthScreen extends StatefulWidget {
  const SimpleAuthScreen({Key? key}) : super(key: key);

  @override
  State<SimpleAuthScreen> createState() => _SimpleAuthScreenState();
}

class _SimpleAuthScreenState extends State<SimpleAuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  // Initialize Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Handle Google Sign In
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Trigger Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() {
          _errorMessage = 'Sign in was cancelled';
          _isLoading = false;
        });
        return;
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credentials
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Create user profile in Firestore
        await _createUserProfile(userCredential.user!);
      }

      // Navigate to profile setup screen instead of auth success
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/profile_setup');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Sign in failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName ?? 'User',
      'photoURL': user.photoURL,
      'createdAt': Timestamp.now(),
      'profileComplete':
          false, // Add this flag to track profile completion status
      'stats': {'steps': 0, 'calories': 0, 'distance': 0.0, 'workouts': 0},
      'dailyGoals': {'steps': 10000, 'water': 8, 'sleep': 8},
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/app name
                Center(
                  child: Text(
                    'JamSync',
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tagline
                Center(
                  child: Text(
                    'Your fitness journey starts here',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: ThemeConfig.textIvory,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 60),

                // Google sign in button
                SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.g_translate_rounded,
                      color: Colors.black,
                      size: 24,
                    ),
                    label: Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // Loading indicator
                if (_isLoading) ...[
                  const SizedBox(height: 30),
                  const Center(
                    child: CircularProgressIndicator(
                      color: ThemeConfig.primaryGreen,
                    ),
                  ),
                ],

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
