import 'package:flutter/material.dart';
import '../models/emergency_model.dart';
import '../services/local_storage_service.dart';
import '../services/mock_data_service.dart';

class EmergencyProvider extends ChangeNotifier {
  List<EmergencyAlertModel> _alerts = [];
  int _selectedType = 0;
  String _details = '';
  bool _isLoading = false;
  bool _alertSent = false;

  List<EmergencyAlertModel> get alerts => _alerts;
  int get selectedType => _selectedType;
  String get details => _details;
  bool get isLoading => _isLoading;
  bool get alertSent => _alertSent;

  void loadAlerts() {
    final stored = LocalStorageService.getEmergencyAlerts();
    _alerts = stored.map((j) => EmergencyAlertModel.fromJson(j)).toList();
    notifyListeners();
  }

  void setSelectedType(int index) {
    _selectedType = index;
    notifyListeners();
  }

  void setDetails(String text) {
    _details = text;
  }

  Future<void> sendAlert() async {
    _isLoading = true;
    notifyListeners();

    await MockDataService.simulateNetworkDelay(ms: 1200);

    final alert = EmergencyAlertModel(
      type: MockDataService.emergencyTypes[_selectedType],
      details: _details,
      date: DateTime.now().toIso8601String(),
      status: 'Sent',
    );

    _alerts.insert(0, alert);
    await LocalStorageService.saveEmergencyAlerts(
        _alerts.map((a) => a.toJson()).toList());

    _isLoading = false;
    _alertSent = true;
    notifyListeners();
  }

  void resetForm() {
    _selectedType = 0;
    _details = '';
    _alertSent = false;
    notifyListeners();
  }
}
