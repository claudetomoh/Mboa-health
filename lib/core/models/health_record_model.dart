import 'package:equatable/equatable.dart';

class HealthRecord extends Equatable {
  final int id;
  final String type;      // prescription | lab_result | x_ray | vaccination | consultation | surgery | other
  final String title;
  final String? doctor;
  final String? facility;
  final String date;      // yyyy-MM-dd
  final String? fileUrl;
  final String? notes;
  final String? createdAt;

  const HealthRecord({
    required this.id,
    required this.type,
    required this.title,
    this.doctor,
    this.facility,
    required this.date,
    this.fileUrl,
    this.notes,
    this.createdAt,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) => HealthRecord(
        id:        json['id'] as int,
        type:      json['type'] as String? ?? 'other',
        title:     json['title'] as String,
        doctor:    json['doctor'] as String?,
        facility:  json['facility'] as String?,
        date:      json['date'] as String,
        fileUrl:   json['file_url'] as String?,
        notes:     json['notes'] as String?,
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'type':     type,
        'title':    title,
        'doctor':   doctor,
        'facility': facility,
        'date':     date,
        'file_url': fileUrl,
        'notes':    notes,
      };

  @override
  List<Object?> get props =>
      [id, type, title, doctor, facility, date, fileUrl, notes];
}
