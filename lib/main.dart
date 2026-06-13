/// main.dart
/// Location: lib/main.dart
///
/// Entry point for the Shredded Squad app.
/// Wires together all 5 screens with named routes and shared state.
///
/// Screen flow:
///   SplashScreen → LoginScreen → AppShell (Dashboard / Progress / Profile)
///                                               ↓
///                                         LoginScreen (on logout)
library;

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'models/dashboard_models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShreddedSquadApp());
}

// ─── Root App ─────────────────────────────────────────────────────────────────

class ShreddedSquadApp extends StatelessWidget {
  const ShreddedSquadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shredded Squad',
      debugShowCheckedModeBanner: false,

      // ── Global theme ──────────────────────────────────────────────────────
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A1A1A)),
        useMaterial3: true,
      ),

      // ── Initial screen ────────────────────────────────────────────────────
      // App always starts at the splash screen
      initialRoute: '/splash',

      // ── Route generator ───────────────────────────────────────────────────
      onGenerateRoute: (settings) {
        switch (settings.name) {

        // 1. Splash screen — shown on app launch
          case '/splash':
            return _fadeRoute(const SplashScreen(), settings);

        // 2. Login screen — shown after splash or on logout
          case '/login':
            return _fadeRoute(const LoginScreen(), settings);

        // 3. AppShell — main container holding Dashboard, Progress, Profile
          case '/home':
            return _fadeRoute(const AppShell(), settings);

        // Fallback for any undefined route
          default:
            return _fadeRoute(const SplashScreen(), settings);
        }
      },
    );
  }

  /// Smooth fade transition used between all screens.
  PageRoute _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeIn,
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

// ─── App Shell ────────────────────────────────────────────────────────────────

/// AppShell is the main container shown after a successful login.
///
/// It owns the shared meals and activities lists so that:
///   - DashboardScreen can add/remove entries via callbacks
///   - ProgressScreen reads the same list for the weekly chart
///
/// IndexedStack keeps all three tabs alive simultaneously so no data
/// is lost when switching between Home, Progress, and Profile.

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // ─── Shared data (single source of truth) ─────────────────────────────────

  /// All meals logged today — shared between Dashboard and Daily Progress total.
  final List<MealEntry> _meals = [];

  /// All activities logged — shared between Dashboard and Progress chart.
  final List<ActivityEntry> _activities = [];

  // ─── Active tab index ─────────────────────────────────────────────────────

  /// 0 = Dashboard, 1 = Progress, 2 = Profile
  int _currentIndex = 0;

  // ─── Meal callbacks ───────────────────────────────────────────────────────

  void _onMealAdded(MealEntry meal) =>
      setState(() => _meals.add(meal));

  void _onMealRemoved(MealEntry meal) =>
      setState(() => _meals.remove(meal));

  // ─── Activity callbacks ───────────────────────────────────────────────────

  void _onActivityAdded(ActivityEntry activity) =>
      setState(() => _activities.add(activity));

  void _onActivityRemoved(ActivityEntry activity) =>
      setState(() => _activities.remove(activity));

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      // Tab 0 — Dashboard
      DashboardScreen(
        meals: _meals,
        activities: _activities,
        onMealAdded: _onMealAdded,
        onMealRemoved: _onMealRemoved,
        onActivityAdded: _onActivityAdded,
        onActivityRemoved: _onActivityRemoved,
      ),

      // Tab 1 — Progress (reads same activities list)
      ProgressScreen(activities: _activities),

      // Tab 2 — Profile
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: _SquadBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────

class _SquadBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SquadBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFFD0CFC8),
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            index: 0,
            label: 'Home',
          ),
          _navItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart,
            index: 1,
            label: 'Progress',
          ),
          _navItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            index: 2,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 26,
              color: isSelected
                  ? const Color(0xFF1A1A1A)
                  : Colors.black38,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF1A1A1A)
                    : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}