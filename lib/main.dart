import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/member_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'models/dashboard_models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShreddedSquadApp());
}

class ShreddedSquadApp extends StatelessWidget {
  const ShreddedSquadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shredded Squad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A1A1A)),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return _fadeRoute(const SplashScreen(), settings);
          case '/login':
            return _fadeRoute(const LoginScreen(), settings);
          case '/home':
            return _fadeRoute(const AppShell(), settings);
          default:
            return _fadeRoute(const SplashScreen(), settings);
        }
      },
    );
  }

  PageRoute _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

// ─── App Shell ────────────────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Shared meals & activities lists
  final List<MealEntry> _meals = [];
  final List<ActivityEntry> _activities = [];

  /// 0=Home  1=Members  2=Progress  3=Profile
  int _currentIndex = 0;

  void _onMealAdded(MealEntry m) => setState(() => _meals.add(m));
  void _onMealRemoved(MealEntry m) => setState(() => _meals.remove(m));
  void _onActivityAdded(ActivityEntry a) => setState(() => _activities.add(a));
  void _onActivityRemoved(ActivityEntry a) =>
      setState(() => _activities.remove(a));

  @override
  Widget build(BuildContext context) {
    final tabs = [
      // Tab 0 — Dashboard
      DashboardScreen(
        meals: _meals,
        activities: _activities,
        onMealAdded: _onMealAdded,
        onMealRemoved: _onMealRemoved,
        onActivityAdded: _onActivityAdded,
        onActivityRemoved: _onActivityRemoved,
      ),

      // Tab 1 — Members (entity record management)
      const MembersTab(),

      // Tab 2 — Progress & Statistics
      ProgressScreen(activities: _activities),

      // Tab 3 — Profile
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: _SquadBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────

class _SquadBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SquadBottomNav(
      {required this.currentIndex, required this.onTap});

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
          _navItem(Icons.home_outlined, Icons.home, 0, 'Home'),
          _navItem(Icons.group_outlined, Icons.group, 1, 'Members'),
          _navItem(Icons.bar_chart_outlined, Icons.bar_chart, 2, 'Progress'),
          _navItem(Icons.person_outline, Icons.person, 3, 'Profile'),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, int index,
      String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon,
                size: 24,
                color: isSelected
                    ? const Color(0xFF1A1A1A)
                    : Colors.black38),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isSelected
                        ? const Color(0xFF1A1A1A)
                        : Colors.black38)),
          ],
        ),
      ),
    );
  }
}