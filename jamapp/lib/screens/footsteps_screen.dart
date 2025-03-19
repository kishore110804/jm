import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_config.dart';

class FootstepsScreen extends StatelessWidget {
  const FootstepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Footsteps Page',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textIvory,
            ),
          ),
          const SizedBox(height: 20),
          const Icon(
            Icons.directions_walk,
            size: 100,
            color: ThemeConfig.primaryGreen,
          ),
        ],
      ),
    );
  }
}
