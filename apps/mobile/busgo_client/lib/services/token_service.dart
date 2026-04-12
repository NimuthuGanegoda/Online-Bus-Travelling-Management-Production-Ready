import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';

/// Manages JWT access + refresh token storage and automatic token rotation.
///
/// Storage backend:
///   • Mobile / Desktop → [FlutterSecureStorage] (hardware-backed encryption)
///   • Web             → [SharedPreferences]     (localStorage; avoids the
///                        Web Crypto OperationError thrown by FlutterSecureStorage
///                        when the page is not served over a secure context or
///                        when IndexedDB crypto operations are unavailable)
class TokenService {
  static const _keyAccess  = 'busgo_access_token';
  static const _keyRefresh = 'busgo_refresh_token';

  // Mobile / desktop storage (null on web)
  final FlutterSecureStorage? _secure;

  TokenService()
      : _secure = kIsWeb
            ? null
            : const FlutterSecureStorage(
                aOptions: AndroidOptions(encryptedSharedPreferences: true),
              );

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secure!.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return _secure!.read(key: key);
    }
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _secure!.delete(key: key);
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _write(_keyAccess,  accessToken),
      _write(_keyRefresh, refreshToken),
    ]);
  }

  Future<String?> getAccessToken()  => _read(_keyAccess);
  Future<String?> getRefreshToken() => _read(_keyRefresh);

  Future<void> clearTokens() async {
    await Future.wait([
      _delete(_keyAccess),
      _delete(_keyRefresh),
    ]);
  }

  Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Token rotation ────────────────────────────────────────────────────────

  /// Exchange the stored refresh token for a new access + refresh pair.
  /// Saves the new tokens and returns the new access token.
  /// Throws [SessionExpiredException] if the refresh token is invalid/expired.
  Future<String> refreshTokens() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const SessionExpiredException();
    }

    // Use a bare Dio instance (no interceptors) to avoid infinite loops.
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
    ));

    try {
      final response = await dio.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      final newAccess  = data['access_token']  as String;
      final newRefresh = data['refresh_token'] as String;

      await saveTokens(newAccess, newRefresh);
      return newAccess;
    } on DioException {
      await clearTokens();
      throw const SessionExpiredException();
    }
  }
}
