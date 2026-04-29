import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show Random;
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

  // FR-34 — true when the bus is within ~150m of the next stop.
  // The driver dashboard / map shows a "STOP" alert while this is true.
  bool _approachingStop = false;
  bool get approachingStop => _approachingStop;

  // Distance in metres from the bus to the next stop (null when no trip).
  double? _distanceToNextStopM;
  double? get distanceToNextStopM => _distanceToNextStopM;

  // Tracks the closest distance the bus has been to the current next stop.
  // When the live distance starts growing again the bus has passed the
  // closest point along the polyline → time to advance the stop pointer.
  double? _minDistToNextStopM;

  // Total passengers who boarded this bus today, from /api/scanner/onboard.
  int _boardedToday = 0;
  int get boardedToday => _boardedToday;

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
    _minDistToNextStopM = null;
    _approachingStop = false;
    _distanceToNextStopM = null;

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

  /// Pull the live passenger count from the same backend source the
  /// scanner uses (/api/scanner/onboard). This keeps the driver dashboard
  /// gauge in sync with what the conductor's scanner shows.
  Future<void> seedPassengersFromBackend() async {
    if (_currentTrip == null) return;
    try {
      final res = await _api.getOnBoardCount();
      final data = res.data?['data'] as Map<String, dynamic>?;
      final onBoard = (data?['on_board'] as num?)?.toInt();
      final boarded = (data?['boarded_today'] as num?)?.toInt() ?? 0;
      if (onBoard == null) return;
      _currentTrip = _currentTrip!.copyWith(currentPassengers: onBoard);
      _boardedToday = boarded;
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

      // FR-34 — track the bus's distance to the next stop, fire the alert
      // when close, and auto-advance once the bus has clearly passed the
      // closest point along the polyline (distance growing again).
      final upcoming = nextStop;
      if (upcoming != null) {
        final dist = _haversineMeters(_currentLocation, upcoming.location);
        _distanceToNextStopM = dist;

        // Update the running minimum so we can detect when distance
        // starts growing again (= bus has passed closest point).
        if (_minDistToNextStopM == null || dist < _minDistToNextStopM!) {
          _minDistToNextStopM = dist;
        }

        // Show alert while the bus is reasonably close to the stop.
        _approachingStop = dist <= 350;

        // Bus has passed the stop:
        //   - it got within 350 m at some point, AND
        //   - it's now drifting away (distance > min + 50 m)
        final minSoFar = _minDistToNextStopM ?? double.infinity;
        if (minSoFar <= 350 && dist > minSoFar + 50) {
          // Mark stop as reached
          if (_currentTrip != null) {
            _currentTrip = _currentTrip!.copyWith(
              stopsCompleted: _currentStopIndex + 1,
            );
          }
          _currentStopIndex++;
          _approachingStop = false;
          _minDistToNextStopM = null; // reset for the new "next stop"
        }
      } else {
        _distanceToNextStopM = null;
        _approachingStop = false;
      }

      notifyListeners();
    });
  }

  // Great-circle distance in metres between two LatLng points.
  double _haversineMeters(LatLng a, LatLng b) {
    const earthM = 6371000.0;
    double rad(double deg) => deg * (3.141592653589793 / 180);
    final dLat = rad(b.latitude  - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h = (1 - _cosApprox(dLat)) / 2 +
        _cosApprox(rad(a.latitude)) *
            _cosApprox(rad(b.latitude)) *
            (1 - _cosApprox(dLng)) / 2;
    return 2 * earthM * _asinApprox(_sqrtApprox(h));
  }

  // Pull math fns from dart:math without re-importing — the file already
  // imports dart:math via Random; we use the global functions.
  double _cosApprox(double x) => math.cos(x);
  double _asinApprox(double x) => math.asin(x);
  double _sqrtApprox(double x) => math.sqrt(x);

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
