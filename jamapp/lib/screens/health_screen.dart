import 'package:flutter/material.dart';
import '../utils/theme_config.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Text(
            'Health Page',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textIvory,
            ),
          ),
          SizedBox(height: 20),
          Icon(Icons.favorite, size: 100, color: ThemeConfig.primaryGreen),
        ],
      ),
    );
  }
}
