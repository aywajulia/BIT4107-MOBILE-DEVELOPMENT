/// dashboard_models.dart
/// Location: lib/dashboard_models.dart
///
/// Contains all data models used by the Dashboard screen:
///   • MealEntry   — a single logged meal
///   • ActivityEntry — a single logged exercise activity
///   • StepData    — daily step count vs target (not persisted)

library;

// ─── Meal Model ──────────────────────────────────────────────────────────────

/// Represents a single meal logged by the user.
class MealEntry {
  final String id;
  final String name;
  final String mealType;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
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

  String get macroSummary =>
      'P: ${protein.toStringAsFixed(0)}g  '
          'C: ${carbs.toStringAsFixed(0)}g  '
          'F: ${fat.toStringAsFixed(0)}g';

  /// Converts the model to a Map for SQLite insertion/update.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'mealType': mealType,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'loggedAt': loggedAt.toIso8601String(),
  };

  /// Creates a MealEntry from a SQLite row (Map).
  factory MealEntry.fromMap(Map<String, dynamic> map) => MealEntry(
    id: map['id'] as String,
    name: map['name'] as String,
    mealType: map['mealType'] as String,
    calories: map['calories'] as int,
    protein: (map['protein'] as num).toDouble(),
    carbs: (map['carbs'] as num).toDouble(),
    fat: (map['fat'] as num).toDouble(),
    loggedAt: DateTime.parse(map['loggedAt'] as String),
  );
}

// ─── Activity Model ───────────────────────────────────────────────────────────

/// Represents a single exercise activity logged by the user.
class ActivityEntry {
  final String id;
  final String name;
  final int caloriesBurned;
  final int durationMinutes;
  final DateTime loggedAt;

  const ActivityEntry({
    required this.id,
    required this.name,
    required this.caloriesBurned,
    required this.durationMinutes,
    required this.loggedAt,
  });

  String get durationLabel => '$durationMinutes min';
  String get caloriesLabel => '$caloriesBurned kcal';

  /// Converts the model to a Map for SQLite insertion/update.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'caloriesBurned': caloriesBurned,
    'durationMinutes': durationMinutes,
    'loggedAt': loggedAt.toIso8601String(),
  };

  /// Creates an ActivityEntry from a SQLite row (Map).
  factory ActivityEntry.fromMap(Map<String, dynamic> map) => ActivityEntry(
    id: map['id'] as String,
    name: map['name'] as String,
    caloriesBurned: map['caloriesBurned'] as int,
    durationMinutes: map['durationMinutes'] as int,
    loggedAt: DateTime.parse(map['loggedAt'] as String),
  );
}

// ─── Step Data Model ──────────────────────────────────────────────────────────

/// Holds the user's daily step progress vs their target.
/// This is NOT persisted to SQLite – it's kept in memory.
class StepData {
  final int currentSteps;
  final int targetSteps;

  const StepData({
    required this.currentSteps,
    required this.targetSteps,
  });

  double get progress =>
      (currentSteps / targetSteps).clamp(0.0, 1.0);

  int get remainingSteps =>
      (targetSteps - currentSteps).clamp(0, targetSteps);

  int get percentComplete => (progress * 100).round();
}