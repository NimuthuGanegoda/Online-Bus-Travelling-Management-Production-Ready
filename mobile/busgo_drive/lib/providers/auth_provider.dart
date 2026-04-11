import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../services/mock_data_service.dart';

class AuthProvider extends ChangeNotifier {
  Driver? _driver;
  bool _isLoading = false;
  String? _error;
  bool _rememberMe = false;

  // Store registered drivers (email -> {password, driver})
  final Map<String, Map<String, dynamic>> _registeredDrivers = {};

  Driver? get driver => _driver;
  bool get isLoggedIn => _driver != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get rememberMe => _rememberMe;

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  Future<bool> login(String employeeId, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1200));

    if (employeeId.isEmpty || password.isEmpty) {
      _isLoading = false;
      _error = 'Please enter both Employee ID and Password';
      notifyListeners();
      return false;
    }

    // Demo credentials
    if ((employeeId == 'EMP-4521' && password == 'driver123') ||
        (employeeId == 'sarasi' && password == '12345678')) {
      _driver = MockDataService.currentDriver;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    // Check registered drivers (login by email or employee ID)
    for (final entry in _registeredDrivers.values) {
      final driver = entry['driver'] as Driver;
      final storedPassword = entry['password'] as String;
      if ((employeeId == driver.email || employeeId == driver.employeeId) &&
          password == storedPassword) {
        _driver = driver;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    }

    _isLoading = false;
    _error = 'Invalid credentials. Use your email or Employee ID to login.';
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String name,
    required String nic,
    required String licenseNumber,
    required String licenseExpiry,
    required String email,
    required String phone,
    required String password,
    required List<String> areas,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _isLoading = false;
      _error = 'All required fields must be filled';
      notifyListeners();
      return false;
    }

    if (password.length < 8) {
      _isLoading = false;
      _error = 'Password must be at least 8 characters';
      notifyListeners();
      return false;
    }

    if (_registeredDrivers.containsKey(email)) {
      _isLoading = false;
      _error = 'An account with this email already exists';
      notifyListeners();
      return false;
    }

    // Create driver and auto-approve (no admin yet)
    final empId = 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final drvId = 'DRV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    final newDriver = Driver(
      id: drvId,
      employeeId: empId,
      name: name,
      email: email,
      phone: phone,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      rating: 0.0,
      tripsCompleted: 0,
      hoursLogged: 0,
      status: 'active',
    );

    _registeredDrivers[email] = {
      'password': password,
      'driver': newDriver,
    };

    _isLoading = false;
    notifyListeners();
    return true;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void logout() {
    _driver = null;
    _error = null;
    notifyListeners();
  }
}
