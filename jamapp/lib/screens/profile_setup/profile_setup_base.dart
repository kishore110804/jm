import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme_config.dart';
import '../../services/auth_service.dart';
import 'name_step.dart';
import 'username_step.dart';
import 'age_step.dart';
import 'photo_step.dart';

class ProfileSetupBase extends StatefulWidget {
  const ProfileSetupBase({super.key});

  @override
  State<ProfileSetupBase> createState() => _ProfileSetupBaseState();
}

class _ProfileSetupBaseState extends State<ProfileSetupBase> {
  final PageController _pageController = PageController(initialPage: 0);
  final AuthService _authService = AuthService();
  int _currentPage = 0;
  String _name = '';
  String _username = '';
  String? _age;
  String? _photoURL;

  final List<Widget> _pages = [];
  
  @override
  void initState() {
    super.initState();
    _pages.add(NameStep(onNext: (name) {
      setState(() {
        _name = name;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }));
    
    _pages.add(UsernameStep(onNext: (username) {
      setState(() {
        _username = username;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }));
    
    _pages.add(AgeStep(onNext: (age) {
      setState(() {
        _age = age;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }));
    
    _pages.add(PhotoStep(onComplete: (photoURL) async {
      setState(() {
        _photoURL = photoURL;
      });
      
      // Save all profile data
      try {
        await _authService.updateUserProfile(
          name: _name,
          username: _username,
          age: _age,
          photoURL: _photoURL,
        );
        
        // Navigate back to profile page
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving profile: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }));
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: _currentPage > 0 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / _pages.length,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(ThemeConfig.primaryGreen),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}
