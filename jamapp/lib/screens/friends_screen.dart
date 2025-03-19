import 'package:flutter/material.dart';
import '../utils/theme_config.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Text(
            'Friends Page',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textIvory,
            ),
          ),
          SizedBox(height: 20),
          Icon(Icons.people, size: 100, color: ThemeConfig.primaryGreen),
        ],
      ),
    );
  }
}
