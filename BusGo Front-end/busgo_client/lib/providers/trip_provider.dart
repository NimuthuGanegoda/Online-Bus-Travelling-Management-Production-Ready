import 'package:flutter/material.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/error_handler.dart';
import '../models/rating_model.dart';
import '../models/trip_model.dart';
import '../services/rating_service.dart';
import '../services/trip_service.dart';

class TripProvider extends ChangeNotifier {
  final TripService _tripService;
  final RatingService _ratingService;

  List<TripModel> _tripHistory = [];
  List<TripModel> _recentTrips = [];
  List<RatingModel> _ratings = [];
  TripModel? _ongoingTrip;

  // Rating form state
  int _selectedRating = 3;
  List<String> _selectedTags = ['Punctual', 'Safe Driving'];
  String _ratingComment = '';

  bool _isLoading = false;
  String? _errorMessage;

  TripProvider(this._tripService, this._ratingService);

  List<TripModel> get tripHistory => _tripHistory;
  List<TripModel> get recentTrips => _recentTrips;
  List<RatingModel> get ratings => _ratings;
  TripModel? get ongoingTrip => _ongoingTrip;
  int get selectedRating => _selectedRating;
  List<String> get selectedTags => _selectedTags;
  String get ratingComment => _ratingComment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalTrips => _tripHistory.length;
  double get totalSpent =>
      _tripHistory.fold(0, (sum, trip) => sum + trip.fare);
  double get averageRating {
    if (_tripHistory.isEmpty) return 0;
    return _tripHistory.fold(0, (sum, trip) => sum + trip.rating) /
        _tripHistory.length;
  }

  // ── Load ────────────────────────────────────────────────────────────────────

  Future<void> loadTripHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tripHistory = await _tripService.getTrips(status: 'completed');
      _ongoingTrip = await _findOngoingTrip();
      _recentTrips = _tripHistory.length > 2
          ? _tripHistory.sublist(0, 2)
          : _tripHistory;
    } on AppException catch (e) {
      _errorMessage = ErrorHandler.userMessage(e);
    } catch (e) {
      _errorMessage = ErrorHandler.userMessage(ErrorHandler.handle(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TripModel?> _findOngoingTrip() async {
    try {
      final ongoing = await _tripService.getTrips(status: 'ongoing');
      return ongoing.isNotEmpty ? ongoing.first : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadRatings() async {
    try {
      _ratings = await _ratingService.getMyRatings();
      notifyListeners();
    } catch (_) {}
  }

  // ── Trip actions ────────────────────────────────────────────────────────────

  Future<TripModel?> startTrip({
    required String busId,
    required String routeId,
    String? boardingStopId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final trip = await _tripService.startTrip(
        busId:          busId,
        routeId:        routeId,
        boardingStopId: boardingStopId,
      );
      _ongoingTrip = trip;
      _isLoading = false;
      notifyListeners();
      return trip;
    } on AppException catch (e) {
      _isLoading = false;
      _errorMessage = ErrorHandler.userMessage(e);
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = ErrorHandler.userMessage(ErrorHandler.handle(e));
      notifyListeners();
      return null;
    }
  }

  Future<TripModel?> alightTrip({
    String? alightingStopId,
    double? fareLkr,
  }) async {
    if (_ongoingTrip?.id == null) return null;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final trip = await _tripService.alightTrip(
        _ongoingTrip!.id!,
        alightingStopId: alightingStopId,
        fareLkr:         fareLkr,
      );
      _ongoingTrip = null;
      _tripHistory.insert(0, trip);
      _recentTrips = _tripHistory.length > 2
          ? _tripHistory.sublist(0, 2)
          : _tripHistory;
      _isLoading = false;
      notifyListeners();
      return trip;
    } on AppException catch (e) {
      _isLoading = false;
      _errorMessage = ErrorHandler.userMessage(e);
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = ErrorHandler.userMessage(ErrorHandler.handle(e));
      notifyListeners();
      return null;
    }
  }

  // ── Rating form ─────────────────────────────────────────────────────────────

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

  Future<bool> submitRating({
    required String tripId,
    required String busId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rating = await _ratingService.submitRating(
        tripId:  tripId,
        busId:   busId,
        stars:   _selectedRating,
        tags:    List.from(_selectedTags),
        comment: _ratingComment,
      );
      _ratings.insert(0, rating);
      _selectedRating = 3;
      _selectedTags = ['Punctual', 'Safe Driving'];
      _ratingComment = '';
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _isLoading = false;
      _errorMessage = ErrorHandler.userMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = ErrorHandler.userMessage(ErrorHandler.handle(e));
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
