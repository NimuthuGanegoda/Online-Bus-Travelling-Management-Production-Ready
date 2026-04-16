import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../services/api_service.dart';

class RouteProvider extends ChangeNotifier {
  BusRoute? _assignedRoute;
  bool _isLoading = false;
  String? _error;

  BusRoute? get assignedRoute => _assignedRoute;
  List<BusRoute> get routes => _assignedRoute != null ? [_assignedRoute!] : [];
  List<BusRoute> get assignedRoutes => routes;
  List<BusRoute> get availableRoutes => const [];
  BusRoute? get selectedRoute => _assignedRoute;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _api = ApiService();

  Future<void> loadRoutes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getAssignedRoute();
      final data = res.data['data'] as Map<String, dynamic>;
      _assignedRoute = _mapRoute(data);
      _error = null;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      _error = msg ?? 'Failed to load route.';
      _assignedRoute = null;
    } catch (_) {
      _error = 'Connection error loading route.';
      _assignedRoute = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectRoute(BusRoute route) {
    _assignedRoute = route;
    notifyListeners();
  }

  void clearSelection() {
    _assignedRoute = null;
    notifyListeners();
  }

  BusRoute _mapRoute(Map<String, dynamic> r) {
    final stopsRaw = r['stops'] as List<dynamic>? ?? [];

    final stops = stopsRaw.map((s) {
      final lat = (s['latitude']  as num?)?.toDouble() ?? 0.0;
      final lng = (s['longitude'] as num?)?.toDouble() ?? 0.0;
      return RouteStop(
        id:       s['id']        as String? ?? '',
        name:     s['stop_name'] as String? ?? 'Stop',
        location: LatLng(lat, lng),
        sequence: s['stop_order'] as int? ?? 0,
      );
    }).toList();

    // Build polyline from stop coordinates
    final polyline = stops.map((s) => s.location).toList();

    // Parse color from hex string (e.g. "#1565c0")
    Color routeColor = const Color(0xFF1565C0);
    final colorStr = r['color'] as String?;
    if (colorStr != null && colorStr.startsWith('#')) {
      try {
        routeColor = Color(int.parse('FF${colorStr.substring(1)}', radix: 16));
      } catch (_) {}
    }

    return BusRoute(
      id:                r['id']          as String,
      routeNumber:       (r['route_number'] ?? '').toString(),
      name:              r['route_name']  as String? ?? 'Route',
      from:              r['origin']      as String? ?? '',
      to:                r['destination'] as String? ?? '',
      totalStops:        stops.length,
      distanceKm:        0,
      estimatedMinutes:  0,
      color:             routeColor,
      stops:             stops,
      polyline:          polyline,
      isAssigned:        true,
    );
  }
}
