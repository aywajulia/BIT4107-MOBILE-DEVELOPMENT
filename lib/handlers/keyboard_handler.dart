/// keyboard_handler.dart
/// OOP class to manage keyboard submission events.
library;
//Allows the done or enter key to allow user login

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