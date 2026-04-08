import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/mock_data_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel _user = MockDataService.defaultUser;

  bool _busArrivalAlerts = true;
  bool _serviceUpdates = true;
  bool _promotions = false;

  UserModel get user => _user;
  bool get busArrivalAlerts => _busArrivalAlerts;
  bool get serviceUpdates => _serviceUpdates;
  bool get promotions => _promotions;

  /// Load notification preferences from local storage
  void loadPreferences() {
    _busArrivalAlerts = LocalStorageService.getBusArrivalAlerts();
    _serviceUpdates = LocalStorageService.getServiceUpdates();
    _promotions = LocalStorageService.getPromotions();
    notifyListeners();
  }

  /// Load user data from a given UserModel (from AuthProvider)
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  /// Load user from local storage by email
  void loadUserFromStorage(String email) {
    final entry = LocalStorageService.getRegisteredUser(email);
    if (entry != null) {
      _user = UserModel.fromJson(entry['user'] as Map<String, dynamic>);
      notifyListeners();
    }
  }

  void toggleBusArrivalAlerts() {
    _busArrivalAlerts = !_busArrivalAlerts;
    LocalStorageService.setBusArrivalAlerts(_busArrivalAlerts);
    notifyListeners();
  }

  void toggleServiceUpdates() {
    _serviceUpdates = !_serviceUpdates;
    LocalStorageService.setServiceUpdates(_serviceUpdates);
    notifyListeners();
  }

  void togglePromotions() {
    _promotions = !_promotions;
    LocalStorageService.setPromotions(_promotions);
    notifyListeners();
  }

  Future<void> updateUser(UserModel updatedUser) async {
    _user = updatedUser;
    await LocalStorageService.updateUserData(
        updatedUser.email, updatedUser.toJson());
    notifyListeners();
  }
}
