class Alert {
  final String id;
  final String type;
  final String description;
  final String driverId;
  final String tripId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final AlertStatus status;

  const Alert({
    required this.id,
    required this.type,
    required this.description,
    required this.driverId,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.status = AlertStatus.sent,
  });

  Alert copyWith({AlertStatus? status}) {
    return Alert(
      id: id,
      type: type,
      description: description,
      driverId: driverId,
      tripId: tripId,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      driverId: json['driver_id'] as String,
      tripId: json['trip_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'description': description,
    'driver_id': driverId,
    'trip_id': tripId,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
  };
}

enum AlertStatus { sent, acknowledged, resolved, cancelled }

class EmergencyType {
  final String key;
  final String label;
  final String icon;

  const EmergencyType({
    required this.key,
    required this.label,
    required this.icon,
  });

  static const List<EmergencyType> types = [
    EmergencyType(key: 'medical', label: 'Medical Emergency', icon: '🏥'),
    EmergencyType(key: 'breakdown', label: 'Vehicle Breakdown', icon: '🔧'),
    EmergencyType(key: 'accident', label: 'Road Accident', icon: '🚨'),
    EmergencyType(key: 'security', label: 'Security Threat', icon: '🛡️'),
    EmergencyType(key: 'other', label: 'Other Emergency', icon: '📢'),
  ];
}
