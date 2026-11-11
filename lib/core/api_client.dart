import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException({required this.statusCode, required this.message, this.details});

  @override
  String toString() => 'ApiException [$statusCode]: $message';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _initializeBaseUrl();
  }

  static const String defaultLanIp = '192.168.1.3';
  static const String _defaultAdbTunnelUrl =
      'http://localhost:8080/projecta/api/v1';
  static const String _defaultAndroidUrl =
      'http://$defaultLanIp/projecta/api/v1';
  static const String _defaultLocalhostUrl = 'http://localhost/projecta/api/v1';
  static const String _tokenPrefKey = 'auth_token';
  static const String _baseUrlPrefKey = 'api_base_url';

  /// Standard HTTP request timeout (8s). Fast failure allows rapid auto-fallback
  /// to USB ADB tunnel (localhost:8080) or Wi-Fi LAN IP without freezing UI.
  static const Duration requestTimeout = Duration(seconds: 8);
  static const String cachedHeaderKey = 'x-projeqta-cached';

  static bool isCachedResponse(http.Response response) {
    return response.headers[cachedHeaderKey] == 'true';
  }

  String _baseUrl = _defaultLocalhostUrl;
  String? _cachedToken;
  http.Client _httpClient = http.Client();

  @visibleForTesting
  set customHttpClient(http.Client client) => _httpClient = client;

  @visibleForTesting
  void resetHttpClient() => _httpClient = http.Client();

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

  /// Resolves relative or localhost media/avatar URLs to point to the active host and port
  /// so that physical Android devices can load server-hosted images without localhost connection errors.
  String? resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      final base = _baseUrl.endsWith('/api/v1')
          ? _baseUrl.substring(0, _baseUrl.length - '/api/v1'.length)
          : _baseUrl;
      final cleanBase = base.endsWith('/')
          ? base.substring(0, base.length - 1)
          : base;
      final cleanPath = trimmed.startsWith('/')
          ? trimmed.substring(1)
          : trimmed;
      return '$cleanBase/$cleanPath';
    }

    try {
      final mediaUri = Uri.parse(trimmed);
      final baseUri = Uri.parse(_baseUrl);

      if (mediaUri.host == 'localhost' || mediaUri.host == '127.0.0.1') {
        if (baseUri.host != 'localhost' && baseUri.host != '127.0.0.1') {
          return mediaUri
              .replace(
                host: baseUri.host,
                port: baseUri.hasPort
                    ? baseUri.port
                    : (baseUri.scheme == 'https' ? 443 : 80),
              )
              .toString();
        } else if (baseUri.hasPort &&
            (!mediaUri.hasPort || mediaUri.port != baseUri.port)) {
          return mediaUri.replace(port: baseUri.port).toString();
        }
      }
    } catch (_) {}

    return trimmed;
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
      return baseUri.replace(
        queryParameters: {...baseUri.queryParameters, ...stringQuery},
      );
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

  /// Automatically tests alternative local endpoints (USB ADB tunnel, Wi-Fi LAN IP, Emulator)
  /// when the current baseUrl experiences connection timeout.
  Future<bool> _tryAutoFallback() async {
    if (kIsWeb) return false;
    final candidates = <String>[
      _defaultAdbTunnelUrl,
      'http://$defaultLanIp/projecta/api/v1',
      'http://10.0.2.2/projecta/api/v1',
      'http://localhost/projecta/api/v1',
    ];

    for (final candidate in candidates) {
      if (candidate == _baseUrl) continue;
      try {
        final healthUri = Uri.parse('$candidate/health');
        final res = await _httpClient
            .get(healthUri)
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          await setBaseUrl(candidate);
          return true;
        }
      } catch (_) {
        // Try next candidate
      }
    }
    return false;
  }

  /// Wraps HTTP requests with auto-fallback and unified error transformation
  Future<http.Response> _executeWithFallback(
    Future<http.Response> Function() requestSender,
  ) async {
    try {
      final response = await requestSender().timeout(requestTimeout);
      return _handleResponse(response);
    } on Exception catch (initialError) {
      final isNetworkIssue =
          initialError is TimeoutException ||
          initialError is SocketException ||
          initialError is http.ClientException;

      if (isNetworkIssue) {
        final switched = await _tryAutoFallback();
        if (switched) {
          try {
            final retryResponse = await requestSender().timeout(requestTimeout);
            return _handleResponse(retryResponse);
          } catch (_) {
            // Fall through to throw standard formatted ApiException below
          }
        }
      }

      if (initialError is TimeoutException) {
        throw ApiException(
          statusCode: 0,
          message:
              'Connection timed out reaching $_baseUrl.\nVerify your device Wi-Fi and server IP.',
        );
      } else if (initialError is SocketException) {
        throw ApiException(
          statusCode: 0,
          message:
              'Cannot connect to $_baseUrl (${initialError.message}).\nTip: If testing via USB cable, ensure "adb reverse tcp:8080 tcp:80" is active.',
        );
      } else if (initialError is http.ClientException) {
        throw ApiException(
          statusCode: 0,
          message:
              'Network connection failed: ${initialError.message}\n(Target: $_baseUrl)',
        );
      } else {
        rethrow;
      }
    }
  }

  String _cacheKey(String endpoint, Map<String, dynamic>? queryParameters) {
    final queryStr = queryParameters != null && queryParameters.isNotEmpty
        ? queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')
        : '';
    return 'cache_${endpoint}_$queryStr';
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _executeWithFallback(() async {
      final uri = _buildUri(endpoint, queryParameters);
      final mergedHeaders = await _buildHeaders(extraHeaders: headers);
      return _httpClient.get(uri, headers: mergedHeaders);
    });
  }

  /// Transparently fetches GET requests with offline fallback caching via SharedPreferences.
  Future<http.Response> getWithCache(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final key = _cacheKey(endpoint, queryParameters);
    try {
      final response = await get(
        endpoint,
        headers: headers,
        queryParameters: queryParameters,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          jsonDecode(response.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(key, response.body);
        } catch (_) {
          // If response body is not valid JSON (e.g. captive portal HTML error), do not cache
        }
      }
      return response;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cachedBody = prefs.getString(key);
      if (cachedBody != null && cachedBody.trim().isNotEmpty) {
        try {
          jsonDecode(cachedBody);
          return http.Response(
            cachedBody,
            200,
            headers: {
              'content-type': 'application/json; charset=utf-8',
              cachedHeaderKey: 'true',
            },
          );
        } catch (_) {
          // Corrupted cache - remove it and let the network exception propagate
          await prefs.remove(key);
        }
      }
      rethrow;
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _executeWithFallback(() async {
      final uri = _buildUri(endpoint);
      final mergedHeaders = await _buildHeaders(extraHeaders: headers);
      final encodedBody = body != null ? jsonEncode(body) : null;
      return _httpClient.post(uri, headers: mergedHeaders, body: encodedBody);
    });
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _executeWithFallback(() async {
      final uri = _buildUri(endpoint);
      final mergedHeaders = await _buildHeaders(extraHeaders: headers);
      final encodedBody = body != null ? jsonEncode(body) : null;
      return _httpClient.put(uri, headers: mergedHeaders, body: encodedBody);
    });
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _executeWithFallback(() async {
      final uri = _buildUri(endpoint);
      final mergedHeaders = await _buildHeaders(extraHeaders: headers);
      final encodedBody = body != null ? jsonEncode(body) : null;
      return _httpClient.patch(uri, headers: mergedHeaders, body: encodedBody);
    });
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _executeWithFallback(() async {
      final uri = _buildUri(endpoint);
      final mergedHeaders = await _buildHeaders(extraHeaders: headers);
      final encodedBody = body != null ? jsonEncode(body) : null;
      return _httpClient.delete(uri, headers: mergedHeaders, body: encodedBody);
    });
  }

  /// Sends a multipart POST request to upload a file (supports file path or raw bytes)
  Future<http.Response> uploadMultipartFile(
    String endpoint, {
    required String fieldName,
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    return _executeWithFallback(() async {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);

      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      if (headers != null) {
        request.headers.addAll(headers);
      }
      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (fileBytes != null && fileBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fieldName,
            fileBytes,
            filename: fileName,
          ),
        );
      } else if (filePath != null && filePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            filePath,
            filename: fileName,
          ),
        );
      } else {
        throw ApiException(statusCode: 400, message: 'No file data provided.');
      }

      final streamedResponse = await _httpClient.send(request);
      return http.Response.fromStream(streamedResponse);
    });
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
        if (responseData.containsKey('error') &&
            responseData['error'] != null) {
          errorMessage = responseData['error'].toString();
        } else if (responseData.containsKey('message') &&
            responseData['message'] != null) {
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
    try {
      return jsonDecode(response.body);
    } on FormatException catch (e) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Invalid server response (non-JSON payload): ${e.message}',
        details: response.body,
      );
    }
  }
}
