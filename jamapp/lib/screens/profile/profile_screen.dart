import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/theme_config.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getUserProfile();

      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ThemeConfig.primaryGreen),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 60,
                  backgroundColor: ThemeConfig.primaryGreen,
                  backgroundImage:
                      _userData?['photoURL'] != null
                          ? NetworkImage(_userData!['photoURL'])
                          : null,
                  child:
                      _userData?['photoURL'] == null
                          ? Text(
                            (_userData?['displayName'] ?? 'User').substring(
                              0,
                              1,
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          )
                          : null,
                ),
                const SizedBox(height: 16),

                // User Name
                Text(
                  _userData?['displayName'] ?? 'User',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ThemeConfig.textIvory,
                  ),
                ),

                // Username
                Text(
                  '@${_userData?['username'] ?? 'username'}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: ThemeConfig.textIvory.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 20),

                // Bio
                if (_userData?['bio'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _userData!['bio'],
                      style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Edit Profile Button
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/account_settings');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ThemeConfig.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Edit Profile',
                    style: GoogleFonts.poppins(
                      color: ThemeConfig.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Steps', '85,432'),
                _buildStatItem('Workouts', '24'),
                _buildStatItem('Streak', '7 days'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Achievements section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ThemeConfig.textIvory,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    color: ThemeConfig.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Achievements grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildAchievementItem('First Steps', Icons.directions_walk, true),
              _buildAchievementItem('Early Bird', Icons.wb_sunny, true),
              _buildAchievementItem('Week Streak', Icons.calendar_today, true),
              _buildAchievementItem('10K Steps', Icons.emoji_events, false),
              _buildAchievementItem('Mountain', Icons.landscape, false),
              _buildAchievementItem('Social', Icons.people, false),
            ],
          ),

          const SizedBox(height: 24),

          // Settings section
          Text(
            'Settings',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textIvory,
            ),
          ),

          const SizedBox(height: 16),

          // Settings menu
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              children: [
                _buildSettingsItem(
                  'Account Settings',
                  Icons.manage_accounts,
                  () {
                    Navigator.pushNamed(context, '/account_settings');
                  },
                ),
                const Divider(color: Colors.grey),
                _buildSettingsItem('Notifications', Icons.notifications, () {}),
                const Divider(color: Colors.grey),
                _buildSettingsItem('Privacy', Icons.lock, () {}),
                const Divider(color: Colors.grey),
                _buildSettingsItem('Help & Support', Icons.help, () {}),
                const Divider(color: Colors.grey),
                _buildSettingsItem('Logout', Icons.logout, () async {
                  await Provider.of<AuthService>(
                    context,
                    listen: false,
                  ).signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
                }, isDestructive: true),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ThemeConfig.textIvory,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: ThemeConfig.textIvory.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementItem(String title, IconData icon, bool achieved) {
    return Container(
      decoration: BoxDecoration(
        color: achieved ? Colors.grey[800] : Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achieved ? ThemeConfig.primaryGreen : Colors.grey[800]!,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: achieved ? ThemeConfig.primaryGreen : Colors.grey,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: achieved ? FontWeight.w600 : FontWeight.normal,
              color:
                  achieved
                      ? ThemeConfig.textIvory
                      : ThemeConfig.textIvory.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : ThemeConfig.textIvory,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isDestructive ? Colors.red : ThemeConfig.textIvory,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
