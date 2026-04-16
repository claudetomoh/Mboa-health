import 'package:flutter/foundation.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/network/api_client.dart';

class NotificationsProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int     _unreadCount = 0;
  bool    _loading     = false;
  String? _error;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int     get unreadCount => _unreadCount;
  bool    get isLoading   => _loading;
  String? get error       => _error;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchNotifications() async {
    _setLoading(true);
    final result = await ApiClient.instance.get(ApiConfig.notifications);
    if (result is ApiSuccess<Map<String, dynamic>>) {
      final list = result.data['notifications'] as List<dynamic>? ?? [];
      _notifications = list
          .cast<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
      _unreadCount = result.data['unread_count'] as int? ?? 0;
      _loading     = false;
      _error       = null;
    } else {
      _error   = (result as ApiFailure<Map<String, dynamic>>).message;
      _loading = false;
    }
    notifyListeners();
  }

  // ── Mark one read ─────────────────────────────────────────────────────────

  Future<void> markRead(int id) async {
    // Optimistic update
    _notifications = _notifications.map((n) {
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();

    // Server call
    await ApiClient.instance.post(
      '${ApiConfig.notifications}?action=mark_read&id=$id',
      {},
    );
  }

  // ── Mark all read ─────────────────────────────────────────────────────────

  Future<void> markAllRead() async {
    // Optimistic update
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();

    // Server call — query param embedded in URL
    await ApiClient.instance.post(
      '${ApiConfig.notifications}?action=mark_all_read',
      {},
    );
  }

  void _setLoading(bool val) {
    _loading = val;
    _error   = null;
    notifyListeners();
  }
}
