/// step_service.dart
/// Location: lib/service/step_service.dart
library;

import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StepService {
  static const double _stepThreshold = 12.0;
  static const int _cooldownMs = 300;

  static int _stepCount = 0;
  static DateTime? _lastStepTime;
  static StreamController<int>? _controller;

  static Future<int> _loadSavedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('step_count') ?? 0;
  }

  static Future<void> _saveSteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('step_count', steps);
  }

  static Stream<int> get stepStream async* {
    if (_controller != null) {
      yield* _controller!.stream;
      return;
    }

    _stepCount = await _loadSavedSteps();

    _controller = StreamController<int>.broadcast();
    _lastStepTime = null;

    _controller!.add(_stepCount);

    accelerometerEventStream().listen(
          (AccelerometerEvent event) {
        final magnitude = sqrt(
          event.x * event.x +
              event.y * event.y +
              event.z * event.z,
        );
        if (magnitude >= _stepThreshold) {
          final now = DateTime.now();
          if (_lastStepTime == null || now.difference(_lastStepTime!).inMilliseconds > _cooldownMs) {
            _lastStepTime = now;
            _stepCount++;
            _controller!.add(_stepCount);
            _saveSteps(_stepCount);
          }
        }
      },
      onError: (error) {
        debugPrint('Step sensor error: $error');
      },
    );

    yield* _controller!.stream;
  }

  static void dispose() {
    if (_controller != null) {
      _controller!.close();
      _controller = null;
    }
  }

  static int caloriesFromSteps(int steps, double weightKg) {
    final factor = 0.04 * (weightKg / 70.0);
    return (steps * factor).round();
  }
}