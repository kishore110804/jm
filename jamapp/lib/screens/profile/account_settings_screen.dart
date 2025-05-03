import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../utils/theme_config.dart';
import '../../widgets/confirm_dialog.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  String? _displayName;
  String? _email;
  String? _photoURL;
  String? _username;
  String? _bio;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _imageFile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final userData = await _authService.getUserProfile();

      if (userData != null) {
        setState(() {
          _displayName = userData['displayName'];
          _email = userData['email'];
          _photoURL = userData['photoURL'];
          _username = userData['username'];
          _bio = userData['bio'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile data: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      String? photoURL = _photoURL;

      // Upload new image if selected
      if (_imageFile != null) {
        photoURL = await _storageService.uploadProfileImage(
          _imageFile!.path,
          FirebaseAuth.instance.currentUser!.uid,
        );
      }

      // Update profile in Firestore
      await _authService.updateUserProfile(
        name: _displayName ?? '',
        username: _username ?? '',
        bio: _bio,
        photoURL: photoURL,
      );

      // Update Firebase Auth display name
      await FirebaseAuth.instance.currentUser?.updateDisplayName(_displayName);

      // If email was changed, handle email update separately
      final currentEmail = FirebaseAuth.instance.currentUser?.email;
      if (_email != null && _email!.isNotEmpty && _email != currentEmail) {
        await _showEmailChangeConfirmation();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile: $e';
      });
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _showEmailChangeConfirmation() async {
    final shouldProceed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => ConfirmDialog(
                title: 'Update Email',
                content:
                    'To change your email, you will need to re-authenticate. Would you like to proceed?',
                confirmText: 'Proceed',
                cancelText: 'Cancel',
              ),
        ) ??
        false;

    if (shouldProceed && mounted) {
      Navigator.pushNamed(context, '/update_email', arguments: _email);
    }
  }

  Future<void> _deleteAccount() async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => ConfirmDialog(
                title: 'Delete Account',
                content:
                    'This will permanently delete your account and all associated data. This action cannot be undone. Are you sure?',
                confirmText: 'Delete Account',
                cancelText: 'Cancel',
                isDestructive: true,
              ),
        ) ??
        false;

    if (shouldDelete) {
      try {
        setState(() => _isLoading = true);
        await _authService.deleteAccount();

        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to delete account: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ThemeConfig.backgroundBlack,
        appBar: AppBar(
          title: Text(
            'Account Settings',
            style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: ThemeConfig.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Account Settings',
          style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: ThemeConfig.primaryGreen),
            onPressed: _isSaving ? null : _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                              : (_photoURL != null && _photoURL!.isNotEmpty
                                  ? NetworkImage(_photoURL!) as ImageProvider
                                  : null),
                      child:
                          (_photoURL == null || _photoURL!.isEmpty) &&
                                  _imageFile == null
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

              const SizedBox(height: 30),

              // Display name field
              TextFormField(
                initialValue: _displayName,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  labelStyle: const TextStyle(color: ThemeConfig.textIvory),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ThemeConfig.textIvory),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: ThemeConfig.primaryGreen,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: const TextStyle(color: ThemeConfig.textIvory),
                validator:
                    (value) =>
                        (value?.isEmpty ?? true)
                            ? 'Display name is required'
                            : null,
                onSaved: (value) => _displayName = value,
              ),

              const SizedBox(height: 16),

              // Username field
              TextFormField(
                initialValue: _username,
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: const TextStyle(color: ThemeConfig.textIvory),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ThemeConfig.textIvory),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: ThemeConfig.primaryGreen,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: const TextStyle(color: ThemeConfig.textIvory),
                validator:
                    (value) =>
                        (value?.isEmpty ?? true)
                            ? 'Username is required'
                            : null,
                onSaved: (value) => _username = value,
              ),

              const SizedBox(height: 16),

              // Email field
              TextFormField(
                initialValue: _email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: ThemeConfig.textIvory),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ThemeConfig.textIvory),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: ThemeConfig.primaryGreen,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: const Icon(
                    Icons.edit,
                    color: ThemeConfig.primaryGreen,
                  ),
                ),
                style: const TextStyle(color: ThemeConfig.textIvory),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) => _email = value,
              ),

              const SizedBox(height: 16),

              // Bio field
              TextFormField(
                initialValue: _bio,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  labelStyle: const TextStyle(color: ThemeConfig.textIvory),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ThemeConfig.textIvory),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: ThemeConfig.primaryGreen,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: const TextStyle(color: ThemeConfig.textIvory),
                maxLines: 3,
                onSaved: (value) => _bio = value,
              ),

              const SizedBox(height: 30),

              // Password change button
              OutlinedButton(
                onPressed:
                    () => Navigator.pushNamed(context, '/change_password'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ThemeConfig.primaryGreen),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Change Password',
                  style: GoogleFonts.poppins(
                    color: ThemeConfig.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Delete account button
              OutlinedButton(
                onPressed: _deleteAccount,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Delete Account',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
