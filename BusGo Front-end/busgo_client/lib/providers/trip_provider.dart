import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../models/rating_model.dart';
import '../services/local_storage_service.dart';
import '../services/mock_data_service.dart';

class TripProvider extends ChangeNotifier {
  List<TripModel> _tripHistory = [];
  List<TripModel> _recentTrips = [];
  List<RatingModel> _ratings = [];
  int _selectedRating = 3;
  List<String> _selectedTags = ['Punctual', 'Safe Driving'];
  String _ratingComment = '';

  List<TripModel> get tripHistory => _tripHistory;
  List<TripModel> get recentTrips => _recentTrips;
  List<RatingModel> get ratings => _ratings;
  int get selectedRating => _selectedRating;
  List<String> get selectedTags => _selectedTags;
  String get ratingComment => _ratingComment;

  int get totalTrips => _tripHistory.length;
  double get totalSpent =>
      _tripHistory.fold(0, (sum, trip) => sum + trip.fare);
  double get averageRating {
    if (_tripHistory.isEmpty) return 0;
    return _tripHistory.fold(0, (sum, trip) => sum + trip.rating) /
        _tripHistory.length;
  }

  /// Load trip history from local storage, seeding with mock data if empty
  void loadTripHistory() {
    final stored = LocalStorageService.getTripHistory();
    if (stored.isNotEmpty) {
      _tripHistory = stored.map((j) => TripModel.fromJson(j)).toList();
    } else {
      _tripHistory = MockDataService.tripHistory.toList();
      _saveTripHistory();
    }
    _recentTrips =
        _tripHistory.length > 2 ? _tripHistory.sublist(0, 2) : _tripHistory;
    _loadRatings();
    notifyListeners();
  }

  void _loadRatings() {
    final stored = LocalStorageService.getRatings();
    _ratings = stored.map((j) => RatingModel.fromJson(j)).toList();
  }

  Future<void> _saveTripHistory() async {
    await LocalStorageService.saveTripHistory(
        _tripHistory.map((t) => t.toJson()).toList());
  }

  Future<void> _saveRatings() async {
    await LocalStorageService.saveRatings(
        _ratings.map((r) => r.toJson()).toList());
  }

  void setRating(int rating) {
    _selectedRating = rating;
    notifyListeners();
  }

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  void setComment(String comment) {
    _ratingComment = comment;
  }

  /// Submit a rating and persist it
  Future<void> submitRating({
    String routeNumber = '39A',
    String driverName = 'John Murphy',
    String driverId = 'DRV-2841',
  }) async {
    final rating = RatingModel(
      tripRouteNumber: routeNumber,
      driverName: driverName,
      driverId: driverId,
      rating: _selectedRating,
      tags: List<String>.from(_selectedTags),
      comment: _ratingComment,
      date: DateTime.now().toIso8601String(),
    );
    _ratings.add(rating);
    await _saveRatings();

    // Reset form
    _selectedRating = 3;
    _selectedTags = ['Punctual', 'Safe Driving'];
    _ratingComment = '';
    notifyListeners();
  }

  /// Add a new trip and persist
  Future<void> addTrip(TripModel trip) async {
    _tripHistory.insert(0, trip);
    _recentTrips =
        _tripHistory.length > 2 ? _tripHistory.sublist(0, 2) : _tripHistory;
    await _saveTripHistory();
    notifyListeners();
  }
}
