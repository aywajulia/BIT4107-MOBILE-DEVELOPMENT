/// keyboard_handler.dart
/// Location: lib/handlers/keyboard_handler.dart
library;

import 'package:flutter/material.dart';
import '../service/event_logger.dart';

class KeyboardActionHandler {
  final VoidCallback onEnterPressed;

  KeyboardActionHandler({required this.onEnterPressed});

  void handleSubmit(String _) {
    EventLogger.logEvent('Keyboard_Enter', screen: 'Login', data: 'Submit pressed');
    onEnterPressed();
  }
}