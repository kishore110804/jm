import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme_config.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leaderboard section
          Text(
            'Leaderboard',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textIvory,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              children: [
                // Top 3 users
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTopUser('Jamie', '10,221', 2),
                    _buildTopUser('Alex', '12,435', 1),
                    _buildTopUser('Taylor', '9,876', 3),
                  ],
                ),
                const SizedBox(height: 20),

                // See full leaderboard button
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ThemeConfig.primaryGreen),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'See Full Leaderboard',
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

          // Friends section
          Text(
            'Friends',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textIvory,
            ),
          ),
          const SizedBox(height: 16),

          // Friend search
          TextField(
            decoration: InputDecoration(
              hintText: 'Search friends...',
              hintStyle: TextStyle(
                color: ThemeConfig.textIvory.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: ThemeConfig.textIvory.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Colors.grey[850],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ThemeConfig.primaryGreen),
              ),
            ),
            style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
          ),

          const SizedBox(height: 16),

          // Friends list
          _buildFriendItem('Alex Johnson', '12,435 steps today', true),
          const Divider(color: Colors.grey),
          _buildFriendItem('Jamie Smith', '10,221 steps today', true),
          const Divider(color: Colors.grey),
          _buildFriendItem('Taylor Brown', '9,876 steps today', false),
          const Divider(color: Colors.grey),
          _buildFriendItem('Jordan Lee', '8,654 steps today', true),

          const SizedBox(height: 24),

          // Friend suggestions
          Text(
            'Suggested Friends',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ThemeConfig.textIvory,
            ),
          ),
          const SizedBox(height: 16),

          // Suggestions
          _buildSuggestionItem('Casey Wilson', 'Based on your location'),
          const Divider(color: Colors.grey),
          _buildSuggestionItem('Riley Martinez', 'Friend of Jamie Smith'),
          const Divider(color: Colors.grey),
          _buildSuggestionItem('Morgan Taylor', 'In your contacts'),
        ],
      ),
    );
  }

  Widget _buildTopUser(String name, String steps, int rank) {
    final isFirst = rank == 1;
    final double avatarSize = isFirst ? 80.0 : 60.0;
    final Color medalColor =
        rank == 1
            ? Colors.amber
            : rank == 2
            ? Colors.grey
            : Colors.brown;

    return Column(
      children: [
        // Medal icon for top 3
        Icon(Icons.emoji_events, color: medalColor, size: isFirst ? 32 : 24),
        const SizedBox(height: 8),

        // Profile picture
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: medalColor, width: 2),
              ),
            ),
            CircleAvatar(
              radius: avatarSize / 2 - 2,
              backgroundColor: Colors.grey[700],
              child: Text(
                name.substring(0, 1),
                style: GoogleFonts.poppins(
                  fontSize: isFirst ? 28 : 20,
                  fontWeight: FontWeight.bold,
                  color: ThemeConfig.textIvory,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Name and steps
        Text(
          name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: isFirst ? 16 : 14,
            color: ThemeConfig.textIvory,
          ),
        ),
        Text(
          '$steps steps',
          style: GoogleFonts.poppins(
            fontSize: isFirst ? 14 : 12,
            color: ThemeConfig.textIvory.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendItem(String name, String stats, bool online) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[700],
                child: Text(
                  name.substring(0, 1),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeConfig.textIvory,
                  ),
                ),
              ),
              if (online)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: ThemeConfig.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[850]!, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ThemeConfig.textIvory,
                  ),
                ),
                Text(
                  stats,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ThemeConfig.textIvory.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.message_outlined,
              color: ThemeConfig.primaryGreen,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String name, String connection) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[700],
            child: Text(
              name.substring(0, 1),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textIvory,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ThemeConfig.textIvory,
                  ),
                ),
                Text(
                  connection,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ThemeConfig.textIvory.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.primaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Add',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
