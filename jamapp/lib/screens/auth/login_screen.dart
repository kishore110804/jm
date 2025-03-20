import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/theme_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

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

    try {
      var result = await _auth.signInWithGoogle();
      if (result == null) {
        setState(() {
          error = 'Could not sign in with Google';
          googleLoading = false;
        });
      } else {
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
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        googleLoading = false;
      });
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
                    onPressed:
                        loading
                            ? null
                            : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  loading = true;
                                  error = '';
                                });

                                var result = await _auth
                                    .signInWithEmailAndPassword(
                                      email,
                                      password,
                                    );
                                if (result == null) {
                                  setState(() {
                                    error =
                                        'Could not sign in with those credentials';
                                    loading = false;
                                  });
                                } else {
                                  // Check if profile setup is needed
                                  bool profileComplete =
                                      await _auth.isProfileComplete();
                                  if (!profileComplete) {
                                    // Navigate to profile setup
                                    if (mounted) {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/profile_setup',
                                      );
                                    }
                                  } else {
                                    // Go back to profile screen
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                }
                              }
                            },
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
