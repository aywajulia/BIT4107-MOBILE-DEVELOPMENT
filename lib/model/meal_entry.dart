/// meal_entry.dart
/// Location: lib/model/meal_entry.dart
library;

class MealEntry {
  final String id;
  final String name;
  final String mealType;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime loggedAt;
  final double quantity;
  final String source;

  const MealEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
    this.quantity = 0,
    this.source = 'api',
  });

  String get dateKey => loggedAt.toIso8601String().split('T').first;
  String get mealTypeLabel {
    switch (mealType) {
      case 'breakfast': return 'Breakfast';
      case 'lunch':     return 'Lunch';
      case 'dinner':    return 'Dinner';
      case 'snack':     return 'Snack';
      default:          return mealType;
    }
  }

  String get macroSummary =>
      'P: ${protein.toStringAsFixed(0)}g  '
          'C: ${carbs.toStringAsFixed(0)}g  '
          'F: ${fat.toStringAsFixed(0)}g';

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'mealType': mealType,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'loggedAt': loggedAt.toIso8601String(),
    'loggedDate': dateKey,
    'quantity': quantity,
    'source': source,
  };

  factory MealEntry.fromMap(Map<String, dynamic> map) => MealEntry(
    id: map['id'] as String,
    name: map['name'] as String,
    mealType: map['mealType'] as String,
    calories: map['calories'] as int,
    protein: (map['protein'] as num).toDouble(),
    carbs: (map['carbs'] as num).toDouble(),
    fat: (map['fat'] as num).toDouble(),
    loggedAt: DateTime.parse(map['loggedAt'] as String),
    quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
    source: map['source'] as String? ?? 'api',
  );
}