import 'package:flutter/material.dart';
import '../screens/auth/simple_auth_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/auth_success_screen.dart';
import '../screens/profile_setup/profile_setup_base.dart'; // Add this import

class AppRouter {
  static const String initialRoute = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/auth':
        return MaterialPageRoute(builder: (_) => const SimpleAuthScreen());
      case '/auth_success':
        return MaterialPageRoute(builder: (_) => const AuthSuccessScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/profile_setup': // Add this route
        return MaterialPageRoute(builder: (_) => const ProfileSetupBase());
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
