/// meal_entry.dart
/// Extended MealEntry model that supports:
///   - mealType: breakfast / lunch / dinner / snack
///   - quantity: grams consumed
///   - source: 'api' (from Open Food Facts) or 'custom' (user-defined local food)
///   - dateKey: YYYY-MM-DD (used to group meals by day)
library;

class MealEntry {
  // ── Core fields ─────────────────────────────────────────────────────────────
  final String id;          // Unique identifier (e.g., timestamp string)
  final String name;        // Name of the food (e.g., "Githeri", "Ugali")
  final String mealType;    // 'breakfast', 'lunch', 'dinner', 'snack'
  final int calories;       // Total calories for the logged quantity
  final double protein;     // Protein in grams
  final double carbs;       // Carbohydrates in grams
  final double fat;         // Fat in grams
  final DateTime loggedAt;  // Exact timestamp of when it was logged

  // ── Extended fields ────────────────────────────────────────────────────────
  final double quantity;    // Amount consumed in grams
  final String source;      // 'api' or 'custom'

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

  /// Returns the date as YYYY-MM-DD, used for grouping in Meal History.
  String get dateKey => loggedAt.toIso8601String().split('T').first;

  /// Returns a user‑friendly label (capitalised) for the meal type.
  String get mealTypeLabel {
    switch (mealType) {
      case 'breakfast': return 'Breakfast';
      case 'lunch': return 'Lunch';
      case 'dinner': return 'Dinner';
      case 'snack': return 'Snack';
      default: return mealType;
    }
  }

  /// Macro summary – compatible with the Dashboard card display.
  String get macroSummary =>
      'P: ${protein.toStringAsFixed(0)}g  '
          'C: ${carbs.toStringAsFixed(0)}g  '
          'F: ${fat.toStringAsFixed(0)}g';

  /// Converts the model to a Map for SQLite insertion.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'mealType': mealType,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'loggedAt': loggedAt.toIso8601String(),
    'loggedDate': dateKey,           // pre‑computed for faster queries
    'quantity': quantity,
    'source': source,
  };

  /// Factory constructor: creates a MealEntry from a SQLite row (Map).
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