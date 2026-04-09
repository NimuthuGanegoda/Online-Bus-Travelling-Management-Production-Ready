import '../core/constants/api_constants.dart';
import '../models/bus_model.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import 'api_client.dart';

class BusService {
  final ApiClient _api;
  BusService(this._api);

  /// GET /buses/nearby?lat=&lng=&radius=
  Future<List<BusModel>> getNearbyBuses(double lat, double lng, {double radius = 2.0}) async {
    final data = await _api.get(ApiEndpoints.nearbyBuses, queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
    });
    final list = data as List<dynamic>;
    return list.map((e) => BusModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /routes
  Future<List<BusRoute>> getAllRoutes() async {
    final data = await _api.get(ApiEndpoints.busRoutes);
    final list = data as List<dynamic>;
    return list.map((e) => BusRoute.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /routes/search?q=
  Future<List<BusRoute>> searchRoutes(String query) async {
    final data = await _api.get(ApiEndpoints.routeSearch, queryParameters: {'q': query});
    final list = data as List<dynamic>;
    return list.map((e) => BusRoute.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /stops/nearby?lat=&lng=&radius=
  Future<List<StopModel>> getNearbyStops(double lat, double lng, {double radius = 0.5}) async {
    final data = await _api.get(ApiEndpoints.nearbyStops, queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
    });
    final list = data as List<dynamic>;
    return list.map((e) => StopModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /routes/:id/stops
  Future<List<StopModel>> getRouteStops(String routeId) async {
    final data = await _api.get(ApiEndpoints.routeStops(routeId));
    final list = data as List<dynamic>;
    return list.map((e) => StopModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /routes/:id/buses
  Future<List<BusModel>> getRouteBuses(String routeId) async {
    final data = await _api.get(ApiEndpoints.routeBuses(routeId));
    final list = data as List<dynamic>;
    return list.map((e) => BusModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
