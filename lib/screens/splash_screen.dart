import 'package:flutter/material.dart';
void main() {
      runApp(const MyApp());
    }

    class MyApp extends StatelessWidget {
      const MyApp({super.key});
      @override
       Widget build(BuildContext context) {
        return MaterialApp(
          title: 'Shredded Squad',
           home: const SplashScreen(),
      );
      }
     }

  class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
  }

  class _SplashScreenState extends State<SplashScreen>
  with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<double> _fadeAnimation;

    @override
    void initState() {
      super.initState();

      /// Fade-in the logo over 1.2 seconds
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );

      _fadeAnimation = CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      );

      // Start the fade
      _controller.forward();

      // Navigate away after 3 seconds total
      // Replace the route name '/home' with your actual next screen.
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        // Remove the default AppBar
        body: Container(
          // Full-screen warm olive-grey gradient — matches the screenshot
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEAE8D8), // light warm cream at the top
                Color(0xFFB5B49A), // muted olive-grey at the bottom
              ],
            ),
          ),

          // Centre the logo vertically and horizontally
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: const _AppLogo(),
            ),
          ),
        ),
      );
    }
  }

/// Renders the two-line "Shredded / Squad" wordmark.
///
/// • "Shredded" — bold, near-black, larger display weight
/// • "Squad"    — bold, off-white, slightly smaller
///
/// Extracted into its own widget so it can be reused on other screens
/// (e.g. a condensed version in the app bar).
class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      // Align text to the left, matching the design
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Shredded" line
        Text(
          'Shredded',
          style: TextStyle(
            fontFamily: 'Roboto', // swap for your brand font if needed
            fontSize: 52,
            fontWeight: FontWeight.w900, // heavy / black weight
            color: const Color(0xFF1A1A1A), // near-black
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),

        // "Squad" line
        Text(
          'Squad',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 48,
            fontWeight: FontWeight.w700, // bold
            color: const Color(0xFFF2EFE0), // off-white / cream
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

