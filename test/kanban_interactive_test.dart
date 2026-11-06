import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/models/task_model.dart';
import 'package:projecta_app/screens/tasks/tasks_screen.dart';
import 'package:projecta_app/services/task_service.dart';

class MockInteractiveTaskService extends TaskService {
  Map<String, List<TaskModel>> kanbanData;
  String? lastStatusUpdated;
  int? lastTaskIdUpdated;
  String? lastNoteUpdated;

  MockInteractiveTaskService({Map<String, List<TaskModel>>? initialData})
      : kanbanData = initialData ??
            {
              'not_started': [
                const TaskModel(
                  id: 101,
                  taskCode: 'TSK-101',
                  projectId: 1,
                  projectName: 'Alpha Portal',
                  title: 'Wireframe Kanban View',
                  priority: 'critical',
                  status: 'not_started',
                  deadline: '2026-11-20',
                  openDependenciesCount: 0,
                  allowedStatuses: ['not_started', 'in_progress', 'blocked'],
                  assignees: [
                    TaskAssigneeModel(
                      userId: 1,
                      fullName: 'Alice Developer',
                      responsibility: 'owner',
                    ),
                    TaskAssigneeModel(
                      userId: 2,
                      fullName: 'Bob Architect',
                      responsibility: 'contributor',
                    ),
                  ],
                ),
              ],
              'in_progress': [
                const TaskModel(
                  id: 102,
                  taskCode: 'TSK-102',
                  projectId: 1,
                  projectName: 'Alpha Portal',
                  title: 'Implement Touch Drag & Drop',
                  priority: 'high',
                  status: 'in_progress',
                  deadline: '2026-11-25',
                  progress: 60,
                  allowedStatuses: [
                    'in_progress',
                    'pending_review',
                    'blocked'
                  ],
                  assignees: [
                    TaskAssigneeModel(
                      userId: 1,
                      fullName: 'Alice Developer',
                      responsibility: 'owner',
                    ),
                  ],
                ),
              ],
              'blocked': [
                const TaskModel(
                  id: 103,
                  taskCode: 'TSK-103',
                  projectId: 1,
                  projectName: 'Alpha Portal',
                  title: 'API Authentication Flow',
                  priority: 'medium',
                  status: 'blocked',
                  openDependenciesCount: 2,
                  allowedStatuses: ['blocked'],
                  assignees: [],
                ),
              ],
              'pending_review': [],
              'completed': [],
            };

  @override
  Future<Map<String, dynamic>> getKanban({
    int? projectId,
    String? priority,
    int? userId,
  }) async {
    if (priority == null || priority == 'all') {
      return {'columns': Map.from(kanbanData), 'is_cached': false};
    }
    final filtered = <String, List<TaskModel>>{};
    kanbanData.forEach((k, list) {
      filtered[k] = list.where((t) => t.priority.toLowerCase() == priority.toLowerCase()).toList();
    });
    return {'columns': filtered, 'is_cached': false};
  }

  @override
  Future<Map<String, dynamic>> getTasks({
    int? projectId,
    String? status,
    String? priority,
    bool? overdue,
    bool? assignedToMe,
    String? search,
    int page = 1,
    int limit = 30,
  }) async {
    return {'tasks': <TaskModel>[], 'total': 0};
  }

  @override
  Future<Map<String, dynamic>> updateStatus(
    int id, {
    required String status,
    int? progress,
    String? note,
  }) async {
    lastTaskIdUpdated = id;
    lastStatusUpdated = status;
    lastNoteUpdated = note;
    return {'ok': true, 'message': 'Status updated'};
  }
}

