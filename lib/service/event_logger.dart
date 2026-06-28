/// Logs user interactions for debugging and analytics.
library;
import 'package:flutter/foundation.dart' show debugPrint;

class EventLogger {
  static void logEvent(String eventType, {String? screen, dynamic data}) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📝 [$timestamp] [$screen] $eventType -> $data');
  }
}