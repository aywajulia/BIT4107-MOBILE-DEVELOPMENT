/// location_service.dart
/// Location: lib/service/location_service.dart
library;

import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class TrackingResult {
  final double distance;
  final double pace;
  final List<Position> positions;
  TrackingResult(this.distance, this.pace, this.positions);
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // ignore: prefer_final_fields
  List<Position> _positions = [];
  bool _isTracking = false;

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

  Future<void> startTracking() async {
    _positions.clear();
    _isTracking = true;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    bool hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied.');
    }

    debugPrint('GPS tracking started');
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (_isTracking) {
        _positions.add(position);
        debugPrint('📍 GPS: ${position.latitude}, ${position.longitude}');
      }
    });
  }

  Future<TrackingResult> stopTracking(int durationMinutes) async {
    _isTracking = false;
    debugPrint('GPS tracking stopped. Positions recorded: ${_positions.length}');

    if (_positions.length < 2) {
      return TrackingResult(0.0, 0.0, []);
    }

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
    double pace = 0.0;
    if (distanceKm > 0) {
      pace = durationMinutes / distanceKm;
    }

    final routePoints = List<Position>.from(_positions);
    _positions.clear();
    debugPrint('Distance: $distanceKm km, Pace: $pace min/km');
    return TrackingResult(distanceKm, pace, routePoints);
  }

  void cancelTracking() {
    _isTracking = false;
    _positions.clear();
  }
}