import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'utils/theme_config.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'configure_google_sign_in.dart';

// App entry point that initializes Firebase and sets up the provider patterns
void main() async {
  await configureApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<StorageService>(create: (_) => StorageService()),
        StreamProvider<User?>.value(
          value: AuthService().user,
          initialData: null,
          catchError: (_, error) {
            if (kDebugMode) {
              print('❌ Auth stream error: $error');
            }
            return null;
          },
        ),
      ],
      child: MaterialApp(
        title: 'JamApp',
        theme: ThemeConfig.darkTheme,
        initialRoute: AppRouter.initialRoute,
        onGenerateRoute: AppRouter.onGenerateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
