import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AsyncServerDiscovery {
  static const String liveProductionUrl = 'https://projeqta.com/api/v1';
  static const String ipv6Candidate =
      'http://[2401:4900:1c6f:701:ae48:ac67:9c58:e898]/projecta/api/v1';

  static const List<String> defaultCandidates = [
    'http://localhost:8080/projecta/api/v1',
    'http://127.0.0.1:8080/projecta/api/v1',
    liveProductionUrl,
    'http://${ApiClient.defaultLanIp}/projecta/api/v1',
    ipv6Candidate,
    'http://10.0.2.2/projecta/api/v1',
    'http://localhost/projecta/api/v1',
  ];

  /// Builds a deduplicated list of candidate endpoints, prioritizing USB tunnel & current baseUrl.
  static List<String> buildCandidates([String? currentBaseUrl]) {
    final list = <String>[
      'http://localhost:8080/projecta/api/v1',
      'http://127.0.0.1:8080/projecta/api/v1',
    ];
    if (currentBaseUrl != null && currentBaseUrl.trim().isNotEmpty) {
      list.add(currentBaseUrl.trim());
    }
    list.addAll([
      liveProductionUrl,
      'http://${ApiClient.defaultLanIp}/projecta/api/v1',
      ipv6Candidate,
      'http://10.0.2.2/projecta/api/v1',
      'http://localhost/projecta/api/v1',
    ]);

    final seen = <String>{};
    final unique = <String>[];
    for (final c in list) {
      final clean = c.trim().endsWith('/') ? c.substring(0, c.length - 1) : c;
      if (seen.add(clean)) {
        unique.add(clean);
      }
    }
    return unique;
  }

  /// Races candidate endpoints in parallel and switches ApiClient baseUrl
  /// to the fastest server that responds with HTTP 200 to /health.
  static Future<String?> probeAndSelectFastest({
    List<String>? candidates,
    Duration timeout = const Duration(milliseconds: 1500),
    http.Client? client,
  }) async {
    if (kIsWeb) return null;

    // When the app is configured for live production and no custom candidates list is passed,
    // do not allow local development servers to hijack the production connection.
    if (ApiClient().baseUrl == liveProductionUrl && candidates == null) {
      return liveProductionUrl;
    }

    final targetCandidates = candidates ?? buildCandidates(ApiClient().baseUrl);
    if (targetCandidates.isEmpty) return null;

    final httpClient = client ?? http.Client();
    final completer = Completer<String?>();
    int pending = targetCandidates.length;

    for (final url in targetCandidates) {
      final clean = url.trim().endsWith('/')
          ? url.substring(0, url.length - 1)
          : url;
      final healthUri = Uri.parse('$clean/health');

      httpClient
          .get(healthUri)
          .timeout(timeout)
          .then((response) {
            if (response.statusCode == 200 && !completer.isCompleted) {
              ApiClient().setBaseUrl(clean);
              completer.complete(clean);
            }
          })
          .catchError((_) {
            // Ignore individual probe error
          })
          .whenComplete(() {
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

  /// Tests a single endpoint's health and returns true if reachable with status 200.
  static Future<bool> testEndpoint(
    String url, {
    Duration timeout = const Duration(seconds: 2),
    http.Client? client,
  }) async {
    final clean = url.trim().endsWith('/')
        ? url.substring(0, url.length - 1)
        : url.trim();
    if (clean.isEmpty) return false;

    final httpClient = client ?? http.Client();
    try {
      final healthUri = Uri.parse('$clean/health');
      final res = await httpClient.get(healthUri).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Tests an endpoint and returns the round-trip latency in milliseconds, or null on failure.
  static Future<int?> getEndpointLatency(
    String url, {
    Duration timeout = const Duration(seconds: 2),
    http.Client? client,
  }) async {
    final clean = url.trim().endsWith('/')
        ? url.substring(0, url.length - 1)
        : url.trim();
    if (clean.isEmpty) return null;

    final httpClient = client ?? http.Client();
    final sw = Stopwatch()..start();
    try {
      final healthUri = Uri.parse('$clean/health');
      final res = await httpClient.get(healthUri).timeout(timeout);
      sw.stop();
      if (res.statusCode == 200) {
        return sw.elapsedMilliseconds;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
