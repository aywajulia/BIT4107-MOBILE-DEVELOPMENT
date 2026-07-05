/// progress_screen.dart
/// Location: lib/screen/progress_screen.dart
library;

import 'package:flutter/material.dart';
import '../model/dashboard_models.dart';

class ProgressScreen extends StatefulWidget {
  final List<ActivityEntry> activities;
  const ProgressScreen({super.key, required this.activities});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
  }

  DateTime _mondayOf(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  List<DateTime> get _weekDays => List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  List<ActivityEntry> get _weekActivities => widget.activities.where((a) {
    final d = DateTime(a.loggedAt.year, a.loggedAt.month, a.loggedAt.day);
    return !d.isBefore(_weekStart) && !d.isAfter(_weekStart.add(const Duration(days: 6)));
  }).toList();

  int get _weeklyWorkouts => _weekActivities.length;
  int get _weeklyCalories => _weekActivities.fold(0, (sum, a) => sum + a.caloriesBurned);

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  List<int> get _dailyCalories {
    return List.generate(7, (i) {
      final day = _weekStart.add(Duration(days: i));
      return _weekActivities
          .where((a) => a.loggedAt.year == day.year && a.loggedAt.month == day.month && a.loggedAt.day == day.day)
          .fold(0, (sum, a) => sum + a.caloriesBurned);
    });
  }

  List<int> get _dailyWorkoutCounts {
    return List.generate(7, (i) {
      final day = _weekStart.add(Duration(days: i));
      return _weekActivities
          .where((a) => a.loggedAt.year == day.year && a.loggedAt.month == day.month && a.loggedAt.day == day.day)
          .length;
    });
  }

  List<List<String>> get _dailyActivityNames {
    return List.generate(7, (i) {
      final day = _weekStart.add(Duration(days: i));
      return _weekActivities
          .where((a) => a.loggedAt.year == day.year && a.loggedAt.month == day.month && a.loggedAt.day == day.day)
          .map((a) => a.name)
          .toSet()
          .toList();
    });
  }

  void _previousWeek() => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  void _nextWeek() {
    final nextMonday = _weekStart.add(const Duration(days: 7));
    if (!nextMonday.isAfter(_mondayOf(DateTime.now()))) setState(() => _weekStart = nextMonday);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFF9A9A9A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Progress&\nStatistics', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), height: 1.15)),
                const SizedBox(height: 24),
                _buildWeekNavigator(),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCircle(value: _weeklyWorkouts.toString(), label: 'Workouts'),
                    _buildStatCircle(value: _weeklyCalories.toString(), label: 'Calories\nBurned', unit: 'Kcal'),
                  ],
                ),
                const SizedBox(height: 40),
                _buildBarChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekNavigator() {
    final endOfWeek = _weekStart.add(const Duration(days: 6));
    final weekLabel = '${_fmt(_weekStart)} – ${_fmt(endOfWeek)}';
    final isCurrentWeek = _weekStart == _mondayOf(DateTime.now());

    return Row(
      children: [
        GestureDetector(onTap: _previousWeek, child: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF1A1A1A))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This week:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              Text(weekLabel, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
        GestureDetector(
          onTap: isCurrentWeek ? null : _nextWeek,
          child: Icon(Icons.chevron_right, size: 28, color: isCurrentWeek ? Colors.black26 : const Color(0xFF1A1A1A)),
        ),
      ],
    );
  }

  String _fmt(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${_dayLabels[d.weekday - 1]} ${d.day} ${months[d.month]}';
  }

  Widget _buildStatCircle({required String value, required String label, String? unit}) {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: const BoxDecoration(color: Color(0xFF1A1A1A), shape: BoxShape.circle),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unit != null) Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1)),
                if (unit == null) const Text('No.', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A), height: 1.2)),
      ],
    );
  }

  Widget _buildBarChart() {
    final calories = _dailyCalories;
    final workoutCounts = _dailyWorkoutCounts;
    final names = _dailyActivityNames;

    final maxCalories = calories.reduce((a, b) => a > b ? a : b);
    final scale = maxCalories == 0 ? 1.0 : maxCalories.toDouble();

    const chartHeight = 180.0;
    const barWidth = 26.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const RotatedBox(
              quarterTurns: 3,
              child: Text('K C A L', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: chartHeight + 32,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (i) {
                          final barH = maxCalories == 0 ? 0.0 : (calories[i] / scale) * chartHeight;
                          final hasActivity = calories[i] > 0;

                          return GestureDetector(
                            onTap: hasActivity ? () => _showDayDetail(_weekDays[i], names[i], calories[i], workoutCounts[i]) : null,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (hasActivity)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text('${workoutCounts[i]}x', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                  ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOut,
                                  width: barWidth,
                                  height: barH.clamp(4.0, chartHeight),
                                  decoration: BoxDecoration(
                                    color: hasActivity ? Colors.white : Colors.transparent,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    Container(height: 1.5, color: Colors.white, margin: const EdgeInsets.only(left: 4)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _dayLabels.map((d) => SizedBox(
                        width: barWidth + 4,
                        child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text('DAYS OF THE WEEK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.white)),
        ),
        if (maxCalories == 0) ...[
          const SizedBox(height: 16),
          const Center(
            child: Text('Log activities to see your weekly calorie burn.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ],
    );
  }

  void _showDayDetail(DateTime day, List<String> activityNames, int totalCalories, int workoutCount) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_fmt(day), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total calories: $totalCalories kcal', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('Workouts: $workoutCount', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            const Text('Activities:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 6),
            ...activityNames.map((name) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: Colors.white54, size: 14),
                  const SizedBox(width: 8),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            )),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Colors.white)))],
      ),
    );
  }
}