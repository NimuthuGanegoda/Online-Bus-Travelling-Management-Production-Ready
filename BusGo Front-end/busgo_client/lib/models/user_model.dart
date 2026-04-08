class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String username;
  final String phone;
  final String? dateOfBirth;
  final String membershipType;
  final String memberSince;
  final int totalTrips;
  final bool isActive;
  final String qrCode;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    required this.phone,
    this.dateOfBirth,
    this.membershipType = 'Standard Member',
    this.memberSince = 'Jan 2024',
    this.totalTrips = 0,
    this.isActive = true,
    this.qrCode = '',
  });

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  String get validUntil => '12 / 2026';

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'username': username,
        'phone': phone,
        'dateOfBirth': dateOfBirth,
        'membershipType': membershipType,
        'memberSince': memberSince,
        'totalTrips': totalTrips,
        'isActive': isActive,
        'qrCode': qrCode,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        username: json['username'] as String,
        phone: json['phone'] as String,
        dateOfBirth: json['dateOfBirth'] as String?,
        membershipType:
            json['membershipType'] as String? ?? 'Standard Member',
        memberSince: json['memberSince'] as String? ?? 'Jan 2024',
        totalTrips: json['totalTrips'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        qrCode: json['qrCode'] as String? ?? '',
      );

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? username,
    String? phone,
    String? dateOfBirth,
    String? membershipType,
    String? memberSince,
    int? totalTrips,
    bool? isActive,
    String? qrCode,
  }) =>
      UserModel(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        username: username ?? this.username,
        phone: phone ?? this.phone,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        membershipType: membershipType ?? this.membershipType,
        memberSince: memberSince ?? this.memberSince,
        totalTrips: totalTrips ?? this.totalTrips,
        isActive: isActive ?? this.isActive,
        qrCode: qrCode ?? this.qrCode,
      );
}
