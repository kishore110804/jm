import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_config.dart';
import 'dart:math';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with SingleTickerProviderStateMixin {
  final int _stressLevel = 35; // 0-100
  final int _sleepHours = 7;
  final int _sleepMinutes = 45;
  final int _heartRate = 68;
  final int _waterIntake = 5; // glasses
  final double _weight = 70.5;
  late TabController _tabController;

  final List<Map<String, dynamic>> _stressHistory = [
    {'day': 'Mon', 'level': 65},
    {'day': 'Tue', 'level': 50},
    {'day': 'Wed', 'level': 45},
    {'day': 'Thu', 'level': 35},
    {'day': 'Fri', 'level': 0},
    {'day': 'Sat', 'level': 0},
    {'day': 'Sun', 'level': 0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStressColor(int level) {
    if (level < 30) return Colors.green;
    if (level < 60) return Colors.orange;
    return Colors.red;
  }

  String _getStressText(int level) {
    if (level < 30) return 'Low';
    if (level < 60) return 'Moderate';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar for different health metrics
        TabBar(
          controller: _tabController,
          indicatorColor: ThemeConfig.primaryGreen,
          labelColor: ThemeConfig.primaryGreen,
          unselectedLabelColor: ThemeConfig.textIvory.withOpacity(0.7),
          tabs: [
            Tab(text: 'Stress & Mood', icon: Icon(Icons.psychology)),
            Tab(text: 'Sleep', icon: Icon(Icons.nightlight)),
            Tab(text: 'Vitals', icon: Icon(Icons.favorite)),
          ],
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Stress & Mood Tab
              _buildStressAndMoodTab(),

              // Sleep Tab
              _buildSleepTab(),

              // Vitals Tab
              _buildVitalsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStressAndMoodTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current stress level
          _buildSectionTitle('Current Stress Level'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getStressText(_stressLevel),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getStressColor(_stressLevel),
                      ),
                    ),
                    Text(
                      '$_stressLevel%',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getStressColor(_stressLevel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _stressLevel / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStressColor(_stressLevel),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Low',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Moderate',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      'High',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Your stress level is ${_getStressText(_stressLevel).toLowerCase()}. Continue practicing mindfulness and exercise to reduce stress.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ThemeConfig.textIvory,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stress history chart
          _buildSectionTitle('Stress Trends'),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_stressHistory.length, (index) {
                final item = _stressHistory[index];
                final double heightPercentage = item['level'] / 100;
                final Color barColor = _getStressColor(item['level']);

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
                                    item['level'] > 0
                                        ? barColor
                                        : Colors.grey[800],
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

          // Mood tracker
          _buildSectionTitle('Today\'s Mood'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How are you feeling?',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ThemeConfig.textIvory,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMoodOption('😀', 'Great'),
                    _buildMoodOption('🙂', 'Good'),
                    _buildMoodOption('😐', 'Okay'),
                    _buildMoodOption('😔', 'Sad'),
                    _buildMoodOption('😩', 'Stressed'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stress management tips
          _buildSectionTitle('Manage Your Stress'),
          const SizedBox(height: 12),
          _buildTipCard(
            'Deep Breathing',
            'Take 5 minutes to practice deep breathing exercises',
            Icons.air,
            Colors.blueAccent,
            () {},
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            'Quick Meditation',
            'A 10-minute guided meditation to reduce stress',
            Icons.self_improvement,
            Colors.purpleAccent,
            () {},
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            'Take a Walk',
            'Step away and take a 15-minute walk outside',
            Icons.directions_walk,
            ThemeConfig.primaryGreen,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sleep summary
          _buildSectionTitle('Last Night\'s Sleep'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.nightlight,
                        color: Colors.indigo,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$_sleepHours\h $_sleepMinutes\m',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeConfig.textIvory,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.thumb_up,
                                color:
                                    _sleepHours >= 7
                                        ? Colors.green
                                        : Colors.orange,
                                size: 20,
                              ),
                            ],
                          ),
                          Text(
                            _sleepHours >= 7
                                ? 'Good sleep duration'
                                : 'Try to get 7-9 hours of sleep',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color:
                                  _sleepHours >= 7
                                      ? Colors.green
                                      : Colors.orange,
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
                    _buildSleepMetricCard('Bedtime', '11:15 PM', Icons.bedtime),
                    _buildSleepMetricCard('Wake up', '7:00 AM', Icons.wb_sunny),
                    _buildSleepMetricCard('Quality', '85%', Icons.star),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sleep phases
          _buildSectionTitle('Sleep Phases'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade300,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(18),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Deep (1h 45m)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 36,
                        color: Colors.indigo.shade400,
                        alignment: Alignment.center,
                        child: Text(
                          'Light (3h 30m)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 36,
                        color: Colors.indigo.shade500,
                        alignment: Alignment.center,
                        child: Text(
                          'REM (1h)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade600,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(18),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Awake',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '11:15 PM',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: ThemeConfig.textIvory.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '7:00 AM',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: ThemeConfig.textIvory.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sleep tips
          _buildSectionTitle('Sleep Better'),
          const SizedBox(height: 12),
          _buildTipCard(
            'Bedtime Routine',
            'Start winding down 30 minutes before bed',
            Icons.nightlight,
            Colors.indigo,
            () {},
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            'Limit Screen Time',
            'Put away electronic devices 1 hour before bed',
            Icons.smartphone,
            Colors.blueGrey,
            () {},
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            'Cool Environment',
            'Set your bedroom temperature to 65-68°F (18-20°C)',
            Icons.ac_unit,
            Colors.lightBlue,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heart rate section
          _buildSectionTitle('Heart Rate'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_heartRate BPM',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ThemeConfig.textIvory,
                            ),
                          ),
                          Text(
                            'Resting heart rate',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: ThemeConfig.textIvory.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Normal',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Your resting heart rate is within the healthy range of 60-100 BPM for adults.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ThemeConfig.textIvory,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeartRateMetric('Lowest', '58', Colors.blue),
                    _buildHeartRateMetric('Average', '72', Colors.amber),
                    _buildHeartRateMetric('Highest', '124', Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Water intake tracking
          _buildSectionTitle('Water Intake'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$_waterIntake',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'glasses',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.lightBlue,
                          ),
                        ),
                        Text(
                          'of 8 daily goal',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: ThemeConfig.textIvory.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _waterIntake / 8,
                  minHeight: 12,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.lightBlue,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 20),
                Row(
                  children: List.generate(8, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.local_drink,
                          color:
                              index < _waterIntake
                                  ? Colors.lightBlue
                                  : Colors.grey[600],
                          size: 26,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add Glass',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Weight tracking
          _buildSectionTitle('Weight Tracking'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$_weight',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: ThemeConfig.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'kg',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: ThemeConfig.primaryGreen,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeConfig.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '- 0.5 kg',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ThemeConfig.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your weight is within a healthy range. Keep up the good work!',
                  style: TextStyle(fontSize: 14, color: ThemeConfig.textIvory),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ThemeConfig.primaryGreen),
                    minimumSize: const Size(double.infinity, 48),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.edit),
                  label: Text(
                    'Update Weight',
                    style: GoogleFonts.poppins(
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: ThemeConfig.textIvory,
      ),
    );
  }

  Widget _buildMoodOption(String emoji, String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: ThemeConfig.textIvory,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ThemeConfig.textIvory,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: ThemeConfig.textIvory.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: ThemeConfig.textIvory,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSleepMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.indigo, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
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

  Widget _buildHeartRateMetric(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          '$value BPM',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
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
    );
  }
}
