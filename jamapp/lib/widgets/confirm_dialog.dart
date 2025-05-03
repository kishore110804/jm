import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_config.dart';

// Reusable confirmation dialog component for user interactions
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;

  const ConfirmDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    this.isDestructive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ThemeConfig.backgroundBlack,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isDestructive ? Colors.red : ThemeConfig.textIvory,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelText,
            style: GoogleFonts.poppins(
              color: ThemeConfig.textIvory.withOpacity(0.7),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmText,
            style: GoogleFonts.poppins(
              color: isDestructive ? Colors.red : ThemeConfig.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
