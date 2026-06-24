/// activity_calorie_service.dart
/// Service that calculates calories burned during physical activities.
/// Uses the MET (Metabolic Equivalent of Task) standard.
library;

class ActivityCalorieService {

  static const Map<String, double> metValues = {
    // Walking activities
    'Walking (slow)': 2.5,      // 2.5 km/h
    'Walking (brisk)': 3.8,     // 4.8 km/h

    // Running activities
    'Running (jog)': 7.0,       // 8 km/h
    'Running (fast)': 9.8,      // 12 km/h

    // Cycling activities
    'Cycling (leisure)': 4.0,   // < 16 km/h
    'Cycling (moderate)': 6.8,  // ~20 km/h

    // Other activities
    'Swimming': 7.0,
    'Weightlifting': 6.0,
    'HIIT': 8.0,               // High Intensity Interval Training
  };

  /// Calculates the total calories burned for a given activity.
  /// Returns the calculated calories burned as a double (rounded later in UI).
  static double calculateCalories(String activity, double weightKg, int minutes) {
    // Look up the MET value for the selected activity; default to 4.0 (moderate effort) if not found.
    final met = metValues[activity] ?? 4.0;

    // Convert minutes to hours (since MET formula uses hours).
    final hours = minutes / 60.0;

    // Apply the formula: MET × weight × hours.
    return met * weightKg * hours;
  }
}