import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_config.dart';
import 'dart:math';

class FootstepsScreen extends StatefulWidget {
  const FootstepsScreen({super.key});

  @override
  State<FootstepsScreen> createState() => _FootstepsScreenState();
}

class _FootstepsScreenState extends State<FootstepsScreen> {
  final int _currentSteps = 9241;
  final int _goalSteps = 10000;
  final List<Map<String, dynamic>> _weeklyData = [
    {'day': 'Mon', 'steps': 7845},
    {'day': 'Tue', 'steps': 8123},
    {'day': 'Wed', 'steps': 7632},
    {'day': 'Thu', 'steps': 9241},
    {'day': 'Fri', 'steps': 0},
    {'day': 'Sat', 'steps': 0},
    {'day': 'Sun', 'steps': 0},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Steps counter with circular progress
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Steps',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: ThemeConfig.textIvory.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              _currentSteps.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: ThemeConfig.textIvory,
                              ),
                            ),
                            Text(
                              'Goal: $_goalSteps steps',
                              style: GoogleFonts.poppins(
                                color: ThemeConfig.primaryGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          children: [
                            Center(
                              child: SizedBox(
                                width: 120,
                                height: 120,
                                child: CircularProgressIndicator(
                                  value: _currentSteps / _goalSteps,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.grey[800],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        ThemeConfig.primaryGreen,
                                      ),
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                '${(_currentSteps / _goalSteps * 100).toInt()}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeConfig.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricCard('Distance', '4.2 km', Icons.straighten),
                      _buildMetricCard(
                        'Calories',
                        '348',
                        Icons.local_fire_department,
                      ),
                      _buildMetricCard('Time', '48 min', Icons.access_time),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Weekly overview
            Text(
              'This Week',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textIvory,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: List.generate(_weeklyData.length, (index) {
                  final item = _weeklyData[index];
                  final double heightPercentage =
                      item['steps'] > 0 ? item['steps'] / _goalSteps : 0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 24,
                                height: max(20, 140 * heightPercentage),
                                decoration: BoxDecoration(
                                  color:
                                      DateTime.now().weekday - 1 == index
                                          ? ThemeConfig.primaryGreen
                                          : ThemeConfig.primaryGreen
                                              .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['day'],
                            style: GoogleFonts.poppins(
                              color: ThemeConfig.textIvory,
                              fontWeight:
                                  DateTime.now().weekday - 1 == index
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // Activity log
            Text(
              'Activity Log',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textIvory,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildActivityLogItem(
                    time: '9:30 AM',
                    title: 'Morning Walk',
                    steps: 3542,
                    minutes: 32,
                    icon: Icons.directions_walk,
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  _buildActivityLogItem(
                    time: '12:45 PM',
                    title: 'Lunch Break Walk',
                    steps: 1254,
                    minutes: 18,
                    icon: Icons.lunch_dining,
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  _buildActivityLogItem(
                    time: '4:15 PM',
                    title: 'Coffee Run',
                    steps: 845,
                    minutes: 12,
                    icon: Icons.coffee,
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  _buildActivityLogItem(
                    time: '6:30 PM',
                    title: 'Evening Walk',
                    steps: 3600,
                    minutes: 35,
                    icon: Icons.nightlight_round,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Goals section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeConfig.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThemeConfig.primaryGreen),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step Goals',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.textIvory,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeConfig.primaryGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Update Goal',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: ThemeConfig.primaryGreen,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'View History',
                            style: GoogleFonts.poppins(
                              color: ThemeConfig.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: ThemeConfig.primaryGreen, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textIvory,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: ThemeConfig.textIvory.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogItem({
    required String time,
    required String title,
    required int steps,
    required int minutes,
    required IconData icon,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: ThemeConfig.primaryGreen.withOpacity(0.2),
        child: Icon(icon, color: ThemeConfig.primaryGreen),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: ThemeConfig.textIvory,
        ),
      ),
      subtitle: Text(
        time,
        style: GoogleFonts.poppins(
          color: ThemeConfig.textIvory.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$steps steps',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.primaryGreen,
            ),
          ),
          Text(
            '$minutes mins',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: ThemeConfig.textIvory.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
