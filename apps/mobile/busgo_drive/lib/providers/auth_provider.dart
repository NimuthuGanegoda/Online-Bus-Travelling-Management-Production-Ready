import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Driver? _driver;
  bool _isLoading = false;
  String? _error;

  Driver? get driver => _driver;
  bool get isLoggedIn => _driver != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _api = ApiService();

  /// Try to restore session from stored token on app start.
  Future<void> tryRestoreSession() async {
    final token = await _api.getToken();
    if (token == null) return;

    try {
      final res = await _api.getMe();
      final data = res.data['data'];
      _driver = _mapDriver(data);
      notifyListeners();
    } catch (_) {
      // Token expired or invalid — clear it
      await _api.clearToken();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.login(email, password);
      final data = res.data['data'];
      await _api.saveToken(data['access_token'] as String);
      _driver = _mapDriver(data['driver']);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Login failed. Check your credentials.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Connection error. Make sure the server is running.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String nic = '',
    String licenseNumber = '',
    String licenseExpiry = '',
    List<String> areas = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.register(
        fullName: name,
        email:    email,
        phone:    phone,
        password: password,
      );
      // Do NOT save token or set driver — account is pending admin approval.
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Registration failed.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Connection error. Make sure the server is running.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    _driver = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Driver _mapDriver(Map<String, dynamic> d) {
    final route = d['bus_routes'];
    return Driver(
      id:            d['id']          as String,
      employeeId:    d['driver_code'] as String,
      name:          d['full_name']   as String,
      email:         d['email']       as String,
      phone:         (d['phone']      as String?) ?? '',
      licenseNumber: '',
      licenseExpiry: '',
      rating:        (d['rating']     as num?)?.toDouble() ?? 0.0,
      status:        d['status']      as String? ?? 'pending',
      vehicleId:     route?['id']     as String? ?? '',
      vehiclePlate:  '',
      vehicleModel:  '',
    );
  }
}
