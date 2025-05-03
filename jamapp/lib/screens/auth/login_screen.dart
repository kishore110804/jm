import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../utils/theme_config.dart';
import '../../debug/firebase_debug_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Handles user login interface and authentication flow
class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String error = '';
  bool loading = false;
  bool googleLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      googleLoading = true;
      error = '';
    });

    // Run diagnostic check first
    bool isConfigured = await _checkGoogleAuthSetup();
    if (!isConfigured) {
      setState(() {
        error =
            'Google Sign-In is not configured correctly. Check Firebase setup.';
        googleLoading = false;
      });
      return;
    }

    try {
      // Get the Google account first
      final googleAccount = await _auth.getGoogleAccount();

      if (googleAccount == null) {
        setState(() {
          error = 'Google sign in was cancelled';
          googleLoading = false;
        });
        return;
      }

      // Check if user exists
      final userEmail = googleAccount.email;
      final userExists = await _auth.userExists(userEmail);

      if (!userExists) {
        // New user - navigate to registration/profile setup
        setState(() {
          googleLoading = false;
        });
        if (mounted) {
          // Pass Google account data to registration screen
          Navigator.pushReplacementNamed(
            context,
            '/register',
            arguments: {
              'email': userEmail,
              'displayName': googleAccount.displayName,
              'photoURL': googleAccount.photoUrl,
              'googleAccount': googleAccount,
            },
          );
        }
        return;
      }

      // Existing user - complete Google sign in
      var result = await _auth.signInWithGoogle();

      if (!result['success']) {
        setState(() {
          error = result['message'] ?? 'Could not sign in with Google';
          googleLoading = false;
        });
        return;
      }

      // For watch compatibility, store authentication state
      try {
        // Store auth info in secure storage for potential watch access
        await _storeAuthInfo(result['user']);
      } catch (storageError) {
        // Non-critical error, continue with flow
        debugPrint('Warning: Could not store auth info: $storageError');
      }

      // Check if profile setup is needed
      try {
        bool profileComplete = await _auth.isProfileComplete();
        if (!profileComplete) {
          // Navigate to profile setup
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/profile_setup');
          }
        } else {
          // Go back to profile screen
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (profileError) {
        // If profile check fails, just go to profile setup to be safe
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/profile_setup');
        }
      }
    } catch (e) {
      String errorMessage = 'Error signing in with Google';

      if (e.toString().contains('unimplemented') ||
          e.toString().contains('not been implemented')) {
        errorMessage = 'Google Sign In is not fully supported on this device';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection';
      } else if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled')) {
        errorMessage = 'Google Sign In was cancelled';
      }

      setState(() {
        error = errorMessage;
        googleLoading = false;
      });
    }
  }

  // Check if Google Auth is properly configured
  Future<bool> _checkGoogleAuthSetup() async {
    try {
      // Check Firebase initialization
      if (!FirebaseAuth.instance.app.isAutomaticDataCollectionEnabled) {
        FirebaseAuth.instance.app.setAutomaticDataCollectionEnabled(true);
      }

      // Check package name in debug panel
      String packageName = await _getPackageName();
      debugPrint('📱 App package name: $packageName');

      // Check if google-services.json is properly loaded
      bool hasGoogleServices = await _checkGoogleServicesJson();
      debugPrint('🔑 Google Services JSON loaded: $hasGoogleServices');

      // If we get to this point without exceptions, basic setup is ok
      return true;
    } catch (e) {
      debugPrint('❌ Auth configuration error: $e');
      return false;
    }
  }

  // Get current package name
  Future<String> _getPackageName() async {
    if (Platform.isAndroid) {
      var packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.packageName;
    }
    return 'unknown';
  }

  // Check if google-services.json is properly loaded
  Future<bool> _checkGoogleServicesJson() async {
    try {
      // A simple way to check is to try to get project ID
      // This will fail if google-services.json isn't properly loaded
      final projectId = FirebaseAuth.instance.app.options.projectId;
      return projectId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Store authentication info for watch access
  Future<void> _storeAuthInfo(User? user) async {
    if (user == null) return;

    // You'll need to implement this method in your auth service
    // This is just a placeholder
    await _auth.storeAuthToken();
  }

  Future<void> _signInWithEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        loading = true;
        error = '';
      });

      try {
        var result = await _auth.signInWithEmailAndPassword(email, password);

        if (!result['success']) {
          setState(() {
            error =
                result['message'] ?? 'Could not sign in with those credentials';
            loading = false;
          });
          return;
        }

        // Check if profile setup is needed
        bool profileComplete = await _auth.isProfileComplete();
        if (!profileComplete) {
          // Navigate to profile setup
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/profile_setup');
          }
        } else {
          // Go back to profile screen
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        setState(() {
          error = 'An unexpected error occurred: $e';
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Sign In',
          style: GoogleFonts.poppins(
            color: ThemeConfig.textIvory,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          height:
              MediaQuery.of(context).size.height -
              AppBar().preferredSize.height -
              MediaQuery.of(context).padding.top,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[900],
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 70,
                    color: ThemeConfig.primaryGreen,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome Back',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ThemeConfig.textIvory,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign in to continue',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: ThemeConfig.textIvory.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  style: const TextStyle(color: ThemeConfig.textIvory),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(
                      Icons.email,
                      color: ThemeConfig.textIvory,
                    ),
                    labelStyle: const TextStyle(color: ThemeConfig.textIvory),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: ThemeConfig.textIvory,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: ThemeConfig.primaryGreen,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                  onChanged: (val) {
                    setState(() => email = val);
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  style: const TextStyle(color: ThemeConfig.textIvory),
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: ThemeConfig.textIvory,
                    ),
                    labelStyle: const TextStyle(color: ThemeConfig.textIvory),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: ThemeConfig.textIvory,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: ThemeConfig.primaryGreen,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator:
                      (val) =>
                          val!.length < 6
                              ? 'Password must be 6+ characters'
                              : null,
                  onChanged: (val) {
                    setState(() => password = val);
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: loading ? null : _signInWithEmail,
                    child:
                        loading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 3,
                              ),
                            )
                            : Text(
                              'SIGN IN',
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: ThemeConfig.textIvory.withOpacity(0.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR',
                        style: GoogleFonts.poppins(
                          color: ThemeConfig.textIvory.withOpacity(0.7),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: ThemeConfig.textIvory.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon:
                        googleLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: ThemeConfig.textIvory,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(
                              Icons.g_mobiledata,
                              size: 30,
                              color: ThemeConfig.textIvory,
                            ),
                    label: Text(
                      'Continue with Google',
                      style: GoogleFonts.poppins(
                        color: ThemeConfig.textIvory,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: ThemeConfig.textIvory.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: googleLoading ? null : _signInWithGoogle,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        'Register',
                        style: GoogleFonts.poppins(
                          color: ThemeConfig.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                // Error message
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      error,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Debug panel at the bottom
                const SizedBox(height: 20),
                FirebaseDebugHelper.buildDebugPanel(),

                // Auth diagnostic button (only in debug mode)
                if (kDebugMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TextButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Running auth diagnostics...'),
                            duration: Duration(seconds: 1),
                          ),
                        );

                        bool isConfigured = await _checkGoogleAuthSetup();

                        String message =
                            isConfigured
                                ? 'Google Auth configuration looks good!'
                                : 'Google Auth configuration issues detected. Check logs.';

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor:
                                isConfigured ? Colors.green : Colors.red,
                          ),
                        );
                      },
                      child: Text(
                        'Diagnose Auth Setup',
                        style: GoogleFonts.poppins(
                          color: ThemeConfig.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
