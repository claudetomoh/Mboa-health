import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final int id;
  final String type;   // reminder | appointment | system | alert | info
  final String title;
  final String? body;
  final bool isRead;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id:        json['id'] as int,
        type:      json['type'] as String? ?? 'info',
        title:     json['title'] as String,
        body:      json['body'] as String?,
        isRead:    json['is_read'] == true || json['is_read'] == 1,
        createdAt: json['created_at'] as String,
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id:        id,
        type:      type,
        title:     title,
        body:      body,
        isRead:    isRead ?? this.isRead,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, type, title, isRead, createdAt];
}
