import '../core/utils/helpers.dart';

class Trip {
  final String id;
  final String routeId;
  final String routeNumber;
  final String routeName;
  final String driverId;
  final DateTime startTime;
  final DateTime? endTime;
  final int passengersBoarded;
  final int passengersAlighted;
  final int currentPassengers;
  final int stopsCompleted;
  final int totalStops;
  final double distanceCovered;
  final double totalDistance;
  final double avgSpeed;
  final TripStatus status;

  const Trip({
    required this.id,
    required this.routeId,
    required this.routeNumber,
    required this.routeName,
    required this.driverId,
    required this.startTime,
    this.endTime,
    this.passengersBoarded = 0,
    this.passengersAlighted = 0,
    this.currentPassengers = 0,
    this.stopsCompleted = 0,
    required this.totalStops,
    this.distanceCovered = 0,
    required this.totalDistance,
    this.avgSpeed = 0,
    this.status = TripStatus.active,
  });

  String get duration {
    final end = endTime ?? DateTime.now();
    final diff = end.difference(startTime);
    return Helpers.formatDuration(diff.inMinutes);
  }

  double get progress =>
      totalStops > 0 ? stopsCompleted / totalStops : 0;

  String get distanceDisplay =>
      '${distanceCovered.toStringAsFixed(1)} / ${totalDistance.toStringAsFixed(1)} km';

  String get passengerDisplay => '$currentPassengers';

  Trip copyWith({
    int? passengersBoarded,
    int? passengersAlighted,
    int? currentPassengers,
    int? stopsCompleted,
    double? distanceCovered,
    double? avgSpeed,
    TripStatus? status,
    DateTime? endTime,
  }) {
    return Trip(
      id: id,
      routeId: routeId,
      routeNumber: routeNumber,
      routeName: routeName,
      driverId: driverId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      passengersBoarded: passengersBoarded ?? this.passengersBoarded,
      passengersAlighted: passengersAlighted ?? this.passengersAlighted,
      currentPassengers: currentPassengers ?? this.currentPassengers,
      stopsCompleted: stopsCompleted ?? this.stopsCompleted,
      totalStops: totalStops,
      distanceCovered: distanceCovered ?? this.distanceCovered,
      totalDistance: totalDistance,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      status: status ?? this.status,
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      routeId: json['route_id'] as String,
      routeNumber: json['route_number'] as String,
      routeName: json['route_name'] as String,
      driverId: json['driver_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      passengersBoarded: json['passengers_boarded'] as int? ?? 0,
      passengersAlighted: json['passengers_alighted'] as int? ?? 0,
      currentPassengers: json['current_passengers'] as int? ?? 0,
      stopsCompleted: json['stops_completed'] as int? ?? 0,
      totalStops: json['total_stops'] as int,
      distanceCovered:
          (json['distance_covered'] as num?)?.toDouble() ?? 0,
      totalDistance: (json['total_distance'] as num).toDouble(),
      avgSpeed: (json['avg_speed'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'route_id': routeId,
    'route_number': routeNumber,
    'route_name': routeName,
    'driver_id': driverId,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'passengers_boarded': passengersBoarded,
    'passengers_alighted': passengersAlighted,
    'current_passengers': currentPassengers,
    'stops_completed': stopsCompleted,
    'total_stops': totalStops,
    'distance_covered': distanceCovered,
    'total_distance': totalDistance,
    'avg_speed': avgSpeed,
    'status': status.name,
  };
}
