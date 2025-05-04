import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme_config.dart';
import '../services/auth_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/leaderboard_item.dart';
import '../widgets/step_counter_widget.dart';
import '../services/step_counter_service.dart';
import '../providers/health_provider.dart';
import '../widgets/weekly_steps_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final StepCounterService _stepService = StepCounterService();

  late TabController _tabController;
  bool _loading = true;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _leaderboardData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();

    // Initialize step counter
    _stepService.initStepCounter();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    // Wrap with Scaffold to provide Material context for TabBar and resolve overflow issues
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/profile');
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
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
              Text(
                'JamSync',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ThemeConfig.primaryGreen,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: ThemeConfig.textIvory,
            ),
            onPressed: () => _showLogoutConfirmation(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Welcome message and profile info
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${_userData?['displayName'] ?? user?.displayName ?? 'Friend'}!',
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
            ),

            // Tab Bar - Wrap in Material widget to fix the error
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Material(
                color: Colors.transparent,
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: ThemeConfig.primaryGreen,
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: ThemeConfig.textIvory,
                  tabs: const [
                    Tab(text: 'Today'),
                    Tab(text: 'Stats'),
                    Tab(text: 'Social'),
                  ],
                ),
              ),
            ),

            // Tab Content - Use Expanded to avoid overflow
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TODAY TAB - Wrap in SingleChildScrollView to handle potential overflow
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step Counter Widget
                        StepCounterWidget(
                          onTap: () {
                            // Navigate to step details screen
                          },
                        ),

                        const SizedBox(height: 24),

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
                                child: Icon(
                                  Icons.flag,
                                  color: Colors.black,
                                  size: 28,
                                ),
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
                                      '${_stepService.steps} steps completed',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: ThemeConfig.textIvory,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: _stepService.steps / 10000,
                                      backgroundColor: Colors.grey[700],
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            ThemeConfig.primaryGreen,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Workout suggestions
                        Text(
                          'Workout Suggestions',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ThemeConfig.textIvory,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Workout cards
                        SizedBox(
                          height: 180,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildWorkoutCard(
                                'Morning Run',
                                '20 min',
                                Icons.directions_run,
                                Colors.orange,
                              ),
                              _buildWorkoutCard(
                                'HIIT Training',
                                '15 min',
                                Icons.fitness_center,
                                Colors.purple,
                              ),
                              _buildWorkoutCard(
                                'Yoga Session',
                                '30 min',
                                Icons.self_improvement,
                                Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // STATS TAB
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          child: Consumer<HealthProvider>(
                            builder: (context, healthProvider, child) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: StatCard(
                                          title: 'Steps Today',
                                          value: '${healthProvider.steps}',
                                          icon: Icons.directions_walk,
                                          iconColor: ThemeConfig.primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: StatCard(
                                          title: 'Calories',
                                          value: '${healthProvider.calories}',
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
                                          value:
                                              '${(_stepService.steps * 0.0008).toStringAsFixed(1)} km',
                                          icon: Icons.map,
                                          iconColor: Colors.blueAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: StatCard(
                                          title: 'Active Time',
                                          value:
                                              '${(_stepService.steps * 0.01).toInt()} min',
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
                                      minimumSize: const Size(
                                        double.infinity,
                                        48,
                                      ),
                                    ),
                                    onPressed: () {
                                      // Navigate to detailed stats
                                    },
                                    child: Text(
                                      'See Detailed Stats',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Weekly Progress
                        Text(
                          'Weekly Progress',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ThemeConfig.textIvory,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: const WeeklyStepsChart(),
                        ),
                      ],
                    ),
                  ),

                  // SOCIAL TAB
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                        color: ThemeConfig.textIvory
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Steps',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: ThemeConfig.textIvory.withOpacity(
                                        0.7,
                                      ),
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
                                  side: const BorderSide(
                                    color: ThemeConfig.primaryGreen,
                                  ),
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

                        const SizedBox(height: 24),

                        // Friends Activity Feed
                        Text(
                          'Friends Activity',
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
                              _buildActivityItem(
                                'Alex completed a 5K run',
                                '15 minutes ago',
                                const Icon(
                                  Icons.directions_run,
                                  color: Colors.orange,
                                ),
                              ),
                              const Divider(color: Colors.grey),
                              _buildActivityItem(
                                'Jamie achieved 10,000 steps goal',
                                '2 hours ago',
                                const Icon(
                                  Icons.directions_walk,
                                  color: ThemeConfig.primaryGreen,
                                ),
                              ),
                              const Divider(color: Colors.grey),
                              _buildActivityItem(
                                'Taylor completed HIIT workout',
                                '4 hours ago',
                                const Icon(
                                  Icons.fitness_center,
                                  color: Colors.purple,
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
          ],
        ),
      ),
    );
  }

  // Add this method to show logout confirmation dialog
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Logout Confirmation',
            style: GoogleFonts.poppins(
              color: ThemeConfig.textIvory,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to logout?',
                  style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.primaryGreen,
                foregroundColor: Colors.black,
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorkoutCard(
    String title,
    String duration,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textIvory,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            duration,
            style: GoogleFonts.poppins(
              color: ThemeConfig.textIvory.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.2),
              foregroundColor: color,
              minimumSize: const Size(100, 30),
              padding: EdgeInsets.zero,
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String activity, String time, Icon icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.grey[800], child: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity,
                  style: GoogleFonts.poppins(
                    color: ThemeConfig.textIvory,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    color: ThemeConfig.textIvory.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.favorite_border,
              color: ThemeConfig.textIvory.withOpacity(0.6),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
