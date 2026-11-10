import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:projecta_app/core/api_client.dart';
import 'package:projecta_app/core/async_server_discovery.dart';
import 'package:projecta_app/core/widgets/offline_cache_banner.dart';
import 'package:projecta_app/services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4: Resilient Network & Offline Cache Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ApiClient getWithCache returns cached response on network failure', () async {
      final client = ApiClient();
      final prefs = await SharedPreferences.getInstance();

      // Pre-seed cache with sample task payload
      const testCacheKey = 'cache_/tasks_page=1&limit=30';
      final dummyJson = jsonEncode({
        'ok': true,
        'tasks': [
          {'id': 999, 'task_code': 'T-0999', 'title': 'Cached Offline Task'}
        ],
        'total': 1,
      });
      await prefs.setString(testCacheKey, dummyJson);

      // Force request to an unreachable endpoint to trigger offline fallback
      await client.setBaseUrl('http://192.0.2.1:9999'); // Non-routable TEST-NET-1 IP

      final response = await client.getWithCache(
        '/tasks',
        queryParameters: {'page': '1', 'limit': '30'},
      );

      expect(response.statusCode, 200);
      expect(ApiClient.isCachedResponse(response), isTrue);

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      expect(decoded['total'], 1);
      expect(decoded['tasks'][0]['task_code'], 'T-0999');
    });

    test('AsyncServerDiscovery races endpoints and selects fastest responding 200', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('8080')) {
          // Fastest endpoint responds immediately
          return http.Response(jsonEncode({'ok': true}), 200);
        } else {
          // Slow endpoint
          await Future.delayed(const Duration(milliseconds: 500));
          return http.Response(jsonEncode({'ok': true}), 200);
        }
      });

      final selected = await AsyncServerDiscovery.probeAndSelectFastest(
        candidates: [
          'http://192.168.1.99/projecta/api/v1',
          'http://localhost:8080/projecta/api/v1',
        ],
        client: mockClient,
      );

      expect(selected, 'http://localhost:8080/projecta/api/v1');
      expect(ApiClient().baseUrl, 'http://localhost:8080/projecta/api/v1');
    });

    test('ApiClient getWithCache purges corrupted JSON from cache and throws network error', () async {
      final client = ApiClient();
      final prefs = await SharedPreferences.getInstance();

      const testCacheKey = 'cache_/corrupted_endpoint_';
      await prefs.setString(testCacheKey, '<html>502 Bad Gateway</html>');

      await client.setBaseUrl('http://192.0.2.1:9999');

      await expectLater(
        () => client.getWithCache('/corrupted_endpoint'),
        throwsA(isA<ApiException>()),
      );

      // Verify corrupted key was purged
      expect(prefs.containsKey(testCacheKey), isFalse);
    });

    testWidgets('OfflineCacheBanner renders ambient amber styling and retry action', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineCacheBanner(
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Viewing offline cached data. Actions are read-only.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retried, isTrue);
    });

    test('ApiClient decodeJson wraps FormatException into ApiException on non-JSON response', () {
      final client = ApiClient();
      final htmlResponse = http.Response('<html><body>502 Bad Gateway</body></html>', 200);

      expect(
        () => client.decodeJson(htmlResponse),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('non-JSON payload'))),
      );
    });

    test('ApiClient getWithCache does not cache non-JSON 200 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('<html>Captive Portal</html>', 200, headers: {'content-type': 'text/html'});
      });
      final client = ApiClient();
      client.customHttpClient = mockClient;
      final prefs = await SharedPreferences.getInstance();

      final res = await client.getWithCache('/portal_test');
      expect(res.statusCode, 200);
      expect(prefs.containsKey('cache_/portal_test_'), isFalse);
      client.resetHttpClient();
    });

    test('TaskService getKanban returns is_cached=true when serving from cache', () async {
      final client = ApiClient();
      final prefs = await SharedPreferences.getInstance();

      const kanbanKey = 'cache_/kanban_';
      final dummyKanban = jsonEncode({
        'ok': true,
        'columns': {
          'not_started': [{'id': 101, 'task_code': 'T-0101', 'title': 'Cached Kanban Task'}],
          'in_progress': [],
          'blocked': [],
          'pending_review': [],
          'completed': [],
        },
      });
      await prefs.setString(kanbanKey, dummyKanban);
      await client.setBaseUrl('http://192.0.2.1:9999');

      final taskService = TaskService(client: client);
      final res = await taskService.getKanban();

      expect(res['is_cached'], isTrue);
      final cols = res['columns'] as Map<String, List<dynamic>>;
      expect(cols['not_started']!.length, 1);
      expect(cols['not_started']!.first.taskCode, 'T-0101');
    });

    test('ApiClient resolveMediaUrl correctly rewrites localhost URLs for physical devices', () async {
      final client = ApiClient();
      await client.setBaseUrl('http://192.168.1.100/projecta/api/v1');

      // Absolute localhost URL
      expect(
        client.resolveMediaUrl('http://localhost/projecta/uploads/avatars/user1.png'),
        'http://192.168.1.100/projecta/uploads/avatars/user1.png',
      );

      // 127.0.0.1 URL
      expect(
        client.resolveMediaUrl('http://127.0.0.1/projecta/uploads/avatars/user2.png'),
        'http://192.168.1.100/projecta/uploads/avatars/user2.png',
      );

      // Relative path
      expect(
        client.resolveMediaUrl('uploads/avatars/user3.png'),
        'http://192.168.1.100/projecta/uploads/avatars/user3.png',
      );

      // External CDN URL preserved
      expect(
        client.resolveMediaUrl('https://example.com/avatar.png'),
        'https://example.com/avatar.png',
      );

      // Null or empty handling
      expect(client.resolveMediaUrl(null), isNull);
      expect(client.resolveMediaUrl(''), isNull);
      expect(client.resolveMediaUrl('   '), isNull);
    });
  });
}

