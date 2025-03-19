import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_config.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Home Page',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textIvory,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Using Google Fonts - Poppins',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: ThemeConfig.textIvory,
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.home, size: 100, color: ThemeConfig.primaryGreen),
        ],
      ),
    );
  }
}
