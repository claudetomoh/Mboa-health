import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/secure_storage.dart';

// =============================================================================
// MBOA HEALTH — API Client
// Wraps http.Client with:
//   • Automatic JWT Authorization header injection
//   • Uniform JSON parsing
//   • Typed error results
//   • OWASP A03: only consumes own server responses; validates status codes.
// =============================================================================

/// Represents a successful or failed API response.
sealed class ApiResult<T> {}

final class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  ApiSuccess(this.data);
}

final class ApiFailure<T> extends ApiResult<T> {
  final String message;
  final int statusCode;
  ApiFailure(this.message, {this.statusCode = 0});
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // ── Headers ──────────────────────────────────────────────────────────────

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await SecureStorage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Request helpers ───────────────────────────────────────────────────────

  Future<ApiResult<Map<String, dynamic>>> get(
    String url, {
    Map<String, String>? queryParams,
    bool auth = true,
  }) async {
    try {
      final uri = Uri.parse(url).replace(
        queryParameters: queryParams,
      );
      final response = await http
          .get(uri, headers: await _headers(auth: auth))
          .timeout(ApiConfig.timeout);
      return _parse(response);
    } catch (e) {
      return ApiFailure(_networkError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> post(
    String url,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      return _parse(response);
    } catch (e) {
      return ApiFailure(_networkError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> put(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await http
          .put(
            uri,
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      return _parse(response);
    } catch (e) {
      return ApiFailure(_networkError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> delete(
    String url, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await http
          .delete(uri, headers: await _headers())
          .timeout(ApiConfig.timeout);
      return _parse(response);
    } catch (e) {
      return ApiFailure(_networkError(e));
    }
  }

  // ── Multipart file upload ────────────────────────────────────────────────

  /// Uploads [fileBytes] as a multipart POST to [url].
  /// Uses the same JWT bearer token as all other authenticated requests.
  Future<ApiResult<Map<String, dynamic>>> uploadFile(
    String url,
    String fieldName,
    List<int> fileBytes,
    String filename,
  ) async {
    try {
      final token = await SecureStorage.getToken();
      final request = http.MultipartRequest('POST', Uri.parse(url));
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(
        http.MultipartFile.fromBytes(fieldName, fileBytes, filename: filename),
      );
      final streamed = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamed);
      return _parse(response);
    } catch (e) {
      return ApiFailure(_networkError(e));
    }
  }

  // ── Response parser ───────────────────────────────────────────────────────

  ApiResult<Map<String, dynamic>> _parse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return ApiFailure(
        'Unexpected server response. Please try again.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json['data'];
      return ApiSuccess(data is Map<String, dynamic> ? data : <String, dynamic>{});
    }

    final message = json['message'] as String? ?? 'An unexpected error occurred.';
    return ApiFailure(message, statusCode: response.statusCode);
  }

  String _networkError(Object e) {
    if (e is SocketException) {
      return 'No internet connection. Please check your network.';
    }
    if (e.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    return 'Network error. Please try again.';
  }
}
