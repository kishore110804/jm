import 'user_stats.dart';

class Friend {
  final String id;
  final String name;
  final String username;
  final String photoUrl;
  final UserStats stats;
  
  Friend({
    required this.id,
    required this.name,
    required this.username,
    required this.photoUrl,
    required this.stats,
  });
}
