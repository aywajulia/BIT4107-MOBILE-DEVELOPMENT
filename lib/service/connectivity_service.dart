/// connectivity_service.dart
/// Location: lib/service/connectivity_service.dart
library;

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final _connectivity = Connectivity();

  static Future<bool> hasInternet() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) =>
    r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  static Stream<bool> get connectivityStream =>
      _connectivity.onConnectivityChanged.map((results) => results.any((r) =>
      r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet));
}