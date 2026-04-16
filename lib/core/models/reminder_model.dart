import 'package:equatable/equatable.dart';

class Reminder extends Equatable {
  final int id;
  final String medicationName;
  final String? dosage;
  final String frequency;  // daily | twice_daily | thrice_daily | weekly | as_needed
  final String reminderTime; // HH:mm:ss
  final String? daysOfWeek;  // Mon,Tue,Wed
  final bool isActive;
  final String? startDate;
  final String? endDate;
  final String? notes;
  final String? createdAt;

  const Reminder({
    required this.id,
    required this.medicationName,
    this.dosage,
    required this.frequency,
    required this.reminderTime,
    this.daysOfWeek,
    required this.isActive,
    this.startDate,
    this.endDate,
    this.notes,
    this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id:             json['id'] as int,
        medicationName: json['medication_name'] as String,
        dosage:         json['dosage'] as String?,
        frequency:      json['frequency'] as String? ?? 'daily',
        reminderTime:   json['reminder_time'] as String,
        daysOfWeek:     json['days_of_week'] as String?,
        isActive:       json['is_active'] == true || json['is_active'] == 1,
        startDate:      json['start_date'] as String?,
        endDate:        json['end_date'] as String?,
        notes:          json['notes'] as String?,
        createdAt:      json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'medication_name': medicationName,
        'dosage':          dosage,
        'frequency':       frequency,
        'reminder_time':   reminderTime,
        'days_of_week':    daysOfWeek,
        'is_active':       isActive,
        'start_date':      startDate,
        'end_date':        endDate,
        'notes':           notes,
      };

  Reminder copyWith({bool? isActive}) => Reminder(
        id:             id,
        medicationName: medicationName,
        dosage:         dosage,
        frequency:      frequency,
        reminderTime:   reminderTime,
        daysOfWeek:     daysOfWeek,
        isActive:       isActive ?? this.isActive,
        startDate:      startDate,
        endDate:        endDate,
        notes:          notes,
        createdAt:      createdAt,
      );

  /// Display-friendly time string: "08:00 AM"
  String get displayTime {
    final parts = reminderTime.split(':');
    if (parts.length < 2) return reminderTime;
    final hour   = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final h      = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:$minute $suffix';
  }

  @override
  List<Object?> get props =>
      [id, medicationName, dosage, frequency, reminderTime, isActive];
}
