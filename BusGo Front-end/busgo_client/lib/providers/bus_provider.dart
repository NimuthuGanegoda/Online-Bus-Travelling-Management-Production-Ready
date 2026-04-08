import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../services/mock_data_service.dart';

class BusProvider extends ChangeNotifier {
  List<BusModel> _nearbyBuses = [];
  List<StopModel> _nearbyStops = [];
  List<BusRoute> _searchResults = [];
  BusModel? _selectedBus;
  bool _isLoading = false;
  String _searchQuery = '';

  List<BusModel> get nearbyBuses => _nearbyBuses;
  List<StopModel> get nearbyStops => _nearbyStops;
  List<BusRoute> get searchResults => _searchResults;
  BusModel? get selectedBus => _selectedBus;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  /// Filter search results by destination query
  void searchByDestination(String query) {
    _searchQuery = query;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _searchResults = MockDataService.searchResults.toList();
    } else {
      _searchResults = MockDataService.searchResults
          .where((r) =>
              r.to.toLowerCase().contains(q) ||
              r.from.toLowerCase().contains(q) ||
              r.routeNumber.toLowerCase().contains(q))
          .toList();
    }
    notifyListeners();
  }

  /// Get destination suggestions matching query
  List<String> getDestinationSuggestions(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return MockDataService.allDestinations
        .where((d) => d.toLowerCase().contains(q))
        .toList();
  }

  void loadNearbyBuses() {
    _nearbyBuses = MockDataService.nearbyBuses.toList();
    notifyListeners();
  }

  void loadNearbyStops() {
    _nearbyStops = MockDataService.nearbyStops.toList();
    notifyListeners();
  }

  void loadSearchResults() {
    _searchResults = MockDataService.searchResults.toList();
    notifyListeners();
  }

  void selectBus(BusModel bus) {
    _selectedBus = bus;
    notifyListeners();
  }

  void clearSelection() {
    _selectedBus = null;
    notifyListeners();
  }

  void loadAll() {
    _isLoading = true;
    notifyListeners();

    _nearbyBuses = MockDataService.nearbyBuses.toList();
    _nearbyStops = MockDataService.nearbyStops.toList();
    _searchResults = MockDataService.searchResults.toList();
    _selectedBus = _nearbyBuses.isNotEmpty ? _nearbyBuses[0] : null;

    _isLoading = false;
    notifyListeners();
  }
}
