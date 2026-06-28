/// meal_validator.dart
/// Dedicated class for validating meal inputs.
class MealValidator {
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Enter a food name';
    return null;
  }

  static String? validateCalories(String? value) {
    if (value == null || value.isEmpty) return 'Enter calories per 100g';
    if (int.tryParse(value) == null) return 'Must be a number';
    return null;
  }

  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) return 'Enter quantity in grams';
    if (int.tryParse(value) == null) return 'Must be a number';
    return null;
  }
}