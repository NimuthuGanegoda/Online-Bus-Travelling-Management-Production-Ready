import 'package:flutter/material.dart';
import '../models/alert_model.dart';

class EmergencyProvider extends ChangeNotifier {
  Alert? _activeAlert;
  String? _selectedType;
  String _description = '';
  bool _isSending = false;
  bool _isSent = false;

  Alert? get activeAlert => _activeAlert;
  String? get selectedType => _selectedType;
  String get description => _description;
  bool get isSending => _isSending;
  bool get isSent => _isSent;
  bool get hasActiveAlert => _activeAlert != null;

  void selectType(String type) {
    _selectedType = type;
    notifyListeners();
  }

  void setDescription(String desc) {
    _description = desc;
  }

  Future<void> sendAlert({
    required String driverId,
    required String tripId,
    required double latitude,
    required double longitude,
  }) async {
    if (_selectedType == null) return;

    _isSending = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _activeAlert = Alert(
      id: 'ALR-${DateTime.now().millisecondsSinceEpoch}',
      type: _selectedType!,
      description: _description,
      driverId: driverId,
      tripId: tripId,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      status: AlertStatus.sent,
    );

    _isSending = false;
    _isSent = true;
    notifyListeners();
  }

  void cancelAlert() {
    if (_activeAlert != null) {
      _activeAlert = _activeAlert!.copyWith(status: AlertStatus.cancelled);
    }
    _activeAlert = null;
    _isSent = false;
    notifyListeners();
  }

  void reset() {
    _activeAlert = null;
    _selectedType = null;
    _description = '';
    _isSending = false;
    _isSent = false;
    notifyListeners();
  }
}
