import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'screens/auth/simple_auth_screen.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/main_app_screen.dart';
import 'utils/theme_config.dart';
import 'providers/health_provider.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<StorageService>(create: (_) => StorageService()),
        ChangeNotifierProvider<HealthProvider>(create: (_) => HealthProvider()),
      ],
      child: MaterialApp(
        title: 'JamSync',
        theme: ThemeData(
          primaryColor: ThemeConfig.primaryGreen,
          scaffoldBackgroundColor: ThemeConfig.backgroundBlack,
          appBarTheme: const AppBarTheme(
            backgroundColor: ThemeConfig.backgroundBlack,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: ThemeConfig.textIvory,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: ThemeConfig.textIvory),
          ),
        ),
        home: const AuthGatekeeper(),
        routes: {
          '/auth': (context) => const SimpleAuthScreen(),
          '/profile_setup': (context) => const ProfileSetupScreen(),
          '/home': (context) => const MainAppScreen(),
        },
      ),
    );
  }
}

class AuthGatekeeper extends StatelessWidget {
  const AuthGatekeeper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the snapshot has user data, then they're logged in
        if (snapshot.hasData && snapshot.data != null) {
          // Check if profile is complete
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: ThemeConfig.primaryGreen),
                  ),
                );
              }
              
              // If profile is not complete, direct to profile setup
              if (!userSnapshot.hasData || 
                  !userSnapshot.data!.exists || 
                  userSnapshot.data!['profileComplete'] != true) {
                return const ProfileSetupScreen();
              }
              
              // Otherwise, go to main app
              return const MainAppScreen();
            },
          );
        }
        
        // Otherwise, they're not logged in
        return const SimpleAuthScreen();
      },
    );
  }
}
