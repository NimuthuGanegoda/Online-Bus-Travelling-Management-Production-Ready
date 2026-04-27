import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../core/utils/helpers.dart';
import '../models/route_model.dart';
import '../models/trip_model.dart';
import '../services/api_service.dart';

class TripProvider extends ChangeNotifier {
  Trip? _currentTrip;
  BusRoute? _currentRoute;
  int _currentStopIndex = 0;
  TripStatus _status = TripStatus.idle;
  Trip? _lastCompletedTrip;

  LatLng _currentLocation = LatLng(6.9320, 79.8828);
  double _currentSpeed = 0;
  Timer? _gpsTimer;
  Timer? _locationUpdateTimer;
  final Random _random = Random();

  int _polySegmentIndex = 0;
  double _segmentProgress = 0.0;
  List<LatLng> _traveledPath = [];

  final _api = ApiService();

  Trip? get currentTrip => _currentTrip;
  BusRoute? get currentRoute => _currentRoute;
  int get currentStopIndex => _currentStopIndex;
  TripStatus get status => _status;
  Trip? get lastCompletedTrip => _lastCompletedTrip;
  LatLng get currentLocation => _currentLocation;
  double get currentSpeed => _currentSpeed;
  List<LatLng> get traveledPath => _traveledPath;

  RouteStop? get nextStop {
    if (_currentRoute == null || _currentStopIndex >= _currentRoute!.stops.length) return null;
    return _currentRoute!.stops[_currentStopIndex];
  }

  RouteStop? get previousStop {
    if (_currentRoute == null || _currentStopIndex == 0) return null;
    return _currentRoute!.stops[_currentStopIndex - 1];
  }

  int get etaMinutes {
    if (_currentRoute == null) return 0;
    return ((_currentRoute!.stops.length - _currentStopIndex) * 8).clamp(0, 999);
  }

  void startTrip(BusRoute route) {
    _currentRoute = route;
    _currentStopIndex = 0;
    _status = TripStatus.active;
    _polySegmentIndex = 0;
    _segmentProgress = 0.0;

    _currentTrip = Trip(
      id:            'TRP-${DateTime.now().millisecondsSinceEpoch}',
      routeId:       route.id,
      routeNumber:   route.routeNumber,
      routeName:     route.name,
      driverId:      '',
      startTime:     DateTime.now(),
      totalStops:    route.stops.length,
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
    _startLocationSync();
    notifyListeners();
  }

  void arriveAtStop() {
    if (_currentTrip == null || _currentRoute == null) return;
    _status = TripStatus.atStop;

    final boarded  = _random.nextInt(8) + 1;
    final alighted = _random.nextInt((_currentTrip!.currentPassengers + 1).clamp(0, 5));

    _currentTrip = _currentTrip!.copyWith(
      passengersBoarded:  _currentTrip!.passengersBoarded  + boarded,
      passengersAlighted: _currentTrip!.passengersAlighted + alighted,
      currentPassengers:  _currentTrip!.currentPassengers  + boarded - alighted,
      stopsCompleted:     _currentStopIndex + 1,
    );

    // Push passenger crowd level to backend
    _syncPassengers(_currentTrip!.currentPassengers);
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
      passengersBoarded:  _currentTrip!.passengersBoarded  + boarded,
      passengersAlighted: _currentTrip!.passengersAlighted + alighted,
      currentPassengers:  (_currentTrip!.currentPassengers + boarded - alighted).clamp(0, 999),
    );
    _syncPassengers(_currentTrip!.currentPassengers);
    notifyListeners();
  }

  /// Manual +/- adjustment used by the dashboard quick-action buttons.
  /// Pushes the new crowd level to the backend so the admin dashboard and
  /// passenger app see the change immediately.
  void adjustPassengers(int delta) {
    if (_currentTrip == null) return;
    final next = (_currentTrip!.currentPassengers + delta).clamp(0, 999);
    if (next == _currentTrip!.currentPassengers) return;
    _currentTrip = _currentTrip!.copyWith(
      currentPassengers:  next,
      passengersBoarded:  delta > 0
          ? _currentTrip!.passengersBoarded + delta
          : _currentTrip!.passengersBoarded,
      passengersAlighted: delta < 0
          ? _currentTrip!.passengersAlighted + (-delta)
          : _currentTrip!.passengersAlighted,
    );
    _syncPassengers(next);
    notifyListeners();
  }

