import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Resolves the right backend host depending on platform:
///   Web (Chrome)     → localhost (same machine as backend)
///   Android emulator → 10.0.2.2 (alias for host machine)
///   Physical device  → set your laptop's LAN IP here
String get _baseUrl {
  if (kIsWeb) return 'http://localhost:5000/api';
  return 'http://10.0.2.2:5000/api';
}

/// Result of a successful driver-auth login.
class LoginResult {
  final String accessToken;
  final String fullName;
  final String? routeNumber;
  final String? routeName;

  LoginResult({
    required this.accessToken,
    required this.fullName,
    this.routeNumber,
    this.routeName,
  });
}

/// Result of a successful QR scan (boarding or alighting).
class ScanResult {
  final String action;       // 'boarded' | 'alighted'
  final String passengerName;
  final String? busNumber;
  final String? routeNumber;
  final double? fare;
  final String message;
  final int? onBoard;        // Live on-board count after this scan
  final int? capacity;

  ScanResult({
    required this.action,
    required this.passengerName,
    this.busNumber,
    this.routeNumber,
    this.fare,
    required this.message,
    this.onBoard,
    this.capacity,
  });
}

/// Thrown for any API failure — caught by screens to show error UI.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  ApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;
}

class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const _tokenKey = 'busgo_scanner_driver_token';
  static const _nameKey  = 'busgo_scanner_driver_name';
  static const _routeKey = 'busgo_scanner_driver_route';

  String? _accessToken;

  // ── Token storage ─────────────────────────────────────────────

  Future<void> _saveSession(LoginResult result) async {
    _accessToken = result.accessToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, result.accessToken);
    await prefs.setString(_nameKey, result.fullName);
    if (result.routeNumber != null) {
      await prefs.setString(_routeKey, result.routeNumber!);
    }
  }

  Future<void> clearSession() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_routeKey);
  }

  Future<String?> getStoredToken() async {
    if (_accessToken != null) return _accessToken;
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);
    return _accessToken;
  }

  Future<String?> getStoredDriverName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  // ── Auth (FR-37 to FR-41) ──────────────────────────────────────

  /// Login using the existing driver-auth endpoint. The scanner is
  /// driver-operated so it shares credentials with the BUSGO Drive app.
  Future<LoginResult> login(String emailOrCode, String password) async {
    final body = jsonEncode({'email': emailOrCode.trim(), 'password': password});
    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('$_baseUrl/driver/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw ApiException('Cannot reach the server. Check your connection.');
    }

    final json = _safeDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && json['success'] == true) {
      final data = (json['data'] ?? {}) as Map<String, dynamic>;
      final driver = (data['driver'] ?? {}) as Map<String, dynamic>;
      final route = driver['bus_routes'] as Map<String, dynamic>?;
      final result = LoginResult(
        accessToken: data['access_token'] as String,
        fullName:    (driver['full_name'] as String?) ?? 'Driver',
        routeNumber: route?['route_number'] as String?,
        routeName:   route?['route_name'] as String?,
      );
      await _saveSession(result);
      return result;
    }

    throw ApiException(
      (json['message'] as String?) ?? 'Login failed',
      statusCode: res.statusCode,
      code:       json['code'] as String?,
    );
  }

  // ── Driver profile (used to seed the on-board count) ──────────

  /// Live on-board passenger count for the driver's bus, computed by the
  /// backend from the count of `trips.status='ongoing'` for this bus.
  Future<({int passengers, int capacity})?> getOnBoardCount() async {
    final token = await getStoredToken();
    if (token == null) throw ApiException('Not signed in');

    http.Response res;
    try {
      res = await http
          .get(
            Uri.parse('$_baseUrl/scanner/onboard'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw ApiException('Cannot reach the server.');
    }

    final json = _safeDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw ApiException(
        (json['message'] as String?) ?? 'Could not load on-board count',
        statusCode: res.statusCode,
      );
    }

    final data = (json['data'] ?? {}) as Map<String, dynamic>;
    return (
      passengers: (data['on_board'] as num?)?.toInt() ?? 0,
      capacity:   (data['capacity'] as num?)?.toInt() ?? 50,
    );
  }

  // ── Scan (FR-43) ───────────────────────────────────────────────

  /// Send a scanned QR payload to the backend. Returns whether the
  /// passenger boarded or alighted, plus a verifying message.
  Future<ScanResult> scan(String qrCode) async {
    final token = await getStoredToken();
    if (token == null) throw ApiException('Not signed in');

    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('$_baseUrl/scanner/scan'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'qr_code': qrCode}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw ApiException('Cannot reach the server. Check your connection.');
    }

    final json = _safeDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && json['success'] == true) {
      final data = (json['data'] ?? {}) as Map<String, dynamic>;
      final passenger = (data['passenger'] ?? {}) as Map<String, dynamic>;
      final bus = (data['bus'] ?? {}) as Map<String, dynamic>;
      final trip = (data['trip'] ?? {}) as Map<String, dynamic>;
      return ScanResult(
        action:        (data['action'] as String?) ?? 'boarded',
        passengerName: (passenger['name'] as String?) ?? 'Passenger',
        busNumber:     bus['number'] as String?,
        routeNumber:   bus['route'] as String?,
        fare:          (trip['fare_lkr'] as num?)?.toDouble(),
        message:       (data['message'] as String?) ?? (json['message'] as String? ?? 'Scan recorded'),
        onBoard:       (bus['on_board'] as num?)?.toInt(),
        capacity:      (bus['capacity'] as num?)?.toInt(),
      );
    }

    throw ApiException(
      (json['message'] as String?) ?? 'Scan failed',
      statusCode: res.statusCode,
      code:       json['code'] as String?,
    );
  }

  Map<String, dynamic> _safeDecode(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {/* fall through */}
    return {};
  }
}
