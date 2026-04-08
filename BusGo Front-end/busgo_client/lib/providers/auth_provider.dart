import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/mock_data_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  // Forgot password state
  int _forgotPasswordStep = 0;
  String _forgotEmail = '';
  String _pinCode = '';
  String _generatedPin = '';

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  int get forgotPasswordStep => _forgotPasswordStep;
  String get forgotEmail => _forgotEmail;
  String get pinCode => _pinCode;
  String get generatedPin => _generatedPin;

  /// Check stored session on app start
  Future<void> checkSession() async {
    if (LocalStorageService.isLoggedIn) {
      final email = LocalStorageService.currentUserEmail;
      if (email != null) {
        final entry = LocalStorageService.getRegisteredUser(email);
        if (entry != null) {
          _currentUser =
              UserModel.fromJson(entry['user'] as Map<String, dynamic>);
          _isLoggedIn = true;
          notifyListeners();
          return;
        }
      }
    }
    _isLoggedIn = false;
    notifyListeners();
  }

  /// Login with email + password against locally stored users
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await MockDataService.simulateNetworkDelay();

    if (email.isEmpty || password.isEmpty) {
      _isLoading = false;
      _errorMessage = 'Email and password are required.';
      notifyListeners();
      return false;
    }

    if (email == 'admin@gmail.com' && password == '12345678') {
      _currentUser = MockDataService.defaultUser;
      _isLoggedIn = true;
      _isLoading = false;
      await LocalStorageService.setLoggedIn(true);
      await LocalStorageService.setCurrentUserEmail(email);
      if (LocalStorageService.getRegisteredUser(email) == null) {
        await LocalStorageService.saveRegisteredUser(
          email, password, MockDataService.defaultUser.toJson());
      }
      notifyListeners();
      return true;
    }

    final entry = LocalStorageService.getRegisteredUser(email);
    if (entry == null) {
      _isLoading = false;
      _errorMessage = 'No account found with this email.';
      notifyListeners();
      return false;
    }

    if (entry['password'] != password) {
      _isLoading = false;
      _errorMessage = 'Incorrect password. Please try again.';
      notifyListeners();
      return false;
    }

    _currentUser =
        UserModel.fromJson(entry['user'] as Map<String, dynamic>);
    _isLoggedIn = true;
    _isLoading = false;

    await LocalStorageService.setLoggedIn(true);
    await LocalStorageService.setCurrentUserEmail(email);

    notifyListeners();
    return true;
  }

  /// Register a new user and persist locally
  Future<bool> register({
    required String fullName,
    required String email,
    required String username,
    required String phone,
    required String password,
    String? dateOfBirth,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await MockDataService.simulateNetworkDelay();

    // Validate
    if (fullName.isEmpty ||
        email.isEmpty ||
        username.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      _isLoading = false;
      _errorMessage = 'All fields are required.';
      notifyListeners();
      return false;
    }

    if (password.length < 8) {
      _isLoading = false;
      _errorMessage = 'Password must be at least 8 characters.';
      notifyListeners();
      return false;
    }

    // Check duplicate email
    if (LocalStorageService.getRegisteredUser(email) != null) {
      _isLoading = false;
      _errorMessage = 'An account with this email already exists.';
      notifyListeners();
      return false;
    }

    // Generate user
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final userId =
        'USR-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final qrCode =
        'BUSGO-${now.year}-${username.substring(0, 2).toUpperCase()}-$userId';

    final user = UserModel(
      id: userId,
      fullName: fullName,
      email: email,
      username: username,
      phone: phone,
      dateOfBirth: dateOfBirth,
      membershipType: 'Standard Member',
      memberSince: '${months[now.month - 1]} ${now.year}',
      totalTrips: 0,
      isActive: true,
      qrCode: qrCode,
    );

    await LocalStorageService.saveRegisteredUser(
        email, password, user.toJson());
    await LocalStorageService.setLoggedIn(true);
    await LocalStorageService.setCurrentUserEmail(email);

    _currentUser = user;
    _isLoggedIn = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Seed default mock user on first run
  Future<void> seedDefaultUser() async {
    final existing =
        LocalStorageService.getRegisteredUser('neo@example.com');
    if (existing == null) {
      await LocalStorageService.saveRegisteredUser(
        'neo@example.com',
        '12345678',
        MockDataService.defaultUser.toJson(),
      );
    }
  }

  // ── Forgot Password Flow ──────────────────────────────

  Future<bool> sendResetPin(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await MockDataService.simulateNetworkDelay(ms: 600);

    if (email.isEmpty) {
      _isLoading = false;
      _errorMessage = 'Please enter your email address.';
      notifyListeners();
      return false;
    }

    final entry = LocalStorageService.getRegisteredUser(email);
    if (entry == null) {
      _isLoading = false;
      _errorMessage = 'No account found with this email.';
      notifyListeners();
      return false;
    }

    // Generate a 6-digit PIN
    _generatedPin = '379142';
    _forgotEmail = email;
    _forgotPasswordStep = 1;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> verifyPin(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await MockDataService.simulateNetworkDelay(ms: 500);

    if (pin.length != 6) {
      _isLoading = false;
      _errorMessage = 'Please enter all 6 digits.';
      notifyListeners();
      return false;
    }

    if (pin != _generatedPin) {
      _isLoading = false;
      _errorMessage = 'Invalid PIN. Please try again.';
      notifyListeners();
      return false;
    }

    _pinCode = pin;
    _forgotPasswordStep = 2;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> resetPassword(
      String newPassword, String confirmPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await MockDataService.simulateNetworkDelay(ms: 600);

    if (newPassword.length < 8) {
      _isLoading = false;
      _errorMessage = 'Password must be at least 8 characters.';
      notifyListeners();
      return false;
    }

    if (newPassword != confirmPassword) {
      _isLoading = false;
      _errorMessage = 'Passwords do not match.';
      notifyListeners();
      return false;
    }

    await LocalStorageService.updateUserPassword(_forgotEmail, newPassword);

    _forgotPasswordStep = 0;
    _forgotEmail = '';
    _pinCode = '';
    _generatedPin = '';
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void resetForgotPassword() {
    _forgotPasswordStep = 0;
    _forgotEmail = '';
    _pinCode = '';
    _generatedPin = '';
    _errorMessage = null;
    notifyListeners();
  }

  /// Logout and clear session
  Future<void> logout() async {
    await LocalStorageService.clearSession();
    _isLoggedIn = false;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
