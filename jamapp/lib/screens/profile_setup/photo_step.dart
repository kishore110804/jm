import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/theme_config.dart';

class PhotoStep extends StatefulWidget {
  final Function(String?) onComplete;

  const PhotoStep({super.key, required this.onComplete});

  @override
  State<PhotoStep> createState() => _PhotoStepState();
}

class _PhotoStepState extends State<PhotoStep> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    // Get current Google profile photo
    final photoURL = _auth.currentUser?.photoURL;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Your profile photo',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textIvory,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We\'re using your Google profile picture.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: ThemeConfig.textIvory.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                shape: BoxShape.circle,
                border: Border.all(color: ThemeConfig.primaryGreen, width: 2),
                image:
                    photoURL != null
                        ? DecorationImage(
                          image: NetworkImage(photoURL),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  photoURL == null
                      ? const Icon(
                        Icons.person,
                        color: ThemeConfig.primaryGreen,
                        size: 70,
                      )
                      : null,
            ),
          ),
          const Spacer(),
          Center(
            child:
                _loading
                    ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ThemeConfig.primaryGreen,
                      ),
                    )
                    : FloatingActionButton.extended(
                      backgroundColor: ThemeConfig.primaryGreen,
                      onPressed: () {
                        setState(() {
                          _loading = true;
                        });

                        try {
                          debugPrint(
                            '📸 Photo step completed - skipping photo URL',
                          );
                          // Don't pass photoURL to avoid Pigeon issues
                          widget.onComplete(null);
                        } catch (e) {
                          debugPrint('❌ Error in photo step: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                          setState(() {
                            _loading = false;
                          });
                        }
                      },
                      icon: const Icon(Icons.check, color: Colors.black),
                      label: Text(
                        'Continue',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
