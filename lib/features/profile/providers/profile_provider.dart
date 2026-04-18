import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';

class ProfileProvider extends ChangeNotifier {
  AppUser? _user;
  Map<String, int>           _stats             = {};
  List<Map<String, dynamic>> _emergencyContacts = [];
  bool       _loading                           = false;
  String?    _error;
  /// Local preview bytes — set immediately on pick so every Consumer updates
  /// without waiting for the upload round-trip or CORS on Image.network.
  Uint8List? avatarPreviewBytes;
  bool       avatarUploading = false;

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

  // ── Avatar upload ─────────────────────────────────────────────────────────

  /// Call this as soon as the user picks a file for an instant preview
  /// everywhere before the upload completes.
  Future<String?> uploadAvatar(XFile file) async {
    final bytes    = await file.readAsBytes();
    avatarPreviewBytes = bytes;
    avatarUploading    = true;
    notifyListeners();

    final filename = file.name.isNotEmpty ? file.name : 'avatar.jpg';
    final result   = await ApiClient.instance.uploadFile(
      ApiConfig.uploadAvatar,
      'avatar',
      bytes,
      filename,
    );
    avatarUploading = false;
    if (result is ApiSuccess<Map<String, dynamic>>) {
      final url = result.data['avatar_url'] as String?;
      if (url != null && _user != null) {
        _user = _user!.copyWith(avatarUrl: url);
      }
      notifyListeners();
      return null;
    }
    // On failure roll back the preview
    avatarPreviewBytes = null;
    notifyListeners();
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
