import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Base URL resolves automatically:
///   Web (Chrome)      → localhost (same machine as backend)
///   Android emulator  → 10.0.2.2 (emulator alias for host localhost)
///   Physical device   → set your machine's LAN IP here
String get kBaseUrl {
  if (kIsWeb) return 'http://localhost:5000/api/driver';
  return 'http://10.0.2.2:5000/api/driver';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'driver_access_token';

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: kBaseUrl,
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
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint('[API] ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('[API] ${response.statusCode} ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('[API] ERROR ${error.response?.statusCode} ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  // ── Token management ──────────────────────────────────────────

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() =>
      _storage.delete(key: _tokenKey);

  Future<String?> getToken() =>
      _storage.read(key: _tokenKey);

  // ── Auth ──────────────────────────────────────────────────────

  Future<Response> login(String email, String password) =>
      _dio.post('/auth/login', data: {'email': email, 'password': password});

  Future<Response> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) =>
      _dio.post('/auth/register', data: {
        'full_name': fullName,
        'email':     email,
        'phone':     phone,
        'password':  password,
      });

  // ── Password recovery (FR-28 / FR-29) ──────────────────────────

  Future<Response> requestPasswordReset(String email) =>
      _dio.post('/auth/forgot-password/request', data: {'email': email});

  Future<Response> verifyResetPin(String email, String pin) =>
      _dio.post('/auth/forgot-password/verify', data: {'email': email, 'pin': pin});

  Future<Response> resetPassword({
    required String resetToken,
    required String newPassword,
  }) =>
      _dio.post('/auth/forgot-password/reset', data: {
        'reset_token':  resetToken,
        'new_password': newPassword,
      });

  // ── Profile ───────────────────────────────────────────────────

  Future<Response> getMe() => _dio.get('/me');

  // ── Route ─────────────────────────────────────────────────────

  Future<Response> getAssignedRoute() => _dio.get('/route');

  // ── Location ──────────────────────────────────────────────────

  Future<Response> updateLocation({
    required double latitude,
    required double longitude,
    double speed = 0,
    double? heading,
  }) =>
      _dio.patch('/location', data: {
        'latitude':  latitude,
        'longitude': longitude,
        'speed':     speed,
        if (heading != null) 'heading': heading,
      });

  // ── Passengers ────────────────────────────────────────────────

  Future<Response> updatePassengers(String crowdLevel) =>
      _dio.patch('/passengers', data: {'crowd_level': crowdLevel});

  // ── Live on-board count (shared with scanner app) ─────────────

  /// Fetches the live passenger count for the driver's bus from the
  /// shared /api/scanner/onboard endpoint. Returns the same number the
  /// BUSGO Scanner app shows so both views stay consistent.
  Future<Response> getOnBoardCount() {
    // Note: this endpoint lives under /scanner but is just a read-only
    // count protected by driver JWT — safe to call from the driver app.
    return _dio.get(
      kBaseUrl.replaceFirst('/api/driver', '/api/scanner/onboard'),
    );
  }

  // ── Emergency ─────────────────────────────────────────────────

  Future<Response> sendEmergency({
    required String alertType,
    String? description,
    double? latitude,
    double? longitude,
    String priority = 'P2',
  }) =>
      _dio.post('/emergency', data: {
        'alert_type':  alertType,
        if (description != null) 'description': description,
        if (latitude  != null)  'latitude':  latitude,
        if (longitude != null)  'longitude': longitude,
        'priority': priority,
      });
}
