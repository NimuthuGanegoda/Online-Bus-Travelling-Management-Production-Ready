class Driver {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String phone;
  final String licenseNumber;
  final String licenseExpiry;
  final String photoUrl;
  final double rating;
  final int tripsCompleted;
  final double hoursLogged;
  final String status; // active, off-duty, on-leave
  final String vehicleId;
  final String vehiclePlate;
  final String vehicleModel;

  const Driver({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.licenseExpiry,
    this.photoUrl = '',
    this.rating = 4.2,
    this.tripsCompleted = 487,
    this.hoursLogged = 1248,
    this.status = 'active',
    this.vehicleId = 'VH-2841',
    this.vehiclePlate = 'WP-KA-5523',
    this.vehicleModel = 'Ashok Leyland Viking',
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  String get ratingDisplay => rating.toStringAsFixed(1);

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      licenseNumber: json['license_number'] as String,
      licenseExpiry: json['license_expiry'] as String,
      photoUrl: json['photo_url'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.2,
      tripsCompleted: json['trips_completed'] as int? ?? 0,
      hoursLogged: (json['hours_logged'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'active',
      vehicleId: json['vehicle_id'] as String? ?? '',
      vehiclePlate: json['vehicle_plate'] as String? ?? '',
      vehicleModel: json['vehicle_model'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_id': employeeId,
    'name': name,
    'email': email,
    'phone': phone,
    'license_number': licenseNumber,
    'license_expiry': licenseExpiry,
    'photo_url': photoUrl,
    'rating': rating,
    'trips_completed': tripsCompleted,
    'hours_logged': hoursLogged,
    'status': status,
    'vehicle_id': vehicleId,
    'vehicle_plate': vehiclePlate,
    'vehicle_model': vehicleModel,
  };
}
