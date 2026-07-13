import 'package:flutter_test/flutter_test.dart';
import 'package:shredded_squad_sqlite_2/validator/auth_validator.dart';
import 'package:shredded_squad_sqlite_2/validator/meal_validator.dart';

void main() {
  test('AuthValidator – valid email passes', () {
    expect(AuthValidator.validateEmail('test@email.com'), null);
  });

  test('AuthValidator – invalid email fails', () {
    expect(AuthValidator.validateEmail('test'), 'Enter a valid email address');
  });

  test('MealValidator – empty name fails', () {
    expect(MealValidator.validateName(''), 'Enter a food name');
  });

  test('MealValidator – valid name passes', () {
    expect(MealValidator.validateName('Githeri'), null);
  });
}