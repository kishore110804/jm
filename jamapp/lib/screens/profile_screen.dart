import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme_config.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final AuthService auth = AuthService();

    // If user is not authenticated, show login prompt
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Please sign in to view your profile',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textIvory,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text(
                'SIGN IN',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text(
                'Register a new account',
                style: GoogleFonts.poppins(color: ThemeConfig.primaryGreen),
              ),
            ),
          ],
        ),
      );
    }

    // If user is authenticated, show profile
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // User profile picture
          CircleAvatar(
            radius: 60,
            backgroundColor: ThemeConfig.primaryGreen,
            child: Icon(
              Icons.person,
              size: 80,
              color: ThemeConfig.backgroundBlack,
            ),
          ),
          const SizedBox(height: 20),
          // User email
          Text(
            user.email ?? 'Email not available',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: ThemeConfig.textIvory,
            ),
          ),
          const SizedBox(height: 40),
          // User information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildProfileItem(Icons.account_circle, 'Account Settings'),
                const Divider(color: Colors.grey),
                _buildProfileItem(Icons.notifications, 'Notifications'),
                const Divider(color: Colors.grey),
                _buildProfileItem(Icons.privacy_tip, 'Privacy'),
                const Divider(color: Colors.grey),
                _buildProfileItem(Icons.help, 'Help & Support'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Sign out button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await auth.signOut();
            },
            child: Text(
              'SIGN OUT',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: ThemeConfig.primaryGreen, size: 24),
          const SizedBox(width: 15),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: ThemeConfig.textIvory,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.arrow_forward_ios,
            color: ThemeConfig.textIvory,
            size: 16,
          ),
        ],
      ),
    );
  }
}
