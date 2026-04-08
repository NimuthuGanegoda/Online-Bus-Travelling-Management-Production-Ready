class RatingModel {
  final String tripRouteNumber;
  final String driverName;
  final String driverId;
  final int rating;
  final List<String> tags;
  final String comment;
  final String date;

  const RatingModel({
    required this.tripRouteNumber,
    required this.driverName,
    required this.driverId,
    required this.rating,
    required this.tags,
    this.comment = '',
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'tripRouteNumber': tripRouteNumber,
        'driverName': driverName,
        'driverId': driverId,
        'rating': rating,
        'tags': tags,
        'comment': comment,
        'date': date,
      };

  factory RatingModel.fromJson(Map<String, dynamic> json) => RatingModel(
        tripRouteNumber: json['tripRouteNumber'] as String,
        driverName: json['driverName'] as String,
        driverId: json['driverId'] as String,
        rating: json['rating'] as int,
        tags: (json['tags'] as List).cast<String>(),
        comment: json['comment'] as String? ?? '',
        date: json['date'] as String,
      );
}
