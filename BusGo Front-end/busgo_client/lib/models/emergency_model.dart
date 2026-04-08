class EmergencyAlertModel {
  final String type;
  final String details;
  final String date;
  final String status;

  const EmergencyAlertModel({
    required this.type,
    this.details = '',
    required this.date,
    this.status = 'Sent',
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'details': details,
        'date': date,
        'status': status,
      };

  factory EmergencyAlertModel.fromJson(Map<String, dynamic> json) =>
      EmergencyAlertModel(
        type: json['type'] as String,
        details: json['details'] as String? ?? '',
        date: json['date'] as String,
        status: json['status'] as String? ?? 'Sent',
      );
}
