import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:projecta_app/core/api_client.dart';
import 'package:projecta_app/screens/tasks/task_form_screen.dart';
import 'package:projecta_app/services/auth_service.dart';
import 'package:projecta_app/services/project_service.dart';
import 'package:projecta_app/services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock-valid-token-admin',
      'user_role': 'super_admin',
      'api_base_url': 'http://localhost/projecta/api/v1',
      'cache_/projects_limit=20': jsonEncode({
        'ok': true,
        'projects': [
          {'id': 101, 'name': 'Old Cached Project', 'status': 'active'},
        ],
      }),
      'auth_user': jsonEncode({
        'id': 1,
        'full_name': 'Aman Bhatia',
        'email': 'aamannbhatia@gmail.com',
        'role': 'super_admin',
        'is_admin': true,
        'must_change_password': false,
      }),
    });
    await AuthService().getCurrentUser();
  });

  tearDown(() {
    ApiClient().resetHttpClient();
  });

  group('TaskService - Project Fetching for Task Creation', () {
    test('getActiveProjects includes planned, active, on_hold projects and excludes completed/cancelled', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/projects'));
        // Verify it queries without hardcoded status=active restriction
        expect(request.url.queryParameters['status'], isNull);

        return http.Response(
          jsonEncode({
            'ok': true,
            'projects': [
              {
                'id': 18,
                'project_code': 'P-0018',
                'name': 'test_New_project_for(All)',
                'status': 'planned',
              },
              {
                'id': 17,
                'project_code': 'P-0017',
                'name': 'pb_tes2',
                'status': 'on_hold',
              },
              {
                'id': 16,
                'project_code': 'P-0016',
                'name': 'pb_test',
                'status': 'active',
              },
              {
                'id': 99,
                'project_code': 'P-0099',
                'name': 'Finished Project',
                'status': 'completed',
              },
              {
                'id': 100,
                'project_code': 'P-0100',
                'name': 'Discarded Project',
                'status': 'cancelled',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      ApiClient().customHttpClient = mockClient;
      final taskService = TaskService();

      final projects = await taskService.getActiveProjects();

      expect(projects.length, 3);
      final names = projects.map((p) => p['name']).toList();
      expect(names, contains('test_New_project_for(All)'));
      expect(names, contains('pb_tes2'));
      expect(names, contains('pb_test'));
      expect(names, isNot(contains('Finished Project')));
      expect(names, isNot(contains('Discarded Project')));
    });
  });

  group('ProjectService - Cache Invalidation on Project Creation', () {
    test('saveProject clears offline cache so newly created project is visible', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().any((k) => k.startsWith('cache_')), isTrue);

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/projects')) {
          return http.Response(
            jsonEncode({
              'ok': true,
              'id': 19,
              'message': 'Project created successfully.',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      ApiClient().customHttpClient = mockClient;
      final projectService = ProjectService();

      await projectService.saveProject({
        'name': 'Brand New Project',
        'status': 'planned',
      });

      // Verify that offline cache was wiped upon saving
      final remainingCacheKeys =
          prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
      expect(remainingCacheKeys.isEmpty, isTrue);
    });
  });

  group('TaskFormScreen - Project Dropdown Integration', () {
    testWidgets('Renders newly created planned project in dropdown with project code and loads all team members including viewers', (
      WidgetTester tester,
    ) async {
      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path.contains('/projects/18')) {
          return http.Response(
            jsonEncode({
              'ok': true,
              'project': {
                'id': 18,
                'name': 'test_New_project_for(All)',
                'project_code': 'P-0018',
                'manager_id': 1,
                'manager_name': 'Aman Bhatia',
                'status': 'planned',
                'priority': 'medium',
              },
              'members': [
                {
                  'user_id': 1,
                  'full_name': 'Aman Bhatia',
                  'member_role': 'manager',
                  'designation': 'Executive Lead',
                },
                {
                  'user_id': 5,
                  'full_name': 'Rahul Dhiman',
                  'member_role': 'member',
                  'designation': 'Senior Developer',
                },
                {
                  'user_id': 6,
                  'full_name': 'Piyush Bhatt',
                  'member_role': 'viewer',
                  'designation': 'UI/UX Designer',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (path.contains('/projects')) {
          return http.Response(
            jsonEncode({
              'ok': true,
              'projects': [
                {
                  'id': 18,
                  'project_code': 'P-0018',
                  'name': 'test_New_project_for(All)',
                  'status': 'planned',
                },
                {
                  'id': 16,
                  'project_code': 'P-0016',
                  'name': 'pb_test',
                  'status': 'active',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (path.contains('/employees')) {
          return http.Response(
            jsonEncode({
              'ok': true,
              'employees': [
                {'id': 1, 'full_name': 'Aman Bhatia'},
                {'id': 5, 'full_name': 'Rahul Dhiman'},
                {'id': 6, 'full_name': 'Piyush Bhatt'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      ApiClient().customHttpClient = mockClient;

      await tester.pumpWidget(
        const MaterialApp(
          home: TaskFormScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the dropdown renders the newly created project with its code
      expect(find.text('test_New_project_for(All) (P-0018)'), findsOneWidget);

      // Verify that all members (manager, member, and viewer) are loaded
      expect(find.textContaining('Aman Bhatia'), findsOneWidget);

      // Tap the owner dropdown to open it and verify Rahul Dhiman and Piyush Bhatt are present
      await tester.ensureVisible(find.textContaining('Aman Bhatia').first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Aman Bhatia').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Rahul Dhiman'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Piyush Bhatt'), findsAtLeastNWidgets(1));
    });
  });
}
