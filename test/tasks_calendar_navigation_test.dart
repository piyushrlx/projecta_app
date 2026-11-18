import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/core/widgets/module_app_bar.dart';
import 'package:projecta_app/models/task_model.dart';
import 'package:projecta_app/screens/calendar/calendar_screen.dart';
import 'package:projecta_app/screens/tasks/tasks_screen.dart';
import 'package:projecta_app/services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountingFakeTaskService extends TaskService {
  int getTasksCallCount = 0;
  int getKanbanCallCount = 0;

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
    getTasksCallCount++;
    return {'tasks': <TaskModel>[], 'total': 0};
  }

  @override
  Future<Map<String, dynamic>> getKanban({
    int? projectId,
    String? priority,
    int? userId,
  }) async {
    getKanbanCallCount++;
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

  group('TasksScreen Header Calendar Navigation Tests', () {
    testWidgets(
      '1. Rendering: Calendar button is in ModuleAppBar header, ViewToggle has List View and Kanban Board',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: TasksScreen(taskService: _CountingFakeTaskService()),
          ),
        );
        await tester.pumpAndSettle();

        // Header ModuleAppBar has Calendar, Search, and Refresh
        final calendarAction = find.descendant(
          of: find.byType(ModuleAppBar),
          matching: find.byIcon(Icons.calendar_month_outlined),
        );
        expect(calendarAction, findsOneWidget);

        final searchAction = find.descendant(
          of: find.byType(ModuleAppBar),
          matching: find.byIcon(Icons.search),
        );
        expect(searchAction, findsOneWidget);

        final refreshAction = find.descendant(
          of: find.byType(ModuleAppBar),
          matching: find.byIcon(Icons.refresh),
        );
        expect(refreshAction, findsOneWidget);

        // View toggle dock has List View and Kanban Board
        expect(find.text('List View'), findsOneWidget);
        expect(find.text('Kanban Board'), findsOneWidget);

        // Semantics checks on dock
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label == 'Switch to List view' &&
                w.properties.selected == true,
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label == 'Switch to Kanban board' &&
                w.properties.selected == false,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '2. Navigation Flow: Tap header Calendar button pushes CalendarScreen, pop back retains state',
      (tester) async {
        final service = _CountingFakeTaskService();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: TasksScreen(taskService: service),
          ),
        );
        await tester.pumpAndSettle();

        final initialLoadCount = service.getTasksCallCount;
        expect(initialLoadCount, greaterThan(0));

        // Tap the Calendar button in the header
        final calendarButton = find.byTooltip('Calendar & Deadlines');
        expect(calendarButton, findsOneWidget);
        await tester.tap(calendarButton);
        await tester.pumpAndSettle();

        // Verify CalendarScreen is displayed
        expect(find.byType(CalendarScreen), findsOneWidget);
        expect(find.text('Calendar & Deadlines'), findsOneWidget);

        // Pop back to TasksScreen (simulating no changes made)
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.pop(false);
        await tester.pumpAndSettle();

        // Verify back on TasksScreen
        expect(find.byType(TasksScreen), findsOneWidget);
        expect(find.text('List View'), findsOneWidget);
        expect(find.text('Kanban Board'), findsOneWidget);

        // Verify no blocking reload spinner was triggered because changed == false
        expect(service.getTasksCallCount, equals(initialLoadCount));
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      '3. Double-Tap Protection: Fast consecutive taps on header Calendar button do not push multiple routes',
      (tester) async {
        final service = _CountingFakeTaskService();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: TasksScreen(taskService: service),
          ),
        );
        await tester.pumpAndSettle();

        final calendarButton = find.byTooltip('Calendar & Deadlines');

        // Fast double-tap
        await tester.tap(calendarButton);
        await tester.tap(calendarButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Exactly one CalendarScreen is pushed
        expect(find.byType(CalendarScreen), findsOneWidget);

        // Pop once -> returns directly to TasksScreen
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.pop();
        await tester.pumpAndSettle();

        expect(find.byType(TasksScreen), findsOneWidget);
        expect(find.byType(CalendarScreen), findsNothing);
      },
    );

    testWidgets(
      '4. Responsive Integrity: 320x640 with 1.3x text scale renders header and dock without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 640 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.3),
              ),
              child: TasksScreen(taskService: _CountingFakeTaskService()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('List View'), findsOneWidget);
        expect(find.text('Kanban Board'), findsOneWidget);
      },
    );
  });
}
