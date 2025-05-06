import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_config.dart';
import 'home_screen.dart';
import 'fitness/workout_screen.dart';
import 'social/social_screen.dart';
import 'profile/profile_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({Key? key}) : super(key: key);

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkoutScreen(),
    const SocialScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = ['Dashboard', 'Workouts', 'Social', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: GoogleFonts.poppins(
            color: ThemeConfig.textIvory,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ThemeConfig.backgroundBlack,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: ThemeConfig.textIvory,
            ),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: ThemeConfig.textIvory),
            onPressed: () {
              // Navigate to search
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.grey[900],
          selectedItemColor: Colors.black,
          unselectedItemColor: ThemeConfig.textIvory.withOpacity(0.7),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
          items: [
            _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
            _buildNavItem(
              Icons.fitness_center_outlined,
              Icons.fitness_center,
              'Workout',
              1,
            ),
            _buildNavItem(Icons.group_outlined, Icons.group, 'Social', 2),
            _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    final bool isSelected = _currentIndex == index;

    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? ThemeConfig.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color:
              isSelected
                  ? Colors.black
                  : ThemeConfig.textIvory.withOpacity(0.7),
        ),
      ),
      label: label,
      backgroundColor: Colors.transparent,
    );
  }
}
