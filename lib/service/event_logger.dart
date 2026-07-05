/// event_logger.dart
/// Location: lib/service/event_logger.dart
library;

import 'package:flutter/foundation.dart';

class EventLogger {
  static void logEvent(String eventType, {String? screen, dynamic data}) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📝 [$timestamp] [$screen] $eventType -> $data');
  }
}