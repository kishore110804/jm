import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Properties for pairing code
  bool _showPairingCode = false;
  String? _pairingCode;
  DateTime? _expiryTime;
  Duration _timeRemaining = const Duration(minutes: 5);
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      AuthService authService;
      try {
        // Try to get the service from the provider
        authService = Provider.of<AuthService>(context, listen: false);
      } catch (e) {
        // If provider not found, create a local instance
        authService = AuthService();
      }

      final userData = await authService.getUserProfile();

      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading user data: $e');
    }
  }

  // Generate a random 6-digit code and save it to Firebase
  Future<void> _generatePairingCode() async {
    // Cancel any existing timer
    _countdownTimer?.cancel();

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate random code
      final random = Random();
      String code = '';
      for (int i = 0; i < 6; i++) {
        code += random.nextInt(10).toString();
      }

      // Set expiry time to 5 minutes from now
      final expiry = DateTime.now().add(const Duration(minutes: 5));

      // Get current user
      AuthService authService;
      try {
        // Try to get the service from the provider
        authService = Provider.of<AuthService>(context, listen: false);
      } catch (e) {
        // If provider not found, create a local instance
        authService = AuthService();
      }

      final user = authService.currentUser;

      if (user != null) {
        // Delete any existing pairing codes for this user
        final firestore = FirebaseFirestore.instance;
        final existingCodes =
            await firestore
                .collection('pairing_codes')
                .where('userId', isEqualTo: user.uid)
                .get();

        for (var doc in existingCodes.docs) {
          await doc.reference.delete();
        }

        // Save new code to Firestore
        await firestore.collection('pairing_codes').add({
          'code': code,
          'userId': user.uid,
          'expiryTime': Timestamp.fromDate(expiry),
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _pairingCode = code;
          _expiryTime = expiry;
          _timeRemaining = const Duration(minutes: 5);
          _showPairingCode = true;
          _isLoading = false;
        });

        // Start countdown timer
        _startCountdown();
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to generate a pairing code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating pairing code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (_expiryTime != null && now.isBefore(_expiryTime!)) {
        setState(() {
          _timeRemaining = _expiryTime!.difference(now);
        });
      } else {
        // Code expired
        timer.cancel();
        setState(() {
          _pairingCode = null;
          _timeRemaining = Duration.zero;
        });
      }
    });
  }

  // Format time as MM:SS
  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ThemeConfig.primaryGreen),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ThemeConfig.textIvory,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ThemeConfig.textIvory),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: ThemeConfig.backgroundBlack,
      body: SingleChildScrollView(
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
                        style: GoogleFonts.poppins(
                          color: ThemeConfig.textIvory,
                        ),
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

            // 6-digit OTP section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeConfig.primaryGreen.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.watch_outlined,
                        color: ThemeConfig.primaryGreen,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connect Smartwatch',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ThemeConfig.textIvory,
                              ),
                            ),
                            Text(
                              'Pair with your Android wearable device',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: ThemeConfig.textIvory.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),

                  if (_showPairingCode && _pairingCode != null) ...[
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Enter this code on your watch:',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: ThemeConfig.textIvory,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // Display the 6-digit code
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                _pairingCode!.split('').map((digit) {
                                  return Container(
                                    width: 45,
                                    height: 55,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ThemeConfig.primaryGreen
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: ThemeConfig.primaryGreen,
                                        width: 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      digit,
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: ThemeConfig.primaryGreen,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),
                          // Countdown timer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: ThemeConfig.primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Expires in ${_formatTime(_timeRemaining)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      _timeRemaining.inMinutes < 1
                                          ? Colors.redAccent
                                          : ThemeConfig.textIvory,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: Text(
                        _showPairingCode
                            ? 'Code expired. Generate a new one.'
                            : 'Generate a pairing code to connect your watch.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color:
                              _showPairingCode
                                  ? Colors.redAccent
                                  : ThemeConfig.textIvory,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Generate code button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _generatePairingCode,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _showPairingCode && _pairingCode != null
                            ? 'Regenerate Code'
                            : 'Generate Pairing Code',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConfig.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
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
                _buildAchievementItem(
                  'First Steps',
                  Icons.directions_walk,
                  true,
                ),
                _buildAchievementItem('Early Bird', Icons.wb_sunny, true),
                _buildAchievementItem(
                  'Week Streak',
                  Icons.calendar_today,
                  true,
                ),
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
                  _buildSettingsItem(
                    'Notifications',
                    Icons.notifications,
                    () {},
                  ),
                  const Divider(color: Colors.grey),
                  _buildSettingsItem('Privacy', Icons.lock, () {}),
                  const Divider(color: Colors.grey),
                  _buildSettingsItem('Help & Support', Icons.help, () {}),
                  const Divider(color: Colors.grey),
                  _buildSettingsItem('Logout', Icons.logout, () async {
                    try {
                      // Try to get the service from the provider
                      final authService = Provider.of<AuthService>(
                        context,
                        listen: false,
                      );
                      await authService.signOut();
                    } catch (e) {
                      // If provider not found, create a local instance
                      final authService = AuthService();
                      await authService.signOut();
                    }

                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  }, isDestructive: true),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
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
