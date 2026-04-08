class TripModel {
  final String routeNumber;
  final String from;
  final String to;
  final String date;
  final String time;
  final String duration;
  final double fare;
  final int rating;
  final String driverName;
  final String driverId;

  const TripModel({
    required this.routeNumber,
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    this.duration = '',
    required this.fare,
    required this.rating,
    this.driverName = 'Kamal Perera',
    this.driverId = 'DRV-2841',
  });

  String get displayRoute => '$from → $to';
  String get fareDisplay => 'Rs ${fare.toStringAsFixed(0)}';
  String get dateTime =>
      duration.isNotEmpty ? '$date · $time · $duration' : '$date · $time';

  Map<String, dynamic> toJson() => {
        'routeNumber': routeNumber,
        'from': from,
        'to': to,
        'date': date,
        'time': time,
        'duration': duration,
        'fare': fare,
        'rating': rating,
        'driverName': driverName,
        'driverId': driverId,
      };

  factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
        routeNumber: json['routeNumber'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        date: json['date'] as String,
        time: json['time'] as String,
        duration: json['duration'] as String? ?? '',
        fare: (json['fare'] as num).toDouble(),
        rating: json['rating'] as int,
        driverName: json['driverName'] as String? ?? 'Kamal Perera',
        driverId: json['driverId'] as String? ?? 'DRV-2841',
      );
}
