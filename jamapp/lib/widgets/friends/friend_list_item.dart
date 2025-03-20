import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/friend.dart';
import '../../utils/theme_config.dart';

class FriendListItem extends StatelessWidget {
  final Friend friend;
  final bool isCloseFriend;
  final VoidCallback onToggleFavorite;

  const FriendListItem({
    super.key,
    required this.friend,
    required this.isCloseFriend,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(friend.photoUrl),
            ),
            
            const SizedBox(width: 16),
            
            // Friend info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeConfig.textIvory,
                    ),
                  ),
                  Text(
                    '@${friend.username}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: ThemeConfig.textIvory.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.directions_walk,
                        size: 16,
                        color: ThemeConfig.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${friend.stats.steps} steps',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: ThemeConfig.textIvory,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: ThemeConfig.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${friend.stats.calories} kcal',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: ThemeConfig.textIvory,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Favorite toggle button
            IconButton(
              icon: Icon(
                isCloseFriend ? Icons.star : Icons.star_border,
                color: isCloseFriend ? ThemeConfig.primaryGreen : ThemeConfig.textIvory.withOpacity(0.7),
              ),
              onPressed: onToggleFavorite,
            ),
          ],
        ),
      ),
    );
  }
}
