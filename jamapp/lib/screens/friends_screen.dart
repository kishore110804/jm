import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../utils/theme_config.dart';
import '../widgets/friends/friend_list_item.dart';
import '../widgets/friends/stat_comparison_card.dart';
import '../models/friend.dart';
import '../models/user_stats.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Friend> _allFriends = [];
  List<Friend> _closeFriends = [];
  UserStats? _userStats;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFriendsData();
  }
  
  Future<void> _loadFriendsData() async {
    // This would normally fetch data from Firebase
    // For now, we'll use some mock data
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    setState(() {
      _allFriends = [
        Friend(
          id: '1',
          name: 'Sarah Johnson',
          username: 'sarahj',
          photoUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
          stats: UserStats(
            steps: 8765,
            calories: 376,
            distance: 5.2,
            workouts: 3,
          ),
        ),
        Friend(
          id: '2',
          name: 'Michael Brown',
          username: 'mikebrown',
          photoUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
          stats: UserStats(
            steps: 12043,
            calories: 498,
            distance: 7.8,
            workouts: 5,
          ),
        ),
        Friend(
          id: '3',
          name: 'Emily Wilson',
          username: 'emilyw',
          photoUrl: 'https://randomuser.me/api/portraits/women/33.jpg',
          stats: UserStats(
            steps: 6542,
            calories: 287,
            distance: 4.1,
            workouts: 2,
          ),
        ),
        Friend(
          id: '4',
          name: 'David Clark',
          username: 'davec',
          photoUrl: 'https://randomuser.me/api/portraits/men/41.jpg',
          stats: UserStats(
            steps: 9821,
            calories: 415,
            distance: 6.3,
            workouts: 4,
          ),
        ),
      ];
      
      _closeFriends = _allFriends.sublist(0, 2); // First two friends are close friends
      
      _userStats = UserStats(
        steps: 10500,
        calories: 445,
        distance: 6.7,
        workouts: 4,
      );
      
      _isLoading = false;
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Please sign in to see your friends',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textIvory,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text(
                'SIGN IN',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ThemeConfig.primaryGreen,
        ),
      );
    }
    
    return Column(
      children: [
        // Tab Bar
        TabBar(
          controller: _tabController,
          labelColor: ThemeConfig.primaryGreen,
          unselectedLabelColor: ThemeConfig.textIvory.withOpacity(0.7),
          indicatorColor: ThemeConfig.primaryGreen,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'All Friends'),
            Tab(text: 'Close Friends'),
            Tab(text: 'Stats Compare'),
          ],
        ),
        
        // Tab Bar View
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // All Friends Tab
              _buildFriendsList(_allFriends),
              
              // Close Friends Tab
              _buildFriendsList(_closeFriends),
              
              // Stats Comparison Tab
              _buildStatsComparison(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFriendsList(List<Friend> friends) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return FriendListItem(
          friend: friend,
          isCloseFriend: _closeFriends.contains(friend),
          onToggleFavorite: () {
            setState(() {
              if (_closeFriends.contains(friend)) {
                _closeFriends.remove(friend);
              } else {
                _closeFriends.add(friend);
              }
            });
          },
        );
      },
    );
  }
  
  Widget _buildStatsComparison() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Stats',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ThemeConfig.textIvory,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatCards(_userStats!),
          
          const SizedBox(height: 30),
          Text(
            'Compare with Friends',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ThemeConfig.textIvory,
            ),
          ),
          const SizedBox(height: 12),
          
          // Friend stat comparisons
          ..._allFriends.map((friend) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: StatComparisonCard(
                friendName: friend.name,
                friendPhotoUrl: friend.photoUrl,
                userStats: _userStats!,
                friendStats: friend.stats,
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildStatCards(UserStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Steps', '${stats.steps}', Icons.directions_walk),
        _buildStatCard('Calories', '${stats.calories} kcal', Icons.local_fire_department),
        _buildStatCard('Distance', '${stats.distance} km', Icons.map),
        _buildStatCard('Workouts', '${stats.workouts}', Icons.fitness_center),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: ThemeConfig.primaryGreen,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: ThemeConfig.textIvory.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: ThemeConfig.textIvory,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
