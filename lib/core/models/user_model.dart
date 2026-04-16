import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final String? bloodType;
  final String? allergies;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
    this.bloodType,
    this.allergies,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id:         json['id'] as int,
        fullName:   json['full_name'] as String,
        email:      json['email'] as String,
        phone:      json['phone'] as String?,
        role:       json['role'] as String? ?? 'patient',
        avatarUrl:  json['avatar_url'] as String?,
        bloodType:  json['blood_type'] as String?,
        allergies:  json['allergies'] as String?,
      );

  /// First name — the part before the first space.
  String get firstName {
    final parts = fullName.trim().split(' ');
    return parts.first;
  }

  AppUser copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? bloodType,
    String? allergies,
  }) =>
      AppUser(
        id:        id,
        fullName:  fullName ?? this.fullName,
        email:     email,
        phone:     phone ?? this.phone,
        role:      role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bloodType: bloodType ?? this.bloodType,
        allergies: allergies ?? this.allergies,
      );

  @override
  List<Object?> get props =>
      [id, fullName, email, phone, role, avatarUrl, bloodType, allergies];
}
