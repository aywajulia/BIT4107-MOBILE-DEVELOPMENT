import 'package:flutter_test/flutter_test.dart';
import 'package:shredded_squad_sqlite_2/service/activity_calorie_service.dart';

void main() {
  test('Calculate calories for Running (jog)', () {
    final calories = ActivityCalorieService.calculateCalories(
      'Running (jog)',
      70.0,
      30,
    );
    expect(calories, 245.0);
  });

  test('Calculate calories for Walking (slow)', () {
    final calories = ActivityCalorieService.calculateCalories(
      'Walking (slow)',
      60.0,
      20,
    );
    expect(calories, 50.0);
  });
}