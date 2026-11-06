import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AsyncServerDiscovery {
  static const List<String> defaultCandidates = [
    'http://localhost:8080/projecta/api/v1',
    'http://192.168.1.6/projecta/api/v1',
    'http://10.0.2.2/projecta/api/v1',
    'http://localhost/projecta/api/v1',
  ];

  /// Races all candidate endpoints in parallel and switches ApiClient baseUrl
  /// to the fastest server that responds with HTTP 200 to /health.
  static Future<String?> probeAndSelectFastest({
    List<String> candidates = defaultCandidates,
    Duration timeout = const Duration(milliseconds: 1500),
    http.Client? client,
  }) async {
    if (kIsWeb) return null;

    final httpClient = client ?? http.Client();
    final completer = Completer<String?>();
    int pending = candidates.length;

    for (final url in candidates) {
      final clean = url.trim().endsWith('/')
          ? url.substring(0, url.length - 1)
          : url;
      final healthUri = Uri.parse('$clean/health');

      httpClient.get(healthUri).timeout(timeout).then((response) {
        if (response.statusCode == 200 && !completer.isCompleted) {
          ApiClient().setBaseUrl(clean);
          completer.complete(clean);
        }
      }).catchError((_) {
        // Ignore individual probe error
      }).whenComplete(() {
        pending--;
        if (pending == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    final fastest = await completer.future;
    if (client == null) {
      httpClient.close();
    }
    return fastest;
  }
}

