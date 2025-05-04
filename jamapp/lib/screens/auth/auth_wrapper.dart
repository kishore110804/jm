import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jamapp/providers/health_provider.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize health provider
    Future.delayed(Duration.zero, () {
      Provider.of<HealthProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
