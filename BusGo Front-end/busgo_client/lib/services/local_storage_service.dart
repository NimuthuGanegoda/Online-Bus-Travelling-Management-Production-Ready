import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Keys ──────────────────────────────────────────────
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyCurrentUserEmail = 'current_user_email';
  static const _keyRegisteredUsers = 'registered_users';
  static const _keyTripHistory = 'trip_history';
  static const _keyRatings = 'ratings';
  static const _keyEmergencyAlerts = 'emergency_alerts';
  static const _keyNotifBusArrival = 'notif_bus_arrival';
  static const _keyNotifServiceUpdates = 'notif_service_updates';
  static const _keyNotifPromotions = 'notif_promotions';
  static const _keyRecentSearches = 'recent_searches';

  // ── Session ───────────────────────────────────────────
  static bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;
  static String? get currentUserEmail => _prefs.getString(_keyCurrentUserEmail);

  static Future<void> setLoggedIn(bool value) =>
      _prefs.setBool(_keyIsLoggedIn, value);

  static Future<void> setCurrentUserEmail(String? email) {
    if (email == null) return _prefs.remove(_keyCurrentUserEmail);
    return _prefs.setString(_keyCurrentUserEmail, email);
  }

  // ── Registered Users (email -> { password, user }) ───
  static Map<String, dynamic> _getRegisteredUsers() {
    final raw = _prefs.getString(_keyRegisteredUsers);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveRegisteredUser(
      String email, String password, Map<String, dynamic> userJson) async {
    final users = _getRegisteredUsers();
    users[email] = {'password': password, 'user': userJson};
    await _prefs.setString(_keyRegisteredUsers, jsonEncode(users));
  }

  static Map<String, dynamic>? getRegisteredUser(String email) {
    final users = _getRegisteredUsers();
    if (!users.containsKey(email)) return null;
    return users[email] as Map<String, dynamic>;
  }

  static Future<void> updateUserPassword(
      String email, String newPassword) async {
    final users = _getRegisteredUsers();
    if (users.containsKey(email)) {
      (users[email] as Map<String, dynamic>)['password'] = newPassword;
      await _prefs.setString(_keyRegisteredUsers, jsonEncode(users));
    }
  }

  static Future<void> updateUserData(
      String email, Map<String, dynamic> userJson) async {
    final users = _getRegisteredUsers();
    if (users.containsKey(email)) {
      (users[email] as Map<String, dynamic>)['user'] = userJson;
      await _prefs.setString(_keyRegisteredUsers, jsonEncode(users));
    }
  }

  // ── Trip History ──────────────────────────────────────
  static List<Map<String, dynamic>> getTripHistory() {
    final raw = _prefs.getString(_keyTripHistory);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> saveTripHistory(
      List<Map<String, dynamic>> trips) async {
    await _prefs.setString(_keyTripHistory, jsonEncode(trips));
  }

  // ── Ratings ───────────────────────────────────────────
  static List<Map<String, dynamic>> getRatings() {
    final raw = _prefs.getString(_keyRatings);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> saveRatings(List<Map<String, dynamic>> ratings) async {
    await _prefs.setString(_keyRatings, jsonEncode(ratings));
  }

  // ── Emergency Alerts ──────────────────────────────────
  static List<Map<String, dynamic>> getEmergencyAlerts() {
    final raw = _prefs.getString(_keyEmergencyAlerts);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> saveEmergencyAlerts(
      List<Map<String, dynamic>> alerts) async {
    await _prefs.setString(_keyEmergencyAlerts, jsonEncode(alerts));
  }

  // ── Notification Preferences ──────────────────────────
  static bool getBusArrivalAlerts() =>
      _prefs.getBool(_keyNotifBusArrival) ?? true;
  static bool getServiceUpdates() =>
      _prefs.getBool(_keyNotifServiceUpdates) ?? true;
  static bool getPromotions() => _prefs.getBool(_keyNotifPromotions) ?? false;

  static Future<void> setBusArrivalAlerts(bool v) =>
      _prefs.setBool(_keyNotifBusArrival, v);
  static Future<void> setServiceUpdates(bool v) =>
      _prefs.setBool(_keyNotifServiceUpdates, v);
  static Future<void> setPromotions(bool v) =>
      _prefs.setBool(_keyNotifPromotions, v);

  // ── Recent Searches ───────────────────────────────────
  static List<Map<String, dynamic>> getRecentSearches() {
    final raw = _prefs.getString(_keyRecentSearches);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> saveRecentSearches(List<Map<String, dynamic>> searches) async {
    await _prefs.setString(_keyRecentSearches, jsonEncode(searches));
  }

  static Future<void> addRecentSearch(Map<String, dynamic> search) async {
    final searches = getRecentSearches();
    searches.insert(0, search);
    if (searches.length > 5) searches.removeLast(); // keep last 5
    await saveRecentSearches(searches);
  }

  // ── Clear All ─────────────────────────────────────────
  static Future<void> clearSession() async {
    await _prefs.setBool(_keyIsLoggedIn, false);
    await _prefs.remove(_keyCurrentUserEmail);
  }
}