  /// Seed the initial passenger count from the bus's saved crowd_level
  /// in the backend. Called on dashboard load so the gauge isn't stuck at 0.
  Future<void> seedPassengersFromBackend() async {
    if (_currentTrip == null) return;
    try {
      final res = await _api.getMe();
      final crowd = res.data?['data']?['bus']?['crowd_level'] as String?;
      if (crowd == null) return;
      final initial = switch (crowd) {
        'full'   => 50,
        'high'   => 35,
        'medium' => 22,
        _        => 8, // 'low' or anything unknown
      };
      _currentTrip = _currentTrip!.copyWith(currentPassengers: initial);
      notifyListeners();
    } catch (_) {/* ignore network hiccups */}
  }

  void endTrip() {
    _gpsTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _status = TripStatus.completed;

    if (_currentTrip != null) {
      _lastCompletedTrip = _currentTrip!.copyWith(
        status:          TripStatus.completed,
        endTime:         DateTime.now(),
        distanceCovered: _currentRoute?.distanceKm ?? 0,
        avgSpeed:        24.5 + _random.nextDouble() * 10,
        stopsCompleted:  _currentRoute?.stops.length ?? 0,
      );
    }

    _currentTrip   = null;
    _currentRoute  = null;
    _currentStopIndex = 0;
    _traveledPath  = [];
    notifyListeners();
  }

  void resetForNewTrip() {
    _lastCompletedTrip = null;
    _status = TripStatus.idle;
    _traveledPath = [];
    notifyListeners();
  }

  // ── Internal helpers ──────────────────────────────────────────

  void _startGpsSimulation() {
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (_status != TripStatus.active || _currentRoute == null) return;
      final poly = _currentRoute!.polyline;
      if (poly.length < 2) return;

      _segmentProgress += 0.02 + _random.nextDouble() * 0.03;

      if (_segmentProgress >= 1.0) {
        _segmentProgress = 0.0;
        _polySegmentIndex++;
        if (_polySegmentIndex >= poly.length - 1) {
          _polySegmentIndex = poly.length - 2;
          _segmentProgress  = 1.0;
        }
      }

      final from = poly[_polySegmentIndex];
      final to   = poly[_polySegmentIndex + 1];
      _currentLocation = _interpolate(from, to, _segmentProgress);

      _traveledPath = [
        for (int i = 0; i <= _polySegmentIndex; i++) poly[i],
        _currentLocation,
      ];

      _currentSpeed = 18 + _random.nextDouble() * 25;

      if (_currentTrip != null) {
        _currentTrip = _currentTrip!.copyWith(
          distanceCovered: _currentTrip!.distanceCovered + 0.02 + _random.nextDouble() * 0.03,
        );
      }

      notifyListeners();
    });
  }

  /// Send location to backend every 5 seconds during active trip.
  void _startLocationSync() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_status != TripStatus.active) return;
      unawaited(_sendLocation());
    });
  }

  Future<void> _sendLocation() async {
    try {
      await _api.updateLocation(
        latitude:  _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        speed:     _currentSpeed,
      );
    } catch (_) {}  // silent — don't crash trip on network hiccup
  }

  void _syncPassengers(int count) {
    String level = 'low';
    if (count > 40)      level = 'full';
    else if (count > 25) level = 'high';
    else if (count > 10) level = 'medium';
    unawaited(_sendPassengers(level));
  }

  Future<void> _sendPassengers(String level) async {
    try {
      await _api.updatePassengers(level);
    } catch (_) {}
  }

  LatLng _interpolate(LatLng a, LatLng b, double t) {
    return LatLng(
      a.latitude  + (b.latitude  - a.latitude)  * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
}
