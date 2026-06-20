/// connectivity_service.dart
/// Location: lib/services/connectivity_service.dart
///
/// Checks internet connectivity before the app loads.
/// The app cannot proceed without an active internet connection.
///
/// Add to pubspec.yaml:
///   connectivity_plus: ^6.0.3
library;

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final _connectivity = Connectivity();

  /// Returns true if the device currently has internet access.
  static Future<bool> hasInternet() async {
    final results = await _connectivity.checkConnectivity();
    // results is a List<ConnectivityResult>
    return results.any((r) =>
    r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  /// Stream that emits true/false whenever connectivity changes.
  /// Used by NoInternetScreen to auto-retry when connection is restored.
  static Stream<bool> get connectivityStream =>
      _connectivity.onConnectivityChanged.map((results) => results.any((r) =>
      r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet));
}