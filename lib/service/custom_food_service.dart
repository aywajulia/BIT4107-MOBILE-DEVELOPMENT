/// custom_food_service.dart
/// Service for managing user‑defined local foods (East African / custom).
/// Provides a clean API for CRUD operations.
/// Uses the main DatabaseHelper internally.
library;

import 'database_helper.dart';

/// Model class for a custom food item.
class CustomFood {
  final int? id;               // auto‑increment, null for new items
  final String name;           // e.g., "Githeri"
  final int caloriesPer100g;   // nutritional base
  final double protein;
  final double carbs;
  final double fat;
  final String? category;      // e.g., 'staple', 'vegetable'
  final String? createdAt;     // timestamp

  CustomFood({
    this.id,
    required this.name,
    required this.caloriesPer100g,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.category,
    this.createdAt,
  });

  /// Converts to Map for SQLite insertion.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'caloriesPer100g': caloriesPer100g,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'category': category,
    'createdAt': createdAt ?? DateTime.now().toIso8601String(),
  };

  /// Factory to build from a SQLite row.
  factory CustomFood.fromMap(Map<String, dynamic> map) => CustomFood(
    id: map['id'],
    name: map['name'],
    caloriesPer100g: map['caloriesPer100g'],
    protein: (map['protein'] as num?)?.toDouble() ?? 0,
    carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
    fat: (map['fat'] as num?)?.toDouble() ?? 0,
    category: map['category'],
    createdAt: map['createdAt'],
  );
}

class CustomFoodService {
  // Use the main DatabaseHelper (singleton)
  static final _db = DatabaseHelper();

  /// Insert a new custom food. Returns the new row id.
  static Future<int> addFood(CustomFood food) async {
    return await _db.insertCustomFood(food.toMap());
  }

  /// Get all custom foods, ordered alphabetically.
  static Future<List<CustomFood>> getAllFoods() async {
    final result = await _db.getAllCustomFoods();
    return result.map((map) => CustomFood.fromMap(map)).toList();
  }

  /// Search custom foods by name (case‑insensitive, partial match).
  static Future<List<CustomFood>> searchFoods(String query) async {
    final result = await _db.searchCustomFoods(query);
    return result.map((map) => CustomFood.fromMap(map)).toList();
  }

  /// Delete a custom food by id.
  static Future<int> deleteFood(int id) async {
    return await _db.deleteCustomFood(id);
  }
}