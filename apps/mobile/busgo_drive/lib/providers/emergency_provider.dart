import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';

class EmergencyProvider extends ChangeNotifier {
  Alert? _activeAlert;
  String? _selectedType;
  String _description = '';
  bool _isSending = false;
  bool _isSent = false;
  String? _error;

  Alert? get activeAlert => _activeAlert;
  String? get selectedType => _selectedType;
  String get description => _description;
  bool get isSending => _isSending;
  bool get isSent => _isSent;
  bool get hasActiveAlert => _activeAlert != null;
  String? get error => _error;

  final _api = ApiService();

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
    _error = null;
    notifyListeners();

    try {
      final res = await _api.sendEmergency(
        alertType:   _selectedType!,
        description: _description.isNotEmpty ? _description : null,
        latitude:    latitude,
        longitude:   longitude,
      );

      final data = res.data['data'] as Map<String, dynamic>;

      _activeAlert = Alert(
        id:          data['id']         as String,
        type:        data['alert_type'] as String,
        description: data['description'] as String? ?? _description,
        driverId:    driverId,
        tripId:      tripId,
        latitude:    latitude,
        longitude:   longitude,
        timestamp:   DateTime.now(),
        status:      AlertStatus.sent,
      );

      _isSent = true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to send alert.';
    } catch (_) {
      _error = 'Connection error. Alert not sent.';
    }

    _isSending = false;
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
    _error = null;
    notifyListeners();
  }
}
