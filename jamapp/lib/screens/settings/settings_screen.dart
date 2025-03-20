import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme_config.dart';
import '../../services/preferences_service.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  String _currentMode = PreferencesService.defaultMode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    String mode = await PreferencesService.getAppMode();
    setState(() {
      _currentMode = mode;
      _isLoading = false;
    });
  }

  Future<void> _setAppMode(String mode) async {
    await PreferencesService.setAppMode(mode);
    setState(() {
      _currentMode = mode;
    });

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'App mode changed to ${mode == PreferencesService.fitnessFocusMode ? "Fitness Focus" : "Networking Focus"}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: ThemeConfig.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: ThemeConfig.primaryGreen,
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Mode',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ThemeConfig.textIvory,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose how you want to use the app:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: ThemeConfig.textIvory.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Fitness Focus Option
                    _buildModeCard(
                      title: 'Fitness Focus',
                      description:
                          'Prioritize fitness tracking, health metrics, and personal goals',
                      icon: Icons.fitness_center,
                      isSelected:
                          _currentMode == PreferencesService.fitnessFocusMode,
                      onTap:
                          () =>
                              _setAppMode(PreferencesService.fitnessFocusMode),
                    ),
                    const SizedBox(height: 16),
                    // Networking Focus Option
                    _buildModeCard(
                      title: 'Networking Focus',
                      description:
                          'Prioritize social connections, friends activities, and community',
                      icon: Icons.people,
                      isSelected:
                          _currentMode ==
                          PreferencesService.networkingFocusMode,
                      onTap:
                          () => _setAppMode(
                            PreferencesService.networkingFocusMode,
                          ),
                    ),
                    const Spacer(),
                    // Reset button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.refresh,
                          color: ThemeConfig.textIvory,
                        ),
                        label: Text(
                          'Reset to Default Settings',
                          style: GoogleFonts.poppins(
                            color: ThemeConfig.textIvory,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: ThemeConfig.textIvory.withOpacity(0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed:
                            () => _setAppMode(PreferencesService.defaultMode),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Log out button for convenience
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: Text(
                          'Sign Out',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          await _auth.signOut();
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      color:
          isSelected
              ? ThemeConfig.primaryGreen.withOpacity(0.3)
              : Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? ThemeConfig.primaryGreen : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? ThemeConfig.primaryGreen : Colors.grey[800],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.black : ThemeConfig.textIvory,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ThemeConfig.textIvory,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: ThemeConfig.textIvory.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: ThemeConfig.primaryGreen,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
