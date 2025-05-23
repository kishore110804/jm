import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../utils/theme_config.dart';
import '../main_app_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSetupScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileSetupScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCheckingProfile = true;

  @override
  void initState() {
    super.initState();
    // Check if profile is complete and redirect if needed
    _checkProfileStatus();

    // Pre-fill with any existing data
    _nameController.text = widget.userData?['displayName'] ?? '';
  }

  Future<void> _checkProfileStatus() async {
    setState(() {
      _isCheckingProfile = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists && doc.data()?['profileComplete'] == true) {
          // Profile is complete, navigate to main app screen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainAppScreen()),
            );
          }
          return;
        }

        // Pre-fill data from Firestore if available
        if (doc.exists) {
          setState(() {
            _nameController.text = doc.data()?['displayName'] ?? '';
            _usernameController.text = doc.data()?['username'] ?? '';
            if (doc.data()?['age'] != null) {
              _ageController.text = doc.data()!['age'].toString();
            }
          });
        }
      }
    } catch (e) {
      print('Error checking profile status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting image: $e';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );

      String? photoURL = widget.userData?['photoURL'];

      // Upload profile image if selected
      if (_imageFile != null) {
        photoURL = await storageService.uploadProfileImage(
          _imageFile!.path,
          widget.userData?['uid'],
        );
      }

      // Update user profile with null-safe handling of photoURL
      await authService.updateUserProfile(
        name: _nameController.text,
        username: _usernameController.text,
        age: _ageController.text,
        photoURL:
            photoURL ?? '', // Use empty string as fallback if photoURL is null
      );

      if (mounted) {
        // Show profile completion screen
        _showProfileCompletedDialog();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save profile: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showProfileCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ThemeConfig.primaryGreen, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ThemeConfig.primaryGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: ThemeConfig.primaryGreen,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Profile Complete!',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.textIvory,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your profile has been successfully set up. You\'re all ready to start tracking your fitness journey!',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: ThemeConfig.textIvory.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pushReplacementNamed(
                        '/home',
                      ); // Use named route for consistency
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.primaryGreen,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Go to Home Page',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingProfile) {
      return Scaffold(
        backgroundColor: ThemeConfig.backgroundBlack,
        body: Center(
          child: CircularProgressIndicator(color: ThemeConfig.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false, // Prevent going back to auth screen
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Profile image
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[800],
                        backgroundImage:
                            _imageFile != null
                                ? FileImage(_imageFile!)
                                : (widget.userData?['photoURL'] != null
                                    ? NetworkImage(widget.userData!['photoURL'])
                                        as ImageProvider
                                    : null),
                        child:
                            (_imageFile == null &&
                                    widget.userData?['photoURL'] == null)
                                ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: ThemeConfig.primaryGreen,
                                )
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ThemeConfig.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: ThemeConfig.textIvory),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.person,
                      color: ThemeConfig.primaryGreen,
                    ),
                  ),
                  style: const TextStyle(color: ThemeConfig.textIvory),
                  validator:
                      (value) =>
                          (value?.isEmpty ?? true)
                              ? 'Please enter your name'
                              : null,
                ),
                const SizedBox(height: 16),

                // Username field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: const TextStyle(color: ThemeConfig.textIvory),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.alternate_email,
                      color: ThemeConfig.primaryGreen,
                    ),
                  ),
                  style: const TextStyle(color: ThemeConfig.textIvory),
                  validator:
                      (value) =>
                          (value?.isEmpty ?? true)
                              ? 'Please choose a username'
                              : null,
                ),
                const SizedBox(height: 16),

                // Age field
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    labelStyle: const TextStyle(color: ThemeConfig.textIvory),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.cake,
                      color: ThemeConfig.primaryGreen,
                    ),
                  ),
                  style: const TextStyle(color: ThemeConfig.textIvory),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Age is optional
                    }

                    final age = int.tryParse(value);
                    if (age == null || age <= 0 || age > 120) {
                      return 'Please enter a valid age';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Save button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: ThemeConfig.primaryGreen,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                          : const Text(
                            'Save Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),

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
