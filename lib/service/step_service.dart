/// step_service.dart
/// Uses the accelerometer sensor to count steps.
/// Works on any device with an accelerometer.
/// Algorithm:
///   1. Listen to accelerometer events via accelerometerEventStream().
///   2. Calculate magnitude of movement: sqrt(x² + y² + z²).
///   3. Detect peaks above a threshold (≥ 12 m/s²).
///   4. Apply a cooldown (300ms) to avoid double counting.
library;

import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';

class StepService {
  // ─── Constants ─────────────────────────────────────────────────────────────
  /// Minimum acceleration magnitude to register a step (m/s²).
  static const double _stepThreshold = 12.0;

  /// Minimum time (milliseconds) between steps to avoid double counting.
  static const int _cooldownMs = 300;

  // ─── State ─────────────────────────────────────────────────────────────────
  static int _stepCount = 0;
  static DateTime? _lastStepTime;
  static StreamController<int>? _controller;

  // ─── Public Stream ─────────────────────────────────────────────────────────

  /// A broadcast stream that emits the current step count every time a step is detected.
  static Stream<int> get stepStream async* {
    // If a controller already exists, just yield its stream.
    if (_controller != null) {
      yield* _controller!.stream;
      return;
    }

    // Create a new broadcast controller.
    _controller = StreamController<int>.broadcast();
    _stepCount = 0;
    _lastStepTime = null;

    // Listen to the accelerometer event stream (not deprecated).
    accelerometerEventStream().listen(
          (AccelerometerEvent event) {
        // 1. Calculate the magnitude of the acceleration vector.
        final magnitude = sqrt(
          event.x * event.x +
              event.y * event.y +
              event.z * event.z,
        );

        // 2. Check if it's a valid step (above threshold and cooldown respected).
        if (_isStep(magnitude)) {
          _lastStepTime = DateTime.now();
          _stepCount++;
          _controller!.add(_stepCount);
        }
      },
      onError: (error) {
        // If the sensor fails, log it but don't crash.
        debugPrint('Step sensor error: $error');
        // Optionally, you could yield 0 or add the error to the stream.
        // _controller!.addError(error);
      },
    );

    yield* _controller!.stream;
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  /// Determines if a given magnitude counts as a step.
  static bool _isStep(double magnitude) {
    // 1. Must be above the threshold.
    if (magnitude < _stepThreshold) return false;

    // 2. Must respect the cooldown (prevent double count).
    if (_lastStepTime != null) {
      final elapsed = DateTime.now().difference(_lastStepTime!).inMilliseconds;
      if (elapsed < _cooldownMs) return false;
    }

    return true;
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────────

  /// Releases resources and resets the step counter.
  /// Called from the Dashboard's dispose() method.
  static void dispose() {
    if (_controller != null) {
      _controller!.close();
      _controller = null;
    }
    _stepCount = 0;
    _lastStepTime = null;
  }
}