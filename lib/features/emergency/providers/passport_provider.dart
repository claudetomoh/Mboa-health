import 'package:flutter/foundation.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

// =============================================================================
// MBOA HEALTH — Digital Health Passport Provider
// Wraps the authenticated passport lifecycle (CC-04) and the public
// token-only view (CC-05A). No new backend behavior — this is a thin client
// over endpoints that are already implemented and reviewed.
// =============================================================================

class PassportProvider extends ChangeNotifier {
  bool _exists = false;
  bool _isActive = false;
  String? _token;
  String? _createdAt;
  String? _updatedAt;
  String? _disabledAt;

  bool _loading = false;
  String? _error;

  /// The exact whitelist returned by the public view endpoint — populated
  /// only when "View as Text" is used, so it always reflects what a real
  /// scan would show, rather than a client-side reconstruction of it.
  Map<String, dynamic>? _publicSnapshot;
  bool _snapshotLoading = false;
  String? _snapshotError;

  bool   get exists      => _exists;
  bool   get isActive    => _isActive;
  String? get token      => _token;
  String? get createdAt  => _createdAt;
  String? get updatedAt  => _updatedAt;
  String? get disabledAt => _disabledAt;
  bool   get isLoading   => _loading;
  String? get error      => _error;

  Map<String, dynamic>? get publicSnapshot => _publicSnapshot;
  bool    get isSnapshotLoading            => _snapshotLoading;
  String? get snapshotError                => _snapshotError;

  /// Full public URL a QR code should encode — the same URL the CC-05A
  /// public endpoint serves. Null until a token exists.
  String? get publicUrl =>
      _token == null ? null : '${ApiConfig.passportView}?token=$_token';

  void _applyStatus(Map<String, dynamic> data) {
    _exists = data['exists'] as bool? ?? false;
    if (_exists) {
      _isActive   = data['is_active'] as bool? ?? false;
      _token      = data['token'] as String?;
      _createdAt  = data['created_at'] as String?;
      _updatedAt  = data['updated_at'] as String?;
      _disabledAt = data['disabled_at'] as String?;
    } else {
      _isActive   = false;
      _token      = null;
      _createdAt  = null;
      _updatedAt  = null;
      _disabledAt = null;
    }
  }

  // ── Status ───────────────────────────────────────────────────────────────

  Future<void> fetchStatus() async {
    _loading = true;
    _error   = null;
    notifyListeners();

    final result = await ApiClient.instance.get(ApiConfig.passport);
    if (result is ApiSuccess<Map<String, dynamic>>) {
      _applyStatus(result.data);
    } else {
      _error = (result as ApiFailure<Map<String, dynamic>>).message;
    }
    _loading = false;
    notifyListeners();
  }

  // ── Lifecycle actions ───────────────────────────────────────────────────

  Future<String?> create() => _lifecycleAction('create');
  Future<String?> enable() => _lifecycleAction('enable');
  Future<String?> regenerate() => _lifecycleAction('regenerate');
  Future<String?> disable() => _lifecycleAction('disable');

  Future<String?> _lifecycleAction(String action) async {
    _loading = true;
    _error   = null;
    notifyListeners();

    final result = await ApiClient.instance.post(
      '${ApiConfig.passport}?action=$action',
      const {},
    );

    String? errorMessage;
    if (result is ApiSuccess<Map<String, dynamic>>) {
      _applyStatus(result.data);
    } else {
      errorMessage = (result as ApiFailure<Map<String, dynamic>>).message;
      _error = errorMessage;
    }
    _loading = false;
    notifyListeners();
    return errorMessage; // null on success, matching this app's provider convention
  }

  // ── Public "View as Text" snapshot ──────────────────────────────────────

  /// Calls the actual public passport endpoint (unauthenticated, token-only)
  /// so "View as Text" shows exactly what a real QR scan would return.
  Future<String?> fetchPublicSnapshot() async {
    if (_token == null) return 'No passport token available.';

    _snapshotLoading = true;
    _snapshotError   = null;
    notifyListeners();

    final result = await ApiClient.instance.get(
      ApiConfig.passportView,
      queryParams: {'token': _token!},
      auth: false,
    );

    String? errorMessage;
    if (result is ApiSuccess<Map<String, dynamic>>) {
      _publicSnapshot = result.data;
    } else {
      errorMessage = (result as ApiFailure<Map<String, dynamic>>).message;
      _snapshotError = errorMessage;
    }
    _snapshotLoading = false;
    notifyListeners();
    return errorMessage;
  }
}
