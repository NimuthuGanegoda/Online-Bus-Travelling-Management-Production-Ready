import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../core/utils/helpers.dart';
import '../models/route_model.dart';
import '../models/trip_model.dart';

class TripProvider extends ChangeNotifier {
  Trip? _currentTrip;
  BusRoute? _currentRoute;
  int _currentStopIndex = 0;
  TripStatus _status = TripStatus.idle;
  Trip? _lastCompletedTrip;

  // GPS along polyline
  LatLng _currentLocation = LatLng(6.9320, 79.8828);
  double _currentSpeed = 0;
  Timer? _gpsTimer;
  final Random _random = Random();

  // Polyline progress tracking
  int _polySegmentIndex = 0;
  double _segmentProgress = 0.0; // 0.0 to 1.0 within current segment
  List<LatLng> _traveledPath = [];

  Trip? get currentTrip => _currentTrip;
  BusRoute? get currentRoute => _currentRoute;
  int get currentStopIndex => _currentStopIndex;
  TripStatus get status => _status;
  Trip? get lastCompletedTrip => _lastCompletedTrip;
  LatLng get currentLocation => _currentLocation;
  double get currentSpeed => _currentSpeed;
  List<LatLng> get traveledPath => _traveledPath;

  RouteStop? get nextStop {
    if (_currentRoute == null) return null;
    if (_currentStopIndex >= _currentRoute!.stops.length) return null;
    return _currentRoute!.stops[_currentStopIndex];
  }

  RouteStop? get previousStop {
    if (_currentRoute == null || _currentStopIndex == 0) return null;
    return _currentRoute!.stops[_currentStopIndex - 1];
  }

  int get etaMinutes {
    if (_currentRoute == null) return 0;
    final remaining =
        _currentRoute!.stops.length - _currentStopIndex;
    return (remaining * 8).clamp(0, 999);
  }

  void startTrip(BusRoute route) {
    _currentRoute = route;
    _currentStopIndex = 0;
    _status = TripStatus.active;
    _polySegmentIndex = 0;
    _segmentProgress = 0.0;

    _currentTrip = Trip(
      id: 'TRP-${DateTime.now().millisecondsSinceEpoch}',
      routeId: route.id,
      routeNumber: route.routeNumber,
      routeName: route.name,
      driverId: 'DRV-2841',
      startTime: DateTime.now(),
      totalStops: route.stops.length,
      totalDistance: route.distanceKm,
    );

    if (route.polyline.isNotEmpty) {
      _currentLocation = route.polyline.first;
      _traveledPath = [route.polyline.first];
    } else if (route.stops.isNotEmpty) {
      _currentLocation = route.stops.first.location;
      _traveledPath = [route.stops.first.location];
    }

    _startGpsSimulation();
    notifyListeners();
  }

  void arriveAtStop() {
    if (_currentTrip == null || _currentRoute == null) return;
    _status = TripStatus.atStop;

    final passengers = _random.nextInt(8) + 1;
    final alighting = _random.nextInt(
      (_currentTrip!.currentPassengers + 1).clamp(0, 5),
    );

    _currentTrip = _currentTrip!.copyWith(
      passengersBoarded: _currentTrip!.passengersBoarded + passengers,
      passengersAlighted: _currentTrip!.passengersAlighted + alighting,
      currentPassengers:
          _currentTrip!.currentPassengers + passengers - alighting,
      stopsCompleted: _currentStopIndex + 1,
    );

    notifyListeners();
  }

  void departFromStop() {
    if (_currentTrip == null || _currentRoute == null) return;

    _currentStopIndex++;
    if (_currentStopIndex >= _currentRoute!.stops.length) {
      endTrip();
      return;
    }

    _status = TripStatus.active;
    notifyListeners();
  }

  void updatePassengers(int boarded, int alighted) {
    if (_currentTrip == null) return;
    _currentTrip = _currentTrip!.copyWith(
      passengersBoarded: _currentTrip!.passengersBoarded + boarded,
      passengersAlighted: _currentTrip!.passengersAlighted + alighted,
      currentPassengers:
          (_currentTrip!.currentPassengers + boarded - alighted)
              .clamp(0, 999),
    );
    notifyListeners();
  }

  void endTrip() {
    _gpsTimer?.cancel();
    _status = TripStatus.completed;

    if (_currentTrip != null) {
      _lastCompletedTrip = _currentTrip!.copyWith(
        status: TripStatus.completed,
        endTime: DateTime.now(),
        distanceCovered: _currentRoute?.distanceKm ?? 0,
        avgSpeed: 24.5 + _random.nextDouble() * 10,
        stopsCompleted: _currentRoute?.stops.length ?? 0,
      );
    }

    _currentTrip = null;
    _currentRoute = null;
    _currentStopIndex = 0;
    _traveledPath = [];
    notifyListeners();
  }

  void resetForNewTrip() {
    _lastCompletedTrip = null;
    _status = TripStatus.idle;
    _traveledPath = [];
    notifyListeners();
  }

  LatLng _interpolate(LatLng a, LatLng b, double t) {
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  void _startGpsSimulation() {
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (_status != TripStatus.active || _currentRoute == null) return;
      final poly = _currentRoute!.polyline;
      if (poly.length < 2) return;

      // Advance along the polyline
      _segmentProgress += 0.02 + _random.nextDouble() * 0.03;

      if (_segmentProgress >= 1.0) {
        _segmentProgress = 0.0;
        _polySegmentIndex++;
        if (_polySegmentIndex >= poly.length - 1) {
          // Reached end of polyline, loop back to near-end
          _polySegmentIndex = poly.length - 2;
          _segmentProgress = 1.0;
        }
      }

      final from = poly[_polySegmentIndex];
      final to = poly[_polySegmentIndex + 1];
      _currentLocation = _interpolate(from, to, _segmentProgress);

      // Build traveled path: all completed segments + partial current
      _traveledPath = [
        for (int i = 0; i <= _polySegmentIndex; i++) poly[i],
        _currentLocation,
      ];

      _currentSpeed = 18 + _random.nextDouble() * 25;

      if (_currentTrip != null) {
        _currentTrip = _currentTrip!.copyWith(
          distanceCovered:
              _currentTrip!.distanceCovered + 0.02 + _random.nextDouble() * 0.03,
        );
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }
}
