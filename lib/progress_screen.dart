/// progress_screen.dart
/// Location: lib/screens/progress_screen.dart
///
/// The Progress & Statistics screen (4th screen) for Shredded Squad.
///
/// Displays:
///   1. Weekly workout count (No. circle)
///   2. Weekly calories burned (Kcal circle)
///   3. Bar chart — Days of the week vs muscle/activity intensity
///
/// Data is derived from the same ActivityEntry list used in the dashboard.
/// In production, pass the list in via constructor or a state-management
/// solution (Provider, Riverpod, Bloc, etc.).
library;

import 'package:flutter/material.dart';
import '../dashboard_model.dart'; // ActivityEntry model

class ProgressScreen extends StatefulWidget {
  /// Activities logged by the user (passed from the dashboard / shared state).
  /// Each entry carries: name, caloriesBurned, durationMinutes, loggedAt.
  final List<ActivityEntry> activities;

  const ProgressScreen({
    super.key,
    required this.activities,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // ─── Week boundaries ──────────────────────────────────────────────────────

  /// The Monday of the currently displayed week.
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
  }

  /// Returns the Monday of the week that contains [date].
  DateTime _mondayOf(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  /// All seven days of the current week (Mon → Sun).
  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  /// Activities that fall within the current week.
  List<ActivityEntry> get _weekActivities => widget.activities.where((a) {
    final d = DateTime(a.loggedAt.year, a.loggedAt.month, a.loggedAt.day);
    return !d.isBefore(_weekStart) &&
        !d.isAfter(_weekStart.add(const Duration(days: 6)));
  }).toList();

  // ─── Weekly stats ─────────────────────────────────────────────────────────

  /// Number of distinct workout sessions this week.
  int get _weeklyWorkouts => _weekActivities.length;

  /// Total calories burned this week.
  int get _weeklyCalories =>
      _weekActivities.fold(0, (sum, a) => sum + a.caloriesBurned);

  // ─── Chart helpers ────────────────────────────────────────────────────────

  /// Short day labels for the x-axis.
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// For each day of the week, sum the total duration of all activities.
  /// Duration is used as the bar height proxy (more time = more muscle work).
  List<int> get _dailyDurations {
    return List.generate(7, (i) {
      final day = _weekStart.add(Duration(days: i));
      return _weekActivities
          .where((a) =>
      a.loggedAt.year == day.year &&
          a.loggedAt.month == day.month &&
          a.loggedAt.day == day.day)
          .fold(0, (sum, a) => sum + a.durationMinutes);
    });
  }

  /// For each day, collect the unique activity names (for the tooltip).
  List<List<String>> get _dailyActivityNames {
    return List.generate(7, (i) {
      final day = _weekStart.add(Duration(days: i));
      return _weekActivities
          .where((a) =>
      a.loggedAt.year == day.year &&
          a.loggedAt.month == day.month &&
          a.loggedAt.day == day.day)
          .map((a) => a.name)
          .toSet()
          .toList();
    });
  }

  /// Navigate to the previous week.
  void _previousWeek() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  /// Navigate to the next week (capped at the current week).
  void _nextWeek() {
    final nextMonday = _weekStart.add(const Duration(days: 7));
    if (!nextMonday.isAfter(_mondayOf(DateTime.now()))) {
      setState(() => _weekStart = nextMonday);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF), // white top
              Color(0xFF9A9A9A), // medium grey bottom
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page title ───────────────────────────────────────────
                const Text(
                  'Progress&\nStatistics',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Week navigator ───────────────────────────────────────
                _buildWeekNavigator(),
                const SizedBox(height: 28),

                // ── Stat circles row ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCircle(
                      value: _weeklyWorkouts.toString(),
                      label: 'Workouts',
                    ),
                    _buildStatCircle(
                      value: _weeklyCalories.toString(),
                      label: 'Calories\nBurned',
                      unit: 'Kcal',
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // ── Bar chart ─────────────────────────────────────────────
                _buildBarChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Week Navigator ───────────────────────────────────────────────────────

  Widget _buildWeekNavigator() {
    // Format: "Mon 9 Jun – Sun 15 Jun"
    final endOfWeek = _weekStart.add(const Duration(days: 6));
    final weekLabel =
        '${_fmt(_weekStart)} – ${_fmt(endOfWeek)}';
    final isCurrentWeek =
        _weekStart == _mondayOf(DateTime.now());

    return Row(
      children: [
        // Back arrow
        GestureDetector(
          onTap: _previousWeek,
          child: const Icon(Icons.chevron_left,
              size: 28, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This week:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                weekLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        // Forward arrow (greyed out on current week)
        GestureDetector(
          onTap: isCurrentWeek ? null : _nextWeek,
          child: Icon(Icons.chevron_right,
              size: 28,
              color: isCurrentWeek
                  ? Colors.black26
                  : const Color(0xFF1A1A1A)),
        ),
      ],
    );
  }

  /// Format DateTime to "Mon 9 Jun"
  String _fmt(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_dayLabels[d.weekday - 1]} ${d.day} ${months[d.month]}';
  }

  // ─── Stat Circle ──────────────────────────────────────────────────────────

  /// Black circle displaying a big metric value with a label below it.
  Widget _buildStatCircle({
    required String value,
    required String label,
    String? unit,
  }) {
    return Column(
      children: [
        // Circle
        Container(
          width: 110,
          height: 110,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Unit label inside circle (e.g. "Kcal") — omitted for workouts
                if (unit != null)
                  Text(
                    unit,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                // Main value
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                // "No." label inside circle for workouts
                if (unit == null)
                  const Text(
                    'No.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Label below the circle
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // ─── Bar Chart ────────────────────────────────────────────────────────────

  Widget _buildBarChart() {
    final durations = _dailyDurations;
    final names = _dailyActivityNames;

    // Maximum duration this week (used to scale bar heights)
    final maxDuration = durations.reduce((a, b) => a > b ? a : b);
    // Avoid division by zero when no data exists
    final scale = maxDuration == 0 ? 1.0 : maxDuration.toDouble();

    const chartHeight = 180.0; // max bar height in pixels
    const barWidth = 26.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Y-axis label (rotated "MUSCLE") ────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Rotated Y label
            const RotatedBox(
              quarterTurns: 3,
              child: Text(
                'M U S C L E',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Chart area
            Expanded(
              child: SizedBox(
                height: chartHeight + 32, // extra for x-axis labels
                child: Column(
                  children: [
                    // Bars
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (i) {
                          final barH = maxDuration == 0
                              ? 0.0
                              : (durations[i] / scale) * chartHeight;
                          final hasActivity = durations[i] > 0;

                          return GestureDetector(
                            // Tap a bar to see the activity names for that day
                            onTap: hasActivity
                                ? () => _showDayDetail(
                              _weekDays[i],
                              names[i],
                              durations[i],
                            )
                                : null,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Tooltip dot on active bars
                                if (hasActivity)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                // The bar itself
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOut,
                                  width: barWidth,
                                  height: barH.clamp(4.0, chartHeight),
                                  decoration: BoxDecoration(
                                    color: hasActivity
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),

                    // X-axis line
                    Container(
                      height: 1.5,
                      color: Colors.white,
                      margin: const EdgeInsets.only(left: 4),
                    ),

                    // Day labels
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _dayLabels
                          .map((d) => SizedBox(
                        width: barWidth + 4,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // X-axis title
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'DAYS OF THE WEEK',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
        ),

        // Empty state hint
        if (maxDuration == 0) ...[
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Log activities on the dashboard\nto see your weekly chart.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Day detail popup ─────────────────────────────────────────────────────

  /// Shows a dialog with the activities done on a specific day.
  void _showDayDetail(
      DateTime day,
      List<String> activityNames,
      int totalDuration,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          _fmt(day),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total duration: $totalDuration min',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Text(
              'Activities:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            // List each activity name
            ...activityNames.map(
                  (name) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center,
                        color: Colors.white54, size: 14),
                    const SizedBox(width: 8),
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}