import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ApiException [$statusCode]: $message';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _initializeBaseUrl();
  }

  static const String defaultLanIp = '192.168.1.7';
  static const String _defaultAndroidUrl = 'http://$defaultLanIp/projecta/api/v1';
  static const String _defaultLocalhostUrl = 'http://localhost/projecta/api/v1';
  static const String _tokenPrefKey = 'auth_token';
  static const String _baseUrlPrefKey = 'api_base_url';
  static const Duration requestTimeout = Duration(seconds: 10);

  String _baseUrl = _defaultLocalhostUrl;
  String? _cachedToken;
  final http.Client _httpClient = http.Client();

  String get baseUrl => _baseUrl;

  void _initializeBaseUrl() {
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          _baseUrl = _defaultAndroidUrl;
          return;
        }
      } catch (_) {
        // Fallback to localhost if Platform inspection is unsupported
      }
    }
    _baseUrl = _defaultLocalhostUrl;
  }

  Future<void> loadSavedBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_baseUrlPrefKey);
    if (saved != null && saved.trim().isNotEmpty) {
      _baseUrl = saved.trim();
    }
  }

  Future<void> setBaseUrl(String url) async {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    _baseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPrefKey, _baseUrl);
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefKey, token);
  }

  Future<String?> getToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenPrefKey);
    return _cachedToken;
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefKey);
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    String cleanEndpoint = endpoint.trim();
    if (!cleanEndpoint.startsWith('/')) {
      cleanEndpoint = '/$cleanEndpoint';
    }

    String fullUrl = '$_baseUrl$cleanEndpoint';

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringQuery = queryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      final baseUri = Uri.parse(fullUrl);
      return baseUri.replace(queryParameters: {
        ...baseUri.queryParameters,
        ...stringQuery,
      });
    }

    return Uri.parse(fullUrl);
  }

  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? extraHeaders,
  }) async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final mergedHeaders = await _buildHeaders(extraHeaders: headers);
    try {
      final response = await _httpClient
          .get(uri, headers: mergedHeaders)
          .timeout(requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Connection timed out reaching $_baseUrl.\nVerify your device Wi-Fi and server IP.',
      );
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Cannot connect to $_baseUrl (${e.message}).',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network connection failed: ${e.message}\n(Target: $_baseUrl)',
      );
    }
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = _buildUri(endpoint);
    final mergedHeaders = await _buildHeaders(extraHeaders: headers);
    final encodedBody = body != null ? jsonEncode(body) : null;

    try {
      final response = await _httpClient
          .post(uri, headers: mergedHeaders, body: encodedBody)
          .timeout(requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Connection timed out reaching $_baseUrl.\nVerify your device Wi-Fi and server IP.',
      );
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Cannot connect to $_baseUrl (${e.message}).',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network connection failed: ${e.message}\n(Target: $_baseUrl)',
      );
    }
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = _buildUri(endpoint);
    final mergedHeaders = await _buildHeaders(extraHeaders: headers);
    final encodedBody = body != null ? jsonEncode(body) : null;

    try {
      final response = await _httpClient
          .put(uri, headers: mergedHeaders, body: encodedBody)
          .timeout(requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Connection timed out reaching $_baseUrl.\nVerify your device Wi-Fi and server IP.',
      );
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Cannot connect to $_baseUrl (${e.message}).',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network connection failed: ${e.message}\n(Target: $_baseUrl)',
      );
    }
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = _buildUri(endpoint);
    final mergedHeaders = await _buildHeaders(extraHeaders: headers);
    final encodedBody = body != null ? jsonEncode(body) : null;

    try {
      final response = await _httpClient
          .patch(uri, headers: mergedHeaders, body: encodedBody)
          .timeout(requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Connection timed out reaching $_baseUrl.\nVerify your device Wi-Fi and server IP.',
      );
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Cannot connect to $_baseUrl (${e.message}).',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network connection failed: ${e.message}\n(Target: $_baseUrl)',
      );
    }
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = _buildUri(endpoint);
    final mergedHeaders = await _buildHeaders(extraHeaders: headers);
    final encodedBody = body != null ? jsonEncode(body) : null;

    try {
      final response = await _httpClient
          .delete(uri, headers: mergedHeaders, body: encodedBody)
          .timeout(requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Connection timed out reaching $_baseUrl.\nVerify your device Wi-Fi and server IP.',
      );
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Cannot connect to $_baseUrl (${e.message}).',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network connection failed: ${e.message}\n(Target: $_baseUrl)',
      );
    }
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    String errorMessage = 'Server returned error status ${response.statusCode}';
    dynamic responseData;

    try {
      responseData = jsonDecode(response.body);
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('error') && responseData['error'] != null) {
          errorMessage = responseData['error'].toString();
        } else if (responseData.containsKey('message') && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }
    } catch (_) {
      // Body not JSON
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
      details: responseData,
    );
  }

  dynamic decodeJson(http.Response response) {
    return jsonDecode(response.body);
  }
}