void main() {
  group('Kanban Interactive Engine Tests', () {
    test('TaskModel correctly parses allowed_statuses and assignees', () {
      final json = {
        'id': 42,
        'task_code': 'TSK-042',
        'project_id': 5,
        'title': 'Test Mobile Card',
        'priority': 'critical',
        'status': 'not_started',
        'open_dependencies_count': 1,
        'allowed_statuses': ['not_started', 'in_progress'],
        'assignees': [
          {
            'user_id': 10,
            'full_name': 'Jane Doe',
            'responsibility': 'owner',
          },
          {
            'user_id': 11,
            'full_name': 'John Smith',
            'responsibility': 'contributor',
          },
          {
            'user_id': 12,
            'full_name': 'Carlos Ray',
            'responsibility': 'contributor',
          },
          {
            'user_id': 13,
            'full_name': 'Diana Prince',
            'responsibility': 'contributor',
          },
        ],
      };

      final model = TaskModel.fromJson(json);

      expect(model.id, 42);
      expect(model.taskCode, 'TSK-042');
      expect(model.priority, 'critical');
      expect(model.isLocked, isTrue);
      expect(model.allowedStatuses, ['not_started', 'in_progress']);
      expect(model.isStatusAllowed('in_progress'), isTrue);
      expect(model.isStatusAllowed('completed'), isFalse);
      expect(model.assignees.length, 4);
      expect(model.assignees.first.fullName, 'Jane Doe');
      expect(model.assignees.first.isOwner, isTrue);
    });

    testWidgets('TasksScreen switches to Kanban view and renders columns & pills',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockService = MockInteractiveTaskService();

      await tester.pumpWidget(
        MaterialApp(
          home: TasksScreen(taskService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      // Initially in List view
      expect(find.text('List View'), findsOneWidget);
      expect(find.text('Kanban Board'), findsOneWidget);

      // Switch to Kanban view
      await tester.tap(find.text('Kanban Board'));
      await tester.pumpAndSettle();

      // Verify Kanban priority filter pills
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Critical'), findsWidgets);
      expect(find.text('High'), findsWidgets);

      // Verify Column tabs
      expect(find.text('Not Started (1)'), findsOneWidget);
      expect(find.text('In Progress (1)'), findsOneWidget);
      expect(find.text('Blocked (1)'), findsOneWidget);

      // Verify task card content
      expect(find.text('Wireframe Kanban View'), findsOneWidget);
      expect(find.text('TSK-101'), findsOneWidget);
      expect(find.text('Critical'), findsWidgets);
    });

    testWidgets('Tapping status pill on Kanban card opens Status Move Sheet',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockService = MockInteractiveTaskService();

      await tester.pumpWidget(
        MaterialApp(
          home: TasksScreen(taskService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Kanban
      await tester.tap(find.text('Kanban Board'));
      await tester.pumpAndSettle();

      // Find the interactive status pill for task 101
      final pillFinder = find.byKey(const ValueKey('task_status_pill_101'));
      expect(pillFinder, findsOneWidget);

      // Tap on the pill inside the card
      await tester.tap(pillFinder);
      await tester.pumpAndSettle();

      // Verify bottom sheet opened
      expect(find.text('Move card to target column'), findsOneWidget);
      expect(find.text('Wireframe Kanban View'), findsWidgets);

      // Tap an allowed target: 'In Progress'
      await tester.tap(find.text('In Progress').last);
      await tester.pumpAndSettle();

      // Verify API was called
      expect(mockService.lastTaskIdUpdated, 101);
      expect(mockService.lastStatusUpdated, 'in_progress');
    });

    testWidgets('Blocked task displays open dependency lock banner',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockService = MockInteractiveTaskService();

      await tester.pumpWidget(
        MaterialApp(
          home: TasksScreen(taskService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Kanban
      await tester.tap(find.text('Kanban Board'));
      await tester.pumpAndSettle();

      // Tap column chip 'Blocked (1)' to jump directly to page 2
      await tester.tap(find.text('Blocked (1)'));
      await tester.pumpAndSettle();

      // Verify card in Blocked column
      expect(find.text('API Authentication Flow'), findsOneWidget);
      expect(find.text('Blocked by 2 dependencies'), findsOneWidget);
    });

    test('TaskModel nextAllowedStatusesFor dynamically recalculates transitions for staff and manager', () {
      // 1. Staff task in not_started
      const staffTaskNotStarted = TaskModel(
        id: 201,
        taskCode: 'TSK-201',
        projectId: 1,
        title: 'Staff Task',
        priority: 'medium',
        status: 'not_started',
        allowedStatuses: ['not_started', 'in_progress', 'blocked'],
      );

      // Staff moving to in_progress should now be allowed to move to pending_review
      final nextStatuses = staffTaskNotStarted.nextAllowedStatusesFor('in_progress');
      expect(nextStatuses, contains('pending_review'));
      expect(nextStatuses, isNot(contains('completed')));

      // 2. Manager task in not_started
      const managerTask = TaskModel(
        id: 202,
        taskCode: 'TSK-202',
        projectId: 1,
        title: 'Manager Task',
        priority: 'critical',
        status: 'not_started',
        allowedStatuses: [
          'not_started',
          'in_progress',
          'blocked',
          'pending_review',
          'completed'
        ],
      );

      // Manager moving to in_progress retains all permissions including completed
      final managerNext = managerTask.nextAllowedStatusesFor('in_progress');
      expect(managerNext, contains('completed'));
      expect(managerNext, contains('pending_review'));
    });
  });
}
