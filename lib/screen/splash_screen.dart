/// splash_screen.dart
/// Location: lib/splash_screen.dart
///
/// Intro splash screen — checks internet before proceeding.
/// If no internet → shows NoInternetScreen (app is blocked).
/// If internet ok  → checks if user is already logged in.
///    ✅ logged in → navigates to /home
///    ❌ not logged in → navigates to /login
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // for auto-login
import '../service/connectivity_service.dart';
import 'no_internet_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), _checkAndNavigate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAndNavigate() async {
    if (!mounted) return;

    final hasInternet = await ConnectivityService.hasInternet();

    // 🔥 Check mounted after the async call
    if (!mounted) return;

    if (!hasInternet) {
      // 🔥 Check mounted before using context
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const NoInternetScreen(nextRoute: '/login'),
        ),
      );
      return;
    }

    // 🔥 AUTO-LOGIN: check if user already logged in
    final prefs = await SharedPreferences.getInstance();

    // 🔥 Check mounted after the async call
    if (!mounted) return;

    final uid = prefs.getString('user_uid');

    if (uid != null && uid.isNotEmpty) {
      // User is logged in – go straight to home
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // No session – go to login
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAE8D8),
              Color(0xFFB5B49A),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shredded',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Squad',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF2EFE0),
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}