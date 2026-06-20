/// splash_screen.dart
/// Location: lib/screens/splash_screen.dart
///
/// Intro splash screen — checks internet before proceeding.
/// If no internet → shows NoInternetScreen (app is blocked).
/// If internet ok  → navigates to LoginScreen after 3 seconds.

import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
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

    // Fade-in animation for the logo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // After 2.5 seconds check internet then navigate
    Future.delayed(const Duration(milliseconds: 2500), _checkAndNavigate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Checks internet connectivity.
  /// ✅ Has internet  → go to login screen
  /// ❌ No internet   → go to no-internet screen (app is blocked)
  Future<void> _checkAndNavigate() async {
    if (!mounted) return;

    final hasInternet = await ConnectivityService.hasInternet();

    if (!mounted) return;

    if (hasInternet) {
      // Internet available — proceed to login
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // No internet — block the app and show the no-internet screen
      // The no-internet screen will navigate to '/login' once reconnected
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const NoInternetScreen(nextRoute: '/login'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Warm olive-grey gradient matching the app design
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAE8D8), // warm cream top
              Color(0xFFB5B49A), // olive grey bottom
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
                // "Shredded" in bold near-black
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
                // "Squad" in off-white
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