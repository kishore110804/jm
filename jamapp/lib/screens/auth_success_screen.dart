import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthSuccessScreen extends StatefulWidget {
  const AuthSuccessScreen({Key? key}) : super(key: key);

  @override
  State<AuthSuccessScreen> createState() => _AuthSuccessScreenState();
}

class _AuthSuccessScreenState extends State<AuthSuccessScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Automatically go to home screen after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacementNamed('/home');
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Success icon
                const Icon(
                  Icons.check_circle_outline,
                  color: ThemeConfig.primaryGreen,
                  size: 100,
                ),
                const SizedBox(height: 30),

                // Welcome message
                Text(
                  'Welcome${user?.displayName != null ? ", ${user!.displayName}" : ""}!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ThemeConfig.textIvory,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Success message
                Text(
                  'You have successfully signed in',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: ThemeConfig.textIvory.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Loading indicator
                const CircularProgressIndicator(
                  color: ThemeConfig.primaryGreen,
                ),
                const SizedBox(height: 16),

                // Info text
                Text(
                  'Redirecting to the app...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ThemeConfig.textIvory.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
