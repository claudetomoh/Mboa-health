import 'package:flutter/foundation.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';

class ProfileProvider extends ChangeNotifier {
  AppUser? _user;
  Map<String, int>           _stats             = {};
  List<Map<String, dynamic>> _emergencyContacts = [];
  bool    _loading                              = false;
  String? _error;

  AppUser?                   get user              => _user;
  Map<String, int>           get stats             => Map.unmodifiable(_stats);
  List<Map<String, dynamic>> get emergencyContacts => List.unmodifiable(_emergencyContacts);
  bool                       get isLoading         => _loading;
  String?                    get error             => _error;

  int get recordsCount  => _stats['health_records']     ?? 0;
  int get remindersCount=> _stats['active_reminders']   ?? 0;
  int get contactsCount => _stats['emergency_contacts'] ?? 0;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchProfile() async {
    _setLoading(true);
    final result = await ApiClient.instance.get(ApiConfig.profile);
    if (result is ApiSuccess<Map<String, dynamic>>) {
      _user = AppUser.fromJson(result.data);
      final rawStats = result.data['stats'];
      if (rawStats is Map<String, dynamic>) {
        _stats = rawStats.map((k, v) => MapEntry(k, (v as num).toInt()));
      }
      final rawContacts = result.data['emergency_contacts'];
      if (rawContacts is List) {
        _emergencyContacts = rawContacts.cast<Map<String, dynamic>>();
      }
      _loading = false;
      _error   = null;
    } else {
      _error   = (result as ApiFailure<Map<String, dynamic>>).message;
      _loading = false;
    }
    notifyListeners();
  }

  // ── Seed from auth (avoids an extra network round-trip on first load) ─────

  void seedFromAuth(AppUser user) {
    _user = user;
    notifyListeners();
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<String?> updateProfile(Map<String, dynamic> payload) async {
    final result = await ApiClient.instance.put(ApiConfig.profile, payload);
    if (result is ApiSuccess<Map<String, dynamic>>) {
      await fetchProfile(); // reload fresh data
      return null;
    }
    return (result as ApiFailure<Map<String, dynamic>>).message;
  }

  // ── Emergency Contacts CRUD ───────────────────────────────────────────────

  Future<String?> addEmergencyContact(Map<String, dynamic> payload) async {
    final result = await ApiClient.instance.post(
      ApiConfig.emergencyContacts,
      payload,
    );
    if (result is ApiSuccess<Map<String, dynamic>>) {
      await fetchProfile();
      return null;
    }
    return (result as ApiFailure<Map<String, dynamic>>).message;
  }

  Future<String?> deleteEmergencyContact(int id) async {
    final result = await ApiClient.instance.delete(
      ApiConfig.emergencyContacts,
      queryParams: {'id': id.toString()},
    );
    if (result is ApiSuccess<Map<String, dynamic>>) {
      _emergencyContacts.removeWhere((c) => (c['id'] as num?)?.toInt() == id);
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
