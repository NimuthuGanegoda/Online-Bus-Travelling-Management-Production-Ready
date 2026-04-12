import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Dio-based API service layer.
/// All endpoints are placeholders — swap the base URL
/// when the backend is ready.
class ApiService {
  static const String _baseUrl = 'https://api.busgo.lk/v1';
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('[API] ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('[API] ${response.statusCode} ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('[API] ERROR ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  /// Set the auth token after login.
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // ---------- Auth ----------
  Future<Response> login(String employeeId, String password) async {
    return _dio.post('/auth/driver/login', data: {
      'employee_id': employeeId,
      'password': password,
    });
  }

  // ---------- Routes ----------
  Future<Response> getAssignedRoutes(String driverId) async {
    return _dio.get('/drivers/$driverId/routes');
  }

  Future<Response> getRouteDetails(String routeId) async {
    return _dio.get('/routes/$routeId');
  }

  // ---------- Trips ----------
  Future<Response> startTrip(String routeId, String driverId) async {
    return _dio.post('/trips', data: {
      'route_id': routeId,
      'driver_id': driverId,
    });
  }

  Future<Response> updateTrip(String tripId, Map<String, dynamic> data) async {
    return _dio.patch('/trips/$tripId', data: data);
  }

  Future<Response> endTrip(String tripId) async {
    return _dio.post('/trips/$tripId/end');
  }

  // ---------- Emergency ----------
  Future<Response> sendAlert(Map<String, dynamic> alertData) async {
    return _dio.post('/alerts', data: alertData);
  }

  Future<Response> cancelAlert(String alertId) async {
    return _dio.patch('/alerts/$alertId/cancel');
  }

  // ---------- Profile ----------
  Future<Response> getDriverProfile(String driverId) async {
    return _dio.get('/drivers/$driverId');
  }

  Future<Response> updateLocation(
    String driverId,
    double lat,
    double lng,
    double speed,
  ) async {
    return _dio.post('/drivers/$driverId/location', data: {
      'latitude': lat,
      'longitude': lng,
      'speed': speed,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
