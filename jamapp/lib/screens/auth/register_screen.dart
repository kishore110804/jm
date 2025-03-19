import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/theme_config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  String email = '';
  String password = '';
  String confirmPassword = '';
  String error = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Register',
          style: GoogleFonts.poppins(
            color: ThemeConfig.textIvory,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              TextFormField(
                style: const TextStyle(color: ThemeConfig.textIvory),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: ThemeConfig.textIvory),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ThemeConfig.textIvory),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ThemeConfig.primaryGreen),
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
                  labelStyle: const TextStyle(color: ThemeConfig.textIvory),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ThemeConfig.textIvory),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ThemeConfig.primaryGreen),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (val) => val!.length < 6 ? 'Password must be 6+ characters' : null,
                onChanged: (val) {
                  setState(() => password = val);
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                style: const TextStyle(color: ThemeConfig.textIvory),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: const TextStyle(color: ThemeConfig.textIvory),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ThemeConfig.textIvory),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ThemeConfig.primaryGreen),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (val) => val != password ? 'Passwords don\'t match' : null,
                onChanged: (val) {
                  setState(() => confirmPassword = val);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => loading = true);
                    
                    var result = await _auth.registerWithEmailAndPassword(email, password);
                    if (result == null) {
                      setState(() {
                        error = 'Please supply a valid email';
                        loading = false;
                      });
                    } else {
                      Navigator.of(context).pop(); // Go back to profile screen after registration
                    }
                  }
                },
                child: Text(
                  'REGISTER',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
