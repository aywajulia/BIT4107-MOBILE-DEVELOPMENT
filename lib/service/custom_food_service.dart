/// custom_food_service.dart
/// Location: lib/service/custom_food_service.dart
library;

import 'database_helper.dart';

class CustomFood {
  final int? id;
  final String name;
  final int caloriesPer100g;
  final double protein;
  final double carbs;
  final double fat;
  final String? category;
  final String? createdAt;

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
  static final _db = DatabaseHelper();

  static Future<int> addFood(CustomFood food) async {
    return await _db.insertCustomFood(food.toMap());
  }

  static Future<List<CustomFood>> getAllFoods() async {
    final result = await _db.getAllCustomFoods();
    return result.map((map) => CustomFood.fromMap(map)).toList();
  }

  static Future<List<CustomFood>> searchFoods(String query) async {
    final result = await _db.searchCustomFoods(query);
    return result.map((map) => CustomFood.fromMap(map)).toList();
  }

  static Future<int> deleteFood(int id) async {
    return await _db.deleteCustomFood(id);
  }
}