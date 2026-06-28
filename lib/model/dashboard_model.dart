/// dashboard_model.dart
/// Contains data models used by the Dashboard:
library;

// ─── Activity Model ───────────────────────────────────────────────────────────

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

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'caloriesBurned': caloriesBurned,
    'durationMinutes': durationMinutes,
    'loggedAt': loggedAt.toIso8601String(),
  };

  factory ActivityEntry.fromMap(Map<String, dynamic> map) => ActivityEntry(
    id: map['id'] as String,
    name: map['name'] as String,
    caloriesBurned: map['caloriesBurned'] as int,
    durationMinutes: map['durationMinutes'] as int,
    loggedAt: DateTime.parse(map['loggedAt'] as String),
  );
}

// ─── Step Data Model ──────────────────────────────────────────────────────────

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