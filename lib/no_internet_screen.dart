/// no_internet_screen.dart
/// Location: lib/screens/no_internet_screen.dart
///
/// Shown whenever the device has no internet connection.
/// The app is blocked from proceeding until connectivity is restored.
/// Auto-detects when internet comes back and navigates forward.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../connectivity_service.dart';

class NoInternetScreen extends StatefulWidget {
  /// The route to navigate to once internet is restored.
  final String nextRoute;

  const NoInternetScreen({super.key, required this.nextRoute});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  // Listens for connectivity changes in real time
  StreamSubscription<bool>? _subscription;

  // Controls the pulsing wifi icon animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();

    // Pulsing animation for the wifi-off icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen for real-time connectivity changes
    // When internet comes back, auto-navigate forward
    _subscription =
        ConnectivityService.connectivityStream.listen((hasInternet) {
          if (hasInternet && mounted) {
            _navigateForward();
          }
        });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Manually triggered when the user taps "Try Again".
  Future<void> _retry() async {
    setState(() => _isRetrying = true);

    // Small delay to show the spinner
    await Future.delayed(const Duration(milliseconds: 800));

    final connected = await ConnectivityService.hasInternet();

    if (connected && mounted) {
      _navigateForward();
    } else {
      if (mounted) {
        setState(() => _isRetrying = false);
        // Shake the error message to indicate still no internet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check your network.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Navigates to the intended screen once internet is confirmed.
  void _navigateForward() {
    Navigator.of(context).pushReplacementNamed(widget.nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Gradient background matching the Shredded Squad design
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFB0B0B0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Animated wifi-off icon ─────────────────────────────
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 64,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── App name ───────────────────────────────────────────
                const Text(
                  'Shredded Squad',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Main message ───────────────────────────────────────
                const Text(
                  'No Internet Connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Explanation ────────────────────────────────────────
                const Text(
                  'Check your internet connection to access the app',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Checklist of what needs internet ───────────────────
                _buildRequirementRow(
                    Icons.cloud_sync_outlined, 'Syncing your profile data'),
                const SizedBox(height: 10),
                _buildRequirementRow(
                    Icons.restaurant_outlined, 'Searching the nutrition database'),
                const SizedBox(height: 10),
                _buildRequirementRow(
                    Icons.bar_chart_outlined, 'Loading your weekly progress'),

                const SizedBox(height: 40),

                // ── Try again button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isRetrying ? null : _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isRetrying
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Auto-reconnect hint ────────────────────────────────
                const Text(
                  'The app will automatically continue\nwhen your connection is restored.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black38,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single row showing a feature that requires internet.
  Widget _buildRequirementRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1A1A1A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}