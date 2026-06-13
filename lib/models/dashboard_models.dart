/// dashboard_models.dart
/// Location: lib/models/dashboard_models.dart
///
/// Contains all data models used by the Dashboard screen:
///   • MealEntry   — a single logged meal
///   • ActivityEntry — a single logged exercise activity
///   • StepData    — daily step count vs target
library;

// ─── Meal Model ──────────────────────────────────────────────────────────────

/// Represents a single meal logged by the user.
class MealEntry {
  final String id;
  final String name;         // e.g. "Grilled Chicken"
  final String mealType;     // e.g. "Breakfast", "Lunch", "Dinner", "Snack"
  final int calories;        // kcal
  final double protein;      // grams
  final double carbs;        // grams
  final double fat;          // grams
  final DateTime loggedAt;

  const MealEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
  });

  /// Total macros display string
  String get macroSummary =>
      'P: ${protein.toStringAsFixed(0)}g  '
          'C: ${carbs.toStringAsFixed(0)}g  '
          'F: ${fat.toStringAsFixed(0)}g';
}

// ─── Activity Model ───────────────────────────────────────────────────────────

/// Represents a single exercise activity logged by the user.
class ActivityEntry {
  final String id;
  final String name;           // e.g. "Running", "Weight Training"
  final int caloriesBurned;    // kcal
  final int durationMinutes;   // how long the activity took
  final DateTime loggedAt;

  const ActivityEntry({
    required this.id,
    required this.name,
    required this.caloriesBurned,
    required this.durationMinutes,
    required this.loggedAt,
  });

  /// Human-readable duration, e.g. "45 min"
  String get durationLabel => '$durationMinutes min';

  /// Human-readable calories, e.g. "320 kcal"
  String get caloriesLabel => '$caloriesBurned kcal';
}

// ─── Step Data Model ──────────────────────────────────────────────────────────

/// Holds the user's daily step progress vs their target.
class StepData {
  final int currentSteps;
  final int targetSteps;

  const StepData({
    required this.currentSteps,
    required this.targetSteps,
  });

  /// Progress from 0.0 to 1.0 (clamped so it never exceeds the ring)
  double get progress =>
      (currentSteps / targetSteps).clamp(0.0, 1.0);

  /// Remaining steps to reach target (never negative)
  int get remainingSteps =>
      (targetSteps - currentSteps).clamp(0, targetSteps);

  /// Percentage of target completed
  int get percentComplete => (progress * 100).round();
}