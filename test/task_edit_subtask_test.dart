import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:projecta_app/core/api_client.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/task_model.dart';
import 'package:projecta_app/screens/tasks/create_task_screen.dart';
import 'package:projecta_app/screens/tasks/task_detail_screen.dart';
import 'package:projecta_app/screens/tasks/task_form_screen.dart';
import 'package:projecta_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock-valid-token-admin',
      'user_role': 'super_admin',
      'api_base_url': 'http://localhost/projecta/api/v1',
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

    final mockClient = MockClient((request) async {
      final path = request.url.path;

      if (path.contains('/projects/101') || path.contains('/projects/1')) {
        return http.Response(
          jsonEncode({
            'ok': true,
            'project': {
              'id': 101,
              'name': 'ERP Platform Overhaul',
              'manager_id': 1,
              'manager_name': 'Aman Bhatia',
              'status': 'active',
              'priority': 'high',
            },
            'members': [
              {
                'user_id': 1,
                'full_name': 'Aman Bhatia',
                'member_role': 'lead',
                'designation': 'Executive Lead',
              },
              {
                'user_id': 3,
                'full_name': 'Harshit Kumar',
                'member_role': 'member',
                'designation': 'Frontend Engineer',
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
                'id': 101,
                'project_code': 'P-0101',
                'name': 'ERP Platform Overhaul',
                'status': 'active',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      } else if (path.contains('/tasks/201')) {
        return http.Response(
          jsonEncode({
            'ok': true,
            'task': {
              'id': 201,
              'task_code': 'T-0201',
              'project_id': 101,
              'project_name': 'ERP Platform Overhaul',
              'title': 'Design System Migration',
              'description': 'Migrate legacy CSS to Tailwind CSS',
              'instructions': 'Ensure color parity with Figma token sheet',
              'priority': 'high',
              'status': 'in_progress',
              'progress': 40,
              'start_date': '2026-11-01',
              'deadline': '2026-11-15',
              'estimated_hours': 12.5,
              'can_manage': true,
              'can_work': true,
              'allowed_statuses': ['in_progress', 'completed'],
            },
            'assignees': [
              {
                'user_id': 1,
                'full_name': 'Aman Bhatia',
                'responsibility': 'owner',
              },
            ],
            'subtasks': [
              {
                'id': 301,
                'task_code': 'T-0301',
                'title': 'Audit Figma Tokens',
                'priority': 'medium',
                'status': 'completed',
                'progress': 100,
              },
            ],
            'depends_on': [],
            'dependent_tasks': [],
            'extension_requests': [],
            'status_history': [],
            'attachments': [],
            'comments_count': 0,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      } else if (path.contains('/tasks/202')) {
        return http.Response(
          jsonEncode({
            'ok': true,
            'task': {
              'id': 202,
              'task_code': 'T-0202',
              'project_id': 101,
              'project_name': 'ERP Platform Overhaul',
              'title': 'Staff Contributor Task',
              'priority': 'low',
              'status': 'not_started',
              'progress': 0,
              'can_manage': false,
              'can_work': true,
              'allowed_statuses': ['not_started'],
            },
            'assignees': [],
            'subtasks': [],
            'depends_on': [],
            'dependent_tasks': [],
            'extension_requests': [],
            'status_history': [],
            'attachments': [],
            'comments_count': 0,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response(
        jsonEncode({'ok': true}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    ApiClient().customHttpClient = mockClient;
  });

  tearDown(() {
    ApiClient().resetHttpClient();
  });

  group('Module 4: TaskFormScreen in Create Mode Tests', () {
    testWidgets('Renders all create fields and validates empty title', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: const TaskFormScreen(initialProjectId: 101),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assign New Task'), findsOneWidget);
      expect(find.text('Task Title *'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('Deadline'), findsOneWidget);
      expect(find.text('Estimated Hours'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Assign Task'), findsOneWidget);

      // Attempt to submit empty title
      await tester.tap(find.text('Assign Task'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a task title.'), findsOneWidget);
    });
  });

  group('Module 4: TaskFormScreen in Edit Mode Tests', () {
    final existingDetail = TaskDetailModel(
      task: const TaskModel(
        id: 201,
        taskCode: 'T-0201',
        projectId: 101,
        projectName: 'ERP Platform Overhaul',
        title: 'Design System Migration',
        priority: 'high',
        status: 'in_progress',
        estimatedHours: 12.5,
        startDate: '2026-11-01',
        deadline: '2026-11-15',
      ),
      description: 'Migrate legacy CSS to Tailwind CSS',
      instructions: 'Ensure color parity with Figma token sheet',
      canManage: true,
      canWork: true,
      assignees: const [
        TaskAssigneeModel(
          userId: 1,
          fullName: 'Aman Bhatia',
          responsibility: 'owner',
        ),
      ],
    );

    testWidgets('Pre-fills existing task details, title, and assignees', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: TaskFormScreen(detail: existingDetail),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Task'), findsOneWidget);
      expect(find.text('Design System Migration'), findsOneWidget);
      expect(find.text('Migrate legacy CSS to Tailwind CSS'), findsOneWidget);
      expect(find.text('12.5'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });

  group('Module 4: TaskFormScreen in Subtask Mode Tests', () {
    testWidgets('Renders subtask header and parent task banner', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: const TaskFormScreen(
            initialProjectId: 101,
            parentTaskId: 201,
            parentTaskTitle: 'Design System Migration',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Subtask'), findsOneWidget);
      expect(find.text('Subtask of: Design System Migration'), findsOneWidget);
      expect(find.text('Create Subtask'), findsOneWidget);
    });
  });

  group('Module 4: TaskDetailScreen Manager Actions Tests', () {
    testWidgets(
      'Displays Edit action button in AppBar when user can manage task',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: const TaskDetailScreen(taskId: 201),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
        expect(find.text('Subtasks (1)'), findsOneWidget);
        expect(find.text('Add Subtask'), findsOneWidget);
        expect(find.text('T-0301 · Audit Figma Tokens'), findsOneWidget);
      },
    );

    testWidgets('Hides Edit action button when user cannot manage task', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: const TaskDetailScreen(taskId: 202),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });
  });

  group('Module 4: CreateTaskScreen Backward Compatibility', () {
    testWidgets('CreateTaskScreen renders seamlessly as TaskFormScreen wrapper', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: const CreateTaskScreen(initialProjectId: 101),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assign New Task'), findsOneWidget);
    });
  });
}
