/// activity_calorie_service.dart
/// Location: lib/service/activity_calorie_service.dart
library;

class ActivityCalorieService {
  static const Map<String, double> metValues = {
    'Walking (slow)': 2.5,
    'Walking (brisk)': 3.8,
    'Running (jog)': 7.0,
    'Running (fast)': 9.8,
    'Cycling (leisure)': 4.0,
    'Cycling (moderate)': 6.8,
    'Swimming': 7.0,
    'Weightlifting': 6.0,
    'HIIT': 8.0,
  };

  static double calculateCalories(String activity, double weightKg, int minutes) {
    final met = metValues[activity] ?? 4.0;
    final hours = minutes / 60.0;
    return met * weightKg * hours;
  }
}