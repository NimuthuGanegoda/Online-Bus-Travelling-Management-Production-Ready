import '../core/constants/app_colors.dart';
import '../core/utils/helpers.dart';
import '../models/bus_model.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/trip_model.dart';
import '../models/user_model.dart';

class MockDataService {
  MockDataService._();

  static const UserModel defaultUser = UserModel(
    id: 'USR-00847',
    fullName: 'Neo Red',
    email: 'neo@example.com',
    username: 'neo_red99',
    phone: '+353 87 123 4567',
    membershipType: 'Standard Member',
    memberSince: 'Jan 2024',
    totalTrips: 24,
    isActive: true,
    qrCode: 'BUSGO-2024-NR-00847',
  );

  static const List<BusModel> nearbyBuses = [
    BusModel(
      routeNumber: '138',
      routeName: 'Nugegoda – Colombo',
      from: 'Nugegoda',
      to: 'Colombo',
      stopId: '1342',
      stopName: "O'Connell St",
      distance: 0.2,
      etaMinutes: 20,
      crowdLevel: CrowdLevel.low,
      routeColor: AppColors.secondary,
      driverName: 'Kamal Perera',
      driverId: 'DRV-2841',
      driverRating: 4.2,
      passengerCount: 12,
      capacity: 40,
    ),
    BusModel(
      routeNumber: '163',
      routeName: 'Rajagiriya – Maharagama',
      from: 'Rajagiriya',
      to: 'Maharagama',
      stopId: '1198',
      stopName: 'Parnell Sq',
      distance: 0.5,
      etaMinutes: 30,
      crowdLevel: CrowdLevel.moderate,
      routeColor: AppColors.warning,
      driverName: 'Kamal Perera',
      driverId: 'DRV-1923',
      driverRating: 4.5,
      passengerCount: 24,
      capacity: 40,
    ),
  ];

  static const List<StopModel> nearbyStops = [
    StopModel(
      stopId: '201',
      name: 'Petta',
      distance: 0.3,
      routes: ['138', '100', '01'],
    ),
    StopModel(
      stopId: '305',
      name: 'Boralla',
      distance: 0.6,
      routes: ['163', '138', '171'],
    ),
  ];

  static const List<BusRoute> searchResults = [
    BusRoute(
      routeNumber: '138',
      from: 'Rajagiriya',
      to: 'Nugegoda',
      stopCount: 12,
      durationMinutes: 25,
      etaMinutes: 15,
      routeColor: AppColors.secondary,
    ),
    BusRoute(
      routeNumber: '100',
      from: 'Colombo',
      to: 'Moratuwa',
      stopCount: 18,
      durationMinutes: 40,
      etaMinutes: 8,
      routeColor: AppColors.success,
    ),
    BusRoute(
      routeNumber: '163',
      from: 'Rajagiriya',
      to: 'Maharagama',
      stopCount: 15,
      durationMinutes: 30,
      etaMinutes: 22,
      routeColor: AppColors.warning,
    ),
    BusRoute(
      routeNumber: '01',
      from: 'Kandy',
      to: 'Colombo',
      stopCount: 42,
      durationMinutes: 240,
      etaMinutes: 5,
      routeColor: AppColors.danger,
    ),
    BusRoute(
      routeNumber: '171',
      from: 'Borella',
      to: 'Kaduwela',
      stopCount: 20,
      durationMinutes: 35,
      etaMinutes: 12,
      routeColor: AppColors.secondary,
    ),
  ];

  /// All known destination names for search suggestions
  static const List<String> allDestinations = [
    'Nugegoda', 'Moratuwa', 'Maharagama', 'Colombo', 'Kandy',
    'Kaduwela', 'Rajagiriya', 'Petta', 'Borella', 'Kollupitiya',
    'Bambalapitiya', 'Wellawatte', 'Dehiwala', 'Mount Lavinia',
    'Kottawa', 'Negombo', 'Galle', 'Matara', 'Panadura',
  ];

  static const List<TripModel> recentTripsShort = [
    TripModel(
      routeNumber: '163',
      from: 'Maharagama',
      to: 'Rajagiriya',
      date: 'Yesterday',
      time: '14:32',
      duration: '30 mins',
      fare: 80,
      rating: 4,
    ),
    TripModel(
      routeNumber: '100',
      from: 'Kottawa',
      to: 'Colombo',
      date: 'Mon 17 Mar',
      time: '08:50',
      duration: '45 mins',
      fare: 120,
      rating: 4,
    ),
  ];

  static const List<TripModel> tripHistory = [
    TripModel(
      routeNumber: '138',
      from: 'Nugegoda',
      to: 'Petta',
      date: 'Today',
      time: '09:15',
      duration: '20 mins',
      fare: 70,
      rating: 4,
      driverName: 'Kamal Perera',
      driverId: 'DRV-2841',
    ),
    TripModel(
      routeNumber: '240',
      from: 'Negombo',
      to: 'Colombo',
      date: 'Yesterday',
      time: '14:32',
      duration: '1 hr 30 mins',
      fare: 250,
      rating: 3,
    ),
    TripModel(
      routeNumber: '144',
      from: 'Rajagiriya',
      to: 'Kollupitiya',
      date: 'Mon 17 Mar',
      time: '08:50',
      duration: '20 mins',
      fare: 50,
      rating: 4,
    ),
    TripModel(
      routeNumber: '100',
      from: 'Colombo',
      to: 'Moratuwa',
      date: 'Sun 16 Mar',
      time: '18:04',
      duration: '30 mins',
      fare: 150,
      rating: 4,
    ),
    TripModel(
      routeNumber: '01',
      from: 'Kandy',
      to: 'Colombo',
      date: 'Sat 15 Mar',
      time: '11:20',
      duration: '4 hrs',
      fare: 800,
      rating: 3,
    ),
  ];

  static const List<String> emergencyTypes = [
    '🏥 Medical Emergency',
    '🔪 Criminal Activity',
    '🔧 Bus Breakdown',
    '😰 Harassment',
    '📢 Other',
  ];

  static const List<String> ratingTags = [
    'Punctual',
    'Safe Driving',
    'Friendly',
    'Clean Bus',
    'Helpful',
  ];

  /// Simulates an API call delay
  static Future<void> simulateNetworkDelay({int ms = 800}) async {
    await Future.delayed(Duration(milliseconds: ms));
  }
}
