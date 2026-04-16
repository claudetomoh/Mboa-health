import 'package:flutter/foundation.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/reminder_model.dart';
import '../../../core/network/api_client.dart';

class RemindersProvider extends ChangeNotifier {
  List<Reminder> _reminders = [];
  bool    _loading = false;
  String? _error;

  List<Reminder> get reminders  => List.unmodifiable(_reminders);
  List<Reminder> get active     => _reminders.where((r) => r.isActive).toList();
  List<Reminder> get inactive   => _reminders.where((r) => !r.isActive).toList();
  bool           get isLoading  => _loading;
  String?        get error      => _error;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchReminders() async {
    _setLoading(true);
    final result = await ApiClient.instance.get(ApiConfig.reminders);
    if (result is ApiSuccess<Map<String, dynamic>>) {
      final list = result.data['reminders'] as List<dynamic>? ?? [];
      _reminders = list
          .cast<Map<String, dynamic>>()
          .map(Reminder.fromJson)
          .toList();
      _loading = false;
      _error   = null;
    } else {
      _error   = (result as ApiFailure<Map<String, dynamic>>).message;
      _loading = false;
    }
    notifyListeners();
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  Future<String?> addReminder(Map<String, dynamic> payload) async {
    final result = await ApiClient.instance.post(ApiConfig.reminders, payload);
    if (result is ApiSuccess<Map<String, dynamic>>) {
      await fetchReminders();
      return null;
    }
    return (result as ApiFailure<Map<String, dynamic>>).message;
  }

  // ── Toggle active ─────────────────────────────────────────────────────────

  Future<void> toggleActive(int id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final newState = !_reminders[index].isActive;

    // Optimistic update
    _reminders[index] = _reminders[index].copyWith(isActive: newState);
    notifyListeners();

    final result = await ApiClient.instance.put(
      ApiConfig.reminders,
      {'is_active': newState},
      queryParams: {'id': id.toString()},
    );
    if (result is ApiFailure<Map<String, dynamic>>) {
      // Revert on failure
      _reminders[index] = _reminders[index].copyWith(isActive: !newState);
      notifyListeners();
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<String?> deleteReminder(int id) async {
    final result = await ApiClient.instance.delete(
      ApiConfig.reminders,
      queryParams: {'id': id.toString()},
    );
    if (result is ApiSuccess<Map<String, dynamic>>) {
      _reminders.removeWhere((r) => r.id == id);
      notifyListeners();
      return null;
    }
    return (result as ApiFailure<Map<String, dynamic>>).message;
  }

  void _setLoading(bool val) {
    _loading = val;
    _error   = null;
    notifyListeners();
  }
}
