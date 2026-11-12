import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/core/widgets/brutalist_pressable.dart';
import 'package:projecta_app/core/widgets/module_app_bar.dart';
import 'package:projecta_app/models/task_model.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/dashboard/admin_dashboard_view.dart';
import 'package:projecta_app/screens/dashboard/staff_dashboard_view.dart';
import 'package:projecta_app/screens/tasks/tasks_screen.dart';
import 'package:projecta_app/services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeTaskService extends TaskService {
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
  Future<Map<String, dynamic>> getKanban({
    int? projectId,
    String? priority,
    int? userId,
  }) async {
    return {
      'is_cached': false,
      'columns': {
        'not_started': [],
        'in_progress': [],
        'blocked': [],
        'pending_review': [],
        'completed': [],
      },
    };
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const staffUser = UserModel(
    id: 3,
    name: 'Harshit Staff',
    email: 'harshit@rankfirst.tech',
    role: 'staff',
    adminScope: 'assigned',
    mustChangePassword: false,
    departmentName: 'Engineering',
  );

  const adminUser = UserModel(
    id: 1,
    name: 'Aman Admin',
    email: 'aman@domain.com',
    role: 'admin',
    adminScope: 'all',
    mustChangePassword: false,
    departmentName: 'Executive',
  );

  group('UI/UX Spec: Enterprise Pressable Tactile Interaction', () {
    testWidgets('Pressable scales smoothly and triggers onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Scaffold(
            body: BrutalistPressable(
              onTap: () => tapped = true,
              child: const Text('TEST BUTTON'),
            ),
          ),
        ),
      );

      expect(find.text('TEST BUTTON'), findsOneWidget);

      final animatedScale = tester.widget<AnimatedScale>(
        find.byType(AnimatedScale),
      );
      expect(animatedScale.scale, 1.0);

      // Tap and hold
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('TEST BUTTON')),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final pressedScale = tester.widget<AnimatedScale>(
        find.byType(AnimatedScale),
      );
      expect(pressedScale.scale, 0.985);

      // Release
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('UI/UX Spec: Staff Dashboard #1 Hero Task Card', () {
    testWidgets(
      'Staff Dashboard highlights the #1 "Work On This Next" Hero Task Card',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockStaffData = {
          'role': 'staff',
          'date': '2026-11-04',
          'compliance_badge': {
            'status_key': 'pending',
            'label': 'Pending',
            'deadline_time': '07:00 PM',
          },
          'kpis': {
            'active_projects': 3,
            'open_tasks': 8,
            'in_progress_tasks': 4,
            'overdue': 2,
          },
          'what_to_work_on_next': [
            {
              'id': 101,
              'title': 'Implement API Authentication Bridge',
              'project_name': 'Projecta Mobile',
              'progress': 75,
              'reason': 'Overdue by 1 day',
              'is_overdue': true,
              'deadline': '2026-11-02',
            },
            {
              'id': 102,
              'title': 'Design Neo-Brutalist Layout',
              'project_name': 'Projecta UI',
              'progress': 40,
              'reason': 'Due Today',
              'is_overdue': false,
              'deadline': '2026-11-04',
            },
          ],
          'recent_feedback': [],
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: Scaffold(
              body: StaffDashboardView(
                user: staffUser,
                data: mockStaffData,
                onRefresh: () {},
              ),
            ),
          ),
        );

        // Verify Hero card header and tag
        expect(find.text('What should I work on next?'), findsOneWidget);
        expect(find.text('Next Up (#1 Hero)'), findsOneWidget);
        expect(
          find.text('Implement API Authentication Bridge'),
          findsOneWidget,
        );
        expect(find.text('Update Status'), findsOneWidget);

        // Verify remaining queue has the second item
        expect(find.text('Upcoming in Queue'), findsOneWidget);
        expect(find.text('Design Neo-Brutalist Layout'), findsOneWidget);
      },
    );
  });

  group('UI/UX Spec: Admin Dashboard Top Urgent Action Strip', () {
    testWidgets(
      'Admin Dashboard highlights Urgent Overdue and Pending Report banner at the top',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockAdminData = {
          'role': 'admin',
          'date': '2026-11-04',
          'kpis': {
            'active_projects': 5,
            'completed_projects': 10,
            'open_tasks': 25,
            'tasks_in_progress': 12,
            'completed_tasks': 48,
            'pending_tasks': 13,
            'overdue_tasks': 4,
            'active_employees': 8,
            'reports_submitted_today': 6,
            'reports_pending_today': 2,
            'compliance_percent': 75,
          },
          'alerts': {
            'reports_awaiting_review': 3,
            'overdue_tasks': [
              {
                'id': 201,
                'title': 'Fix Session Timeout Logic',
                'project_name': 'Backend API',
                'deadline': '2026-11-01',
              },
            ],
            'blocked_tasks': [],
          },
          'active_projects': [],
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: Scaffold(
              body: AdminDashboardView(
                user: adminUser,
                data: mockAdminData,
                onRefresh: () {},
              ),
            ),
          ),
        );

        // Verify Action Strip at top
        expect(find.text('Admin Executive Control'), findsOneWidget);
        expect(find.text('OVERDUE'), findsOneWidget); // Top strip & KPI card
        expect(find.text('PENDING'), findsOneWidget);
        expect(find.textContaining('Reports Awaiting Review'), findsOneWidget);
      },
    );
  });

  group('UI/UX Spec: TasksScreen Mobile Kanban Snapping', () {
    testWidgets(
      'TasksScreen switches to Kanban view with PageView snapping (viewportFraction: 0.88)',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: Scaffold(body: TasksScreen(taskService: FakeTaskService())),
          ),
        );

        // Verify List view by default
        expect(find.text('List View'), findsOneWidget);
        expect(find.text('Kanban Board'), findsOneWidget);

        // Switch to Kanban Board
        await tester.tap(find.text('Kanban Board'));
        await tester.pumpAndSettle();

        // Find PageView and verify viewportFraction is 0.88
        final pageViewFinder = find.byType(PageView);
        expect(pageViewFinder, findsOneWidget);

        final pageView = tester.widget<PageView>(pageViewFinder);
        final pageController = pageView.controller as PageController;
        expect(pageController.viewportFraction, 0.88);
      },
    );

    testWidgets(
      'TasksScreen header search icon filters List View via API and Kanban View client-side',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final searchService = _SearchableFakeTaskService();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: TasksScreen(taskService: searchService),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Alpha Migration'), findsOneWidget);
        expect(find.text('Beta Audit'), findsOneWidget);

        // Open inline search bar from ModuleAppBar
        final headerSearchIcon = find.descendant(
          of: find.byType(ModuleAppBar),
          matching: find.byIcon(Icons.search),
        );
        expect(headerSearchIcon, findsOneWidget);
        await tester.tap(headerSearchIcon);
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Alpha');
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pumpAndSettle();

        expect(searchService.lastListSearch, 'Alpha');
        expect(find.text('Alpha Migration'), findsOneWidget);
        expect(find.text('Beta Audit'), findsNothing);

        // Switch to Kanban view -> client-side search filter should keep Alpha only
        await tester.tap(find.text('Kanban Board'));
        await tester.pumpAndSettle();

        expect(find.text('Alpha Migration'), findsOneWidget);
        expect(find.text('Beta Audit'), findsNothing);

        // Closing search bar clears filter and restores Beta Audit in Kanban
        await tester.tap(find.byIcon(Icons.search_off));
        await tester.pumpAndSettle();

        expect(find.text('Alpha Migration'), findsOneWidget);
        expect(find.text('Beta Audit'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _SearchableFakeTaskService extends TaskService {
  String? lastListSearch;

  final List<TaskModel> _allTasks = const [
    TaskModel(
      id: 1,
      taskCode: 'T-0001',
      projectId: 10,
      projectName: 'Core ERP',
      title: 'Alpha Migration',
      priority: 'high',
      status: 'in_progress',
      progress: 40,
    ),
    TaskModel(
      id: 2,
      taskCode: 'T-0002',
      projectId: 11,
      projectName: 'Security Ops',
      title: 'Beta Audit',
      priority: 'medium',
      status: 'not_started',
      progress: 0,
    ),
  ];

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
    lastListSearch = search;
    final query = search?.trim().toLowerCase() ?? '';
    final filtered = query.isEmpty
        ? _allTasks
        : _allTasks
              .where((t) => t.title.toLowerCase().contains(query))
              .toList();
    return {'tasks': filtered, 'total': filtered.length};
  }

  @override
  Future<Map<String, dynamic>> getKanban({
    int? projectId,
    String? priority,
    int? userId,
  }) async {
    return {
      'is_cached': false,
      'columns': {
        'not_started': [_allTasks[1]],
        'in_progress': [_allTasks[0]],
        'blocked': <TaskModel>[],
        'pending_review': <TaskModel>[],
        'completed': <TaskModel>[],
      },
    };
  }
}
