import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore
import '../../utils/theme_config.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      appBar: AppBar(
        title: const Text('JamSync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/auth');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User info section
              CircleAvatar(
                radius: 50,
                backgroundImage:
                    user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                child:
                    user?.photoURL == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome, ${user?.displayName ?? 'User'}!',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 10),
              const Text('You are now signed in to JamSync'),
              const SizedBox(height: 40),

              // Profile setup button - only show if needed
              FutureBuilder<bool>(
                future: _isProfileComplete(user?.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final isProfileComplete = snapshot.data ?? false;

                  return isProfileComplete
                      ? const Text('Your profile is complete!')
                      : ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Complete Your Profile'),
                        onPressed: () {
                          Navigator.of(context).pushNamed('/profile_setup');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Check if the user profile is complete
  Future<bool> _isProfileComplete(String? uid) async {
    if (uid == null) return false;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      return doc.exists && (doc.data()?['profileComplete'] == true);
    } catch (e) {
      print('Error checking profile: $e');
      return false;
    }
  }
}
