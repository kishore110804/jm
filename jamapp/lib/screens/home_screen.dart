import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme_config.dart';
import '../services/auth_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/leaderboard_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  bool _loading = true;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _leaderboardData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      // Get current user profile
      final userData = await _authService.getUserProfile();

      // Example leaderboard data - in a real app, fetch from Firebase
      final leaderboardData = [
        {'name': 'Alex', 'steps': 12435, 'rank': 1, 'photoUrl': null},
        {'name': 'Jamie', 'steps': 10221, 'rank': 2, 'photoUrl': null},
        {'name': 'Taylor', 'steps': 9876, 'rank': 3, 'photoUrl': null},
        {'name': 'Jordan', 'steps': 8654, 'rank': 4, 'photoUrl': null},
        {'name': 'Casey', 'steps': 7532, 'rank': 5, 'photoUrl': null},
      ];

      setState(() {
        _userData = userData;
        _leaderboardData = leaderboardData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      print('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ThemeConfig.primaryGreen),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: ThemeConfig.primaryGreen,
                  backgroundImage:
                      _userData?['photoURL'] != null
                          ? NetworkImage(_userData!['photoURL'])
                          : null,
                  child:
                      _userData?['photoURL'] == null
                          ? const Icon(Icons.person, color: Colors.black)
                          : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${_userData?['name'] ?? user?.displayName ?? 'Friend'}!',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ThemeConfig.textIvory,
                      ),
                    ),
                    Text(
                      'Keep the momentum going!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: ThemeConfig.textIvory.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Your Stats Section
            Text(
              'Your Stats',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textIvory,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[800]!),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Steps Today',
                          value: '9,241',
                          icon: Icons.directions_walk,
                          iconColor: ThemeConfig.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Calories',
                          value: '348',
                          icon: Icons.local_fire_department,
                          iconColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Distance',
                          value: '4.2 km',
                          icon: Icons.map,
                          iconColor: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Active Time',
                          value: '48 min',
                          icon: Icons.timer,
                          iconColor: Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.primaryGreen,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      // Navigate to detailed stats
                    },
                    child: Text(
                      'See Detailed Stats',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Leaderboard Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Leaderboard',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ThemeConfig.textIvory,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Show full leaderboard
                  },
                  child: Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      color: ThemeConfig.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[800]!),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Leaderboard header
                  Row(
                    children: [
                      const SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          'Name',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: ThemeConfig.textIvory.withOpacity(0.7),
                          ),
                        ),
                      ),
                      Text(
                        'Steps',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: ThemeConfig.textIvory.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.grey),
                  ..._leaderboardData.map(
                    (user) => LeaderboardItem(
                      name: user['name'],
                      steps: user['steps'],
                      rank: user['rank'],
                      photoUrl: user['photoUrl'],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: ThemeConfig.primaryGreen),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      // Challenge friends
                    },
                    child: Text(
                      'Challenge Friends',
                      style: GoogleFonts.poppins(
                        color: ThemeConfig.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Daily Goal Section
            Container(
              decoration: BoxDecoration(
                color: ThemeConfig.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThemeConfig.primaryGreen),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: ThemeConfig.primaryGreen,
                    radius: 24,
                    child: Icon(Icons.flag, color: Colors.black, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Goal: 10,000 Steps',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ThemeConfig.textIvory,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '92% Complete - 759 steps to go!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: ThemeConfig.textIvory,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: 0.92,
                          backgroundColor: Colors.grey[700],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            ThemeConfig.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
