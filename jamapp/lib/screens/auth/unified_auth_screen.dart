import 'package:flutter/material.dart';
import 'dart:io';

import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme_config.dart';
import '../profile/profile_setup_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class UnifiedAuthScreen extends StatefulWidget {
  const UnifiedAuthScreen({Key? key}) : super(key: key);

  @override
  State<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends State<UnifiedAuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  // Handle Google Sign In process with improved reliability
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Simplified Google Sign In flow
      final result = await authService.signInWithGoogle();

      if (result['success']) {
        // Check if this is a new user
        if (result['isNewUser']) {
          if (mounted) {
            // Navigate to profile setup
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) => ProfileSetupScreen(userData: result['user']),
              ),
            );
          }
        } else {
          // Check if profile is complete
          final isProfileComplete = await authService.isProfileComplete();

          if (mounted) {
            if (!isProfileComplete) {
              // Profile incomplete - go to setup
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder:
                      (context) => ProfileSetupScreen(userData: result['user']),
                ),
              );
            } else {
              // Profile complete - go to home
              Navigator.of(context).pushReplacementNamed('/home');
            }
          }
        }
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle Email/Password sign in
  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check for internet connection first
      final hasConnection = await _checkInternetConnection();
      if (!hasConnection) {
        setState(() {
          _errorMessage =
              'No internet connection. Please check your network settings.';
          _isLoading = false;
        });
        return;
      }

      final authService = Provider.of<AuthService>(context, listen: false);

      // First check if user exists
      final userExists = await authService.userExists(_emailController.text);

      Map<String, dynamic> result;

      if (userExists) {
        // Sign in existing user
        result = await authService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        // Register new user
        result = await authService.registerWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
      }

      if (result['success']) {
        // For new registrations or incomplete profiles
        if (!userExists || !(await authService.isProfileComplete())) {
          if (mounted) {
            // Navigate to profile setup
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) => ProfileSetupScreen(userData: result['user']),
              ),
            );
          }
        } else {
          // Existing user with complete profile
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48, // 48 for padding
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // App logo/name
                    Center(
                      child: Text(
                        'JamApp',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
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
                    const SizedBox(height: 40),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(
                          color: ThemeConfig.textIvory.withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.email,
                          color: ThemeConfig.primaryGreen,
                        ),
                      ),
                      style: const TextStyle(color: ThemeConfig.textIvory),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: ThemeConfig.textIvory.withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: ThemeConfig.primaryGreen,
                        ),
                      ),
                      style: const TextStyle(color: ThemeConfig.textIvory),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),

                    // Sign in with email button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithEmail,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: ThemeConfig.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: ThemeConfig.primaryGreen
                              .withOpacity(0.5),
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
                                  'Continue with Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: ThemeConfig.textIvory.withOpacity(0.4),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: ThemeConfig.textIvory.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: ThemeConfig.textIvory.withOpacity(0.4),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google sign in button with more reliable icon
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.account_circle,
                          color: ThemeConfig.textIvory,
                          size: 24,
                        ),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: ThemeConfig.textIvory,
                          ),
                        ),
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: ThemeConfig.textIvory),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method to get Google logo or fallback icon
  Widget _getGoogleLogo() {
    // Always return a fallback icon since the asset is missing
    return const Icon(
      Icons.g_mobiledata, // Use Google-like icon from material icons
      color: Colors.white,
      size: 24,
    );
  }
}
