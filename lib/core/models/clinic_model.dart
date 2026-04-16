import 'package:equatable/equatable.dart';

class Clinic extends Equatable {
  final int id;
  final String name;
  final String address;
  final String city;
  final String? phone;
  final String type;
  final double? rating;
  final bool is24h;
  final String? hours;
  final double? latitude;
  final double? longitude;
  final List<String> services;

  const Clinic({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.phone,
    required this.type,
    this.rating,
    required this.is24h,
    this.hours,
    this.latitude,
    this.longitude,
    this.services = const [],
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'];
    List<String> services;
    if (rawServices is List) {
      services = rawServices.cast<String>();
    } else if (rawServices is String && rawServices.isNotEmpty) {
      services = rawServices.split(',').map((s) => s.trim()).toList();
    } else {
      services = [];
    }

    return Clinic(
      id:        json['id'] as int,
      name:      json['name'] as String,
      address:   json['address'] as String,
      city:      json['city'] as String? ?? '',
      phone:     json['phone'] as String?,
      type:      json['type'] as String? ?? 'clinic',
      rating:    json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      is24h:     json['is_24h'] == true || json['is_24h'] == 1,
      hours:     json['hours'] as String?,
      latitude:  json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      services:  services,
    );
  }

  @override
  List<Object?> get props => [id, name, address, city, type];
}
