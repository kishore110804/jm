import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_config.dart';
import 'routes/app_router.dart';
import 'utils/theme_config.dart';
import 'providers/health_provider.dart';

// Auth screens
import 'screens/auth/simple_auth_screen.dart';
import 'screens/auth/auth_success_screen.dart';

// Main app screens
import 'screens/main_app_screen.dart';
import 'screens/home_screen.dart';

// Profile screens
import 'screens/profile/profile_setup_screen.dart';
import 'screens/profile/account_settings_screen.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with our custom configuration
  await initializeFirebase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        // Add other providers here
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JamSync',
      theme: ThemeConfig.darkTheme,
      initialRoute: AppRouter.initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const SimpleAuthScreen(),
        '/auth_success': (context) => const AuthSuccessScreen(),
        '/main_app': (context) => const MainAppScreen(),
        '/profile_setup': (context) => const ProfileSetupScreen(),
        '/account_settings': (context) => const AccountSettingsScreen(),
      },
    );
  }
}
