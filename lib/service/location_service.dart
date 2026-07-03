/// location_service.dart
/// Handles GPS tracking for activities.
/// Requests permissions, tracks location, calculates distance and pace.
library;

import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final List<Position> _positions = [];
  bool _isTracking = false;

  /// Request location permission.
  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  /// Start tracking GPS positions.
  Future<void> startTracking() async {
    _positions.clear();
    _isTracking = true;

    // Ensure location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Request permission
    bool hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied.');
    }

    // Listen to position updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5, // update every 5 meters
      ),
    ).listen((Position position) {
      if (_isTracking) {
        _positions.add(position);
        debugPrint('📍 GPS: ${position.latitude}, ${position.longitude}');
      }
    });
  }

  /// Stop tracking and return the total distance (km) and pace (min/km).
  Future<({double distance, double pace})> stopTracking(int durationMinutes) async {
    _isTracking = false;

    if (_positions.length < 2) {
      return (distance: 0.0, pace: 0.0);
    }

    // Calculate total distance
    double totalDistanceMeters = 0.0;
    for (int i = 1; i < _positions.length; i++) {
      totalDistanceMeters += Geolocator.distanceBetween(
        _positions[i - 1].latitude,
        _positions[i - 1].longitude,
        _positions[i].latitude,
        _positions[i].longitude,
      );
    }

    final distanceKm = totalDistanceMeters / 1000.0;

    // Calculate pace (min/km)
    double pace = 0.0;
    if (distanceKm > 0) {
      pace = durationMinutes / distanceKm;
    }

    _positions.clear();
    return (distance: distanceKm, pace: pace);
  }

  /// Get the current location (single shot).
  static Future<Position> getCurrentLocation() async {
    bool hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied.');
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Cancel tracking without saving.
  void cancelTracking() {
    _isTracking = false;
    _positions.clear();
  }
}