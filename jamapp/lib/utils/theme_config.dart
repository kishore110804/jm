import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConfig {
  // App color constants
  static const Color primaryGreen = Color(0xFF1AFF00);
  static const Color backgroundBlack = Colors.black;
  static const Color textIvory = Color(0xFFEFEBDF);

  // Main theme for the app
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: backgroundBlack,
    colorScheme: const ColorScheme.dark(
      primary: primaryGreen,
      secondary: primaryGreen,
      surface: backgroundBlack,
      background: backgroundBlack,
      onBackground: textIvory,
      onSurface: textIvory,
    ),
    // Use Google Fonts for the app
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: textIvory, displayColor: textIvory),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundBlack,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(
        color: textIvory,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: backgroundBlack,
      selectedItemColor: primaryGreen,
      unselectedItemColor: textIvory.withOpacity(0.6),
      type: BottomNavigationBarType.fixed,
    ),
    iconTheme: const IconThemeData(color: primaryGreen),
  );
}
