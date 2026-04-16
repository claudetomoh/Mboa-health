import 'package:flutter/foundation.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/clinic_model.dart';
import '../../../core/network/api_client.dart';

class ClinicLocatorProvider extends ChangeNotifier {
  List<Clinic> _clinics = [];
  bool    _loading = false;
  String? _error;

  List<Clinic> get clinics   => List.unmodifiable(_clinics);
  bool         get isLoading => _loading;
  String?      get error     => _error;

  Future<void> fetchClinics({String query = ''}) async {
    _setLoading(true);
    final params = <String, String>{
      if (query.isNotEmpty) 'q': query,
    };
    final result = await ApiClient.instance.get(
      ApiConfig.clinics,
      queryParams: params.isEmpty ? null : params,
      auth: false,
    );
    if (result is ApiSuccess<Map<String, dynamic>>) {
      final list = result.data['clinics'] as List<dynamic>? ?? [];
      _clinics = list
          .cast<Map<String, dynamic>>()
          .map(Clinic.fromJson)
          .toList();
      _loading = false;
      _error   = null;
    } else {
      _error   = (result as ApiFailure<Map<String, dynamic>>).message;
      _loading = false;
    }
    notifyListeners();
  }

  void _setLoading(bool val) {
    _loading = val;
    _error   = null;
    notifyListeners();
  }
}
