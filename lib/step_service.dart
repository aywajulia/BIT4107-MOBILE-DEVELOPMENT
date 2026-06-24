/// step_service.dart
/// Service that provides real-time step count from the device's pedometer sensor.
/// Uses the pedometer package to listen to hardware step events.
library;

import 'package:pedometer/pedometer.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class StepService {
  /// A broadcast stream that emits the current step count every time the sensor updates.
  /// This is a static getter so it can be accessed anywhere without instantiating the class.
  static Stream<int> get stepStream async* {
    try {
      // Pedometer.stepCountStream is a static getter that streams StepCount events.
      // It automatically requests sensor permissions on Android (handled by the plugin).
      await for (final stepCount in Pedometer.stepCountStream) {
        // Extract the integer step count from the StepCount object and yield it.
        yield stepCount.steps;
      }
    } catch (e) {
      // If the sensor is unavailable (e.g., emulator or no hardware) or permission is denied,
      // we catch the error and output a debug-only message.
      // debugPrint is used instead of print so the message is stripped in release builds.
      debugPrint('Step sensor error: $e');
      // Yield 0 to prevent the UI from crashing or showing null.
      // This ensures the app gracefully degrades on unsupported devices.
      yield 0;
    }
  }
}