import 'package:flutter/material.dart';
import '../screens/auth/unified_auth_screen.dart';
import '../screens/profile/profile_setup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/error/connection_error_screen.dart';

class AppRouter {
  static const String initialRoute = '/auth';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Extract args if available
    final args = settings.arguments;

    switch (settings.name) {
      case '/auth':
        return MaterialPageRoute(
          builder: (context) => const UnifiedAuthScreen(),
        );

      case '/profile_setup':
        // Get user from arguments to pass to profile setup
        final user = args as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => ProfileSetupScreen(userData: user),
        );

      case '/home':
        return MaterialPageRoute(builder: (context) => const HomeScreen());

      case '/connection_error':
        // Provide a specialized screen for connection errors
        return MaterialPageRoute(
          builder:
              (context) => ConnectionErrorScreen(
                message: args as String? ?? 'Failed to connect to server',
                onRetry:
                    () => Navigator.of(context).pushReplacementNamed('/auth'),
              ),
        );

      // Add other routes as needed

      default:
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(title: const Text('Not Found')),
                body: Center(child: Text('Route ${settings.name} not found')),
              ),
        );
    }
  }
}
