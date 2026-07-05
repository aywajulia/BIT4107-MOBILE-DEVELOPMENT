/// dashboard_models.dart
/// Location: lib/model/dashboard_models.dart

library;

class ActivityEntry {
  final String id;
  final String name;
  final int caloriesBurned;
  final int durationMinutes;
  final DateTime loggedAt;
  final double? distance;
  final double? pace;
  final String? route;

  const ActivityEntry({
    required this.id,
    required this.name,
    required this.caloriesBurned,
    required this.durationMinutes,
    required this.loggedAt,
    this.distance,
    this.pace,
    this.route,
  });

  String get durationLabel => '$durationMinutes min';
  String get caloriesLabel => '$caloriesBurned kcal';
  String get distanceLabel => distance != null ? '${distance!.toStringAsFixed(2)} km' : 'N/A';
  String get paceLabel => pace != null ? '${pace!.toStringAsFixed(1)} min/km' : 'N/A';

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'caloriesBurned': caloriesBurned,
    'durationMinutes': durationMinutes,
    'loggedAt': loggedAt.toIso8601String(),
    'distance': distance,
    'pace': pace,
    'route': route,
  };

  factory ActivityEntry.fromMap(Map<String, dynamic> map) => ActivityEntry(
    id: map['id'] as String,
    name: map['name'] as String,
    caloriesBurned: map['caloriesBurned'] as int,
    durationMinutes: map['durationMinutes'] as int,
    loggedAt: DateTime.parse(map['loggedAt'] as String),
    distance: (map['distance'] as num?)?.toDouble(),
    pace: (map['pace'] as num?)?.toDouble(),
    route: map['route'] as String?,
  );
}

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