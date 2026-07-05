/// theme_provider.dart
/// Location: lib/service/theme_provider.dart
library;

import 'package:flutter/material.dart';

class ThemeProvider {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  static void toggleTheme() {
    final current = themeNotifier.value;
    themeNotifier.value = (current == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
  }

  static bool get isDarkMode => themeNotifier.value == ThemeMode.dark;
}