import 'package:flutter/foundation.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/health_record_model.dart';
import '../../../core/network/api_client.dart';

class HealthRecordsProvider extends ChangeNotifier {
  List<HealthRecord> _records = [];
  bool    _loading = false;
  String? _error;

  List<HealthRecord> get records   => List.unmodifiable(_records);
  bool               get isLoading => _loading;
  String?            get error     => _error;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchRecords() async {
    _setLoading(true);
    final result = await ApiClient.instance.get(ApiConfig.healthRecords);
    if (result is ApiSuccess<Map<String, dynamic>>) {
      final list = result.data['records'] as List<dynamic>? ?? [];
      _records = list
          .cast<Map<String, dynamic>>()
          .map(HealthRecord.fromJson)
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

  Future<String?> addRecord(Map<String, dynamic> payload) async {
    final result = await ApiClient.instance.post(
      ApiConfig.healthRecords,
      payload,
    );
    if (result is ApiSuccess<Map<String, dynamic>>) {
      await fetchRecords(); // refresh list
      return null;
    }
    return (result as ApiFailure<Map<String, dynamic>>).message;
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<String?> updateRecord(int id, Map<String, dynamic> payload) async {
    final result = await ApiClient.instance.put(
      '${ApiConfig.healthRecords}?id=$id',
      payload,
    );
    if (result is ApiSuccess<Map<String, dynamic>>) {
      await fetchRecords();
      return null;
    }
    return (result as ApiFailure<Map<String, dynamic>>).message;
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<String?> deleteRecord(int id) async {
    final result = await ApiClient.instance.delete(
      ApiConfig.healthRecords,
      queryParams: {'id': id.toString()},
    );
    if (result is ApiSuccess<Map<String, dynamic>>) {
      _records.removeWhere((r) => r.id == id);
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
