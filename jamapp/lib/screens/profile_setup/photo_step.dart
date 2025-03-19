import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/theme_config.dart';

class PhotoStep extends StatefulWidget {
  final Function(String?) onComplete;

  const PhotoStep({super.key, required this.onComplete});

  @override
  State<PhotoStep> createState() => _PhotoStepState();
}

class _PhotoStepState extends State<PhotoStep> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _uploading = false;
  
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      // No image to upload, just complete
      widget.onComplete(null);
      return;
    }
    
    setState(() {
      _uploading = true;
    });
    
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${currentUser.uid}.jpg');
      
      await storageRef.putFile(_imageFile!);
      final String downloadURL = await storageRef.getDownloadURL();
      
      widget.onComplete(downloadURL);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      setState(() {
        _uploading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Add a profile photo',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textIvory,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'This helps people recognize you.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: ThemeConfig.textIvory.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  shape: BoxShape.circle,
                  border: Border.all(color: ThemeConfig.primaryGreen, width: 2),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            color: ThemeConfig.primaryGreen,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add Photo',
                            style: GoogleFonts.poppins(
                              color: ThemeConfig.textIvory,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _uploading 
                    ? null 
                    : () {
                        widget.onComplete(null); // Skip this step
                      },
                child: Text(
                  'Skip',
                  style: GoogleFonts.poppins(
                    color: ThemeConfig.textIvory.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ),
              _uploading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.primaryGreen),
                    )
                  : FloatingActionButton(
                      backgroundColor: ThemeConfig.primaryGreen,
                      onPressed: _uploadImage,
                      child: const Icon(Icons.check, color: Colors.black),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
