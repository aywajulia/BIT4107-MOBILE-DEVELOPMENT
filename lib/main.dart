/// main.dart
/// Location: lib/main.dart
///
/// Entry point for Shredded Squad.
/// 🗄️ Uses SQLite for local storage – no Firebase required.

library;

import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'nutrition_api_screen.dart';
import 'personal_records_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'dashboard_model.dart';
import 'database_helper.dart';   // added for SQLite

void main() async {
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
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A1A1A)),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return _fade(const SplashScreen(), settings);
          case '/login':
            return _fade(const LoginScreen(), settings);
          case '/home':
            return _fade(const AppShell(), settings);
          default:
            return _fade(const SplashScreen(), settings);
        }
      },
    );
  }

  PageRoute _fade(Widget page, RouteSettings settings) =>
      PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      );
}

// ─── App Shell ────────────────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  List<MealEntry> _meals = [];
  List<ActivityEntry> _activities = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper();
    final meals = await db.getAllMeals();
    final activities = await db.getAllActivities();
    setState(() {
      _meals = meals;
      _activities = activities;
      _isLoading = false;
    });
  }

  void _addMeal(MealEntry m) async {
    final db = DatabaseHelper();
    await db.insertMeal(m);
    setState(() => _meals.add(m));
  }

  void _removeMeal(MealEntry m) async {
    final db = DatabaseHelper();
    await db.deleteMeal(m.id);
    setState(() => _meals.remove(m));
  }

  void _addActivity(ActivityEntry a) async {
    final db = DatabaseHelper();
    await db.insertActivity(a);
    setState(() => _activities.add(a));
  }

  void _removeActivity(ActivityEntry a) async {
    final db = DatabaseHelper();
    await db.deleteActivity(a.id);
    setState(() => _activities.remove(a));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tabs = [
      DashboardScreen(
        meals: _meals,
        activities: _activities,
        onMealAdded: _addMeal,
        onMealRemoved: _removeMeal,
        onActivityAdded: _addActivity,
        onActivityRemoved: _removeActivity,
      ),
      NutritionScreen(onMealAdded: _addMeal),
      const PersonalRecordsScreen(),
      ProgressScreen(activities: _activities),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

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
          _item(Icons.home_outlined, Icons.home, 0, 'Home'),
          _item(Icons.restaurant_outlined, Icons.restaurant, 1, 'Nutrition'),
          _item(Icons.emoji_events_outlined, Icons.emoji_events, 2, 'PRs'),
          _item(Icons.bar_chart_outlined, Icons.bar_chart, 3, 'Progress'),
          _item(Icons.person_outline, Icons.person, 4, 'Profile'),
        ],
      ),
    );
  }

  Widget _item(IconData icon, IconData active, int index, String label) {
    final sel = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              sel ? active : icon,
              size: 22,
              color: sel ? const Color(0xFF1A1A1A) : Colors.black38,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                color: sel ? const Color(0xFF1A1A1A) : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}