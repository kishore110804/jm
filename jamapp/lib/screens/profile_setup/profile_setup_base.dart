import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Replace AuthService
import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore
import '../../utils/theme_config.dart';
import 'name_step.dart';
import 'username_step.dart';
import 'age_step.dart';
import 'photo_step.dart';

class ProfileSetupBase extends StatefulWidget {
  const ProfileSetupBase({super.key});

  @override
  State<ProfileSetupBase> createState() => _ProfileSetupBaseState();
}

class _ProfileSetupBaseState extends State<ProfileSetupBase> {
  final PageController _pageController = PageController(initialPage: 0);
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Use Firebase Auth directly
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Use Firestore
  int _currentPage = 0;
  String _name = '';
  String _username = '';
  String? _age;
  String? _photoURL;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.add(
      NameStep(
        onNext: (name) {
          setState(() {
            _name = name;
          });
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );

    _pages.add(
      UsernameStep(
        onNext: (username) {
          setState(() {
            _username = username;
          });
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );

    _pages.add(
      AgeStep(
        onNext: (age) {
          setState(() {
            _age = age;
          });
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );

    _pages.add(
      PhotoStep(
        onComplete: (photoURL) async {
          setState(() {
            _photoURL = photoURL;
          });

          // Save all profile data
          try {
            await _updateUserProfile(
              name: _name,
              username: _username,
              age: _age,
              photoURL: _photoURL,
            );

            // Navigate back to home page
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error saving profile: $e',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Update user profile with error handling for PigeonUserInfo issues
  Future<void> _updateUserProfile({
    required String name,
    required String username,
    String? age,
    String? photoURL,
  }) async {
    debugPrint('🔍 Starting to update user profile');

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ Error: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('👤 Current User: ${currentUser.uid}');

      // Create a safe, simple data object with only primitive types
      final Map<String, dynamic> updateData = {
        'name': name,
        'username': username,
        'profileComplete': true,
        'updatedAt':
            FieldValue.serverTimestamp(), // Use server timestamp to avoid Pigeon issues
      };

      // Only add optional fields if they're provided and non-null
      if (age != null && age.isNotEmpty) updateData['age'] = age;

      debugPrint('📝 Update data: $updateData');

      // Use set with merge option instead of update to handle both new and existing documents
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(updateData, SetOptions(merge: true));

      debugPrint('✅ Firestore update successful');

      // Update Firebase Auth display name only - wrap in try-catch to isolate potential errors
      try {
        await currentUser.updateDisplayName(name);
        debugPrint('✅ Firebase Auth displayName updated');
      } catch (authUpdateError) {
        debugPrint(
          '⚠️ Could not update Auth profile, but Firestore updated: $authUpdateError',
        );
      }

      debugPrint('✅ Profile update completed successfully');

      // Navigation should happen outside this method
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      // Convert the error to a simpler format to avoid Pigeon issues
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        leading:
            _currentPage > 0
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                )
                : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / _pages.length,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(
              ThemeConfig.primaryGreen,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}
