import 'package:flutter/material.dart';
import '../../utils/theme_config.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      appBar: AppBar(
        title: const Text('JamApp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.signOut();
              Navigator.of(context).pushReplacementNamed('/auth');
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome to JamApp!',
          style: TextStyle(color: ThemeConfig.textIvory, fontSize: 24),
        ),
      ),
    );
  }
}
