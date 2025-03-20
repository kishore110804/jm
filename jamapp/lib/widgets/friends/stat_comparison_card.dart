import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_stats.dart';
import '../../utils/theme_config.dart';

class StatComparisonCard extends StatelessWidget {
  final String friendName;
  final String friendPhotoUrl;
  final UserStats userStats;
  final UserStats friendStats;

  const StatComparisonCard({
    super.key,
    required this.friendName,
    required this.friendPhotoUrl,
    required this.userStats,
    required this.friendStats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with friend info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(friendPhotoUrl),
                ),
                const SizedBox(width: 12),
                Text(
                  'You vs $friendName',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ThemeConfig.textIvory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats comparison
            _buildComparisonItem('Steps', userStats.steps, friendStats.steps),
            _buildComparisonItem('Calories', userStats.calories, friendStats.calories, suffix: ' kcal'),
            _buildComparisonItem('Distance', userStats.distance, friendStats.distance, suffix: ' km', isDouble: true),
            _buildComparisonItem('Workouts', userStats.workouts, friendStats.workouts),
          ],
        ),
      ),
    );
  }
  
  Widget _buildComparisonItem(String label, dynamic userValue, dynamic friendValue, {String suffix = '', bool isDouble = false}) {
    final userValueStr = isDouble ? '${userValue.toStringAsFixed(1)}$suffix' : '$userValue$suffix';
    final friendValueStr = isDouble ? '${friendValue.toStringAsFixed(1)}$suffix' : '$friendValue$suffix';
    
    // Calculate which value is higher
    final userIsHigher = isDouble 
        ? (userValue as double) > (friendValue as double) 
        : (userValue as int) > (friendValue as int);
    final difference = isDouble 
        ? ((userValue as double) - (friendValue as double)).abs().toStringAsFixed(1)
        : ((userValue as int) - (friendValue as int)).abs().toString();
        
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Label
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: ThemeConfig.textIvory.withOpacity(0.7),
              ),
            ),
          ),
          
          // Your value
          Expanded(
            child: Text(
              userValueStr,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: userIsHigher ? ThemeConfig.primaryGreen : ThemeConfig.textIvory,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // VS
          Text(
            'vs',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: ThemeConfig.textIvory.withOpacity(0.5),
            ),
          ),
          
          // Friend's value
          Expanded(
            child: Text(
              friendValueStr,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: !userIsHigher ? ThemeConfig.primaryGreen : ThemeConfig.textIvory,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Difference indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: userIsHigher ? ThemeConfig.primaryGreen.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              userIsHigher ? '+$difference' : '-$difference',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: userIsHigher ? ThemeConfig.primaryGreen : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
