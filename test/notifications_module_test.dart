import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/widgets/app_side_drawer.dart';
import 'package:projecta_app/models/notification_model.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/notifications/notifications_screen.dart';
import 'package:projecta_app/screens/tasks/task_detail_screen.dart';
import 'package:projecta_app/services/notification_service.dart';

class MockNotificationService extends NotificationService {
  List<NotificationModel> mockItems;
  int unreadCount;
  final List<int> markReadCalls = [];
  int markAllReadCalls = 0;

  MockNotificationService({
    required this.mockItems,
    required this.unreadCount,
  });

  @override
  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 30}) async {
    return {
      'notifications': mockItems,
      'unread_count': unreadCount,
      'total': mockItems.length,
    };
  }

  @override
  Future<void> markRead(int id) async {
    markReadCalls.add(id);
    final idx = mockItems.indexWhere((m) => m.id == id);
    if (idx != -1 && !mockItems[idx].isRead) {
      mockItems[idx] = mockItems[idx].copyWith(isRead: true);
      unreadCount = (unreadCount - 1).clamp(0, 9999);
    }
  }

  @override
  Future<void> markAllRead() async {
    markAllReadCalls++;
    mockItems = mockItems.map((m) => m.copyWith(isRead: true)).toList();
    unreadCount = 0;
  }
}

void main() {
  const testUser = UserModel(
    id: 1,
    name: 'Piyush Bhatt',
    email: 'piyush@example.com',
    role: 'super_admin',
    adminScope: 'all',
    mustChangePassword: false,
  );

  final sampleNotifications = [
    const NotificationModel(
      id: 101,
      type: 'task_assigned',
      title: 'Task Assigned: Flutter Auth',
      message: 'You were assigned to Flutter Auth.',
      link: 'task-details.php?id=55',
      isRead: false,
      createdAt: '2026-11-11 09:30:00',
    ),
    const NotificationModel(
      id: 102,
      type: 'overdue',
      title: 'Overdue task: Mobile API Client',
      message: 'Task is 2 days overdue.',
      link: 'task-details.php?id=56',
      isRead: false,
      createdAt: '2026-11-11 10:00:00',
    ),
    const NotificationModel(
      id: 103,
      type: 'project_update',
      title: 'Project Milestone Achieved',
      message: 'Phase 1 completed for Alpha.',
      link: 'project-details.php?id=12',
      isRead: false,
      createdAt: '2026-11-11 10:30:00',
    ),
    const NotificationModel(
      id: 104,
      type: 'report_missing',
      title: 'Daily Report Missing',
      message: 'Please submit daily report.',
      link: 'submit-report.php?date=2026-11-11',
      isRead: true,
      createdAt: '2026-11-10 18:00:00',
    ),
  ];

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
      theme: ThemeData(useMaterial3: true),
    );
  }

  group('NotificationsScreen & Deep-Linking Module Tests', () {
    testWidgets('Renders AppBar, filters, and notification cards with badges', (tester) async {
      final mockService = MockNotificationService(
        mockItems: List.from(sampleNotifications),
        unreadCount: 3,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          NotificationsScreen(
            user: testUser,
            notificationService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Mark all read
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);

      // Verify 5 Filter chips
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('UNREAD'), findsOneWidget);
      expect(find.text('TASKS'), findsOneWidget);
      expect(find.text('PROJECTS'), findsOneWidget);
      expect(find.text('REPORTS'), findsOneWidget);

      // Verify cards rendered
      expect(find.text('Task Assigned: Flutter Auth'), findsOneWidget);
      expect(find.text('Overdue task: Mobile API Client'), findsOneWidget);
      expect(find.text('Project Milestone Achieved'), findsOneWidget);
      expect(find.text('Daily Report Missing'), findsOneWidget);

      // Verify NEW & URGENT badges
      expect(find.text('NEW'), findsNWidgets(2));
      expect(find.text('URGENT'), findsOneWidget);
    });

    testWidgets('Filter pills filter notifications by category and unread state', (tester) async {
      final mockService = MockNotificationService(
        mockItems: List.from(sampleNotifications),
        unreadCount: 3,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          NotificationsScreen(
            user: testUser,
            notificationService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap UNREAD filter
      await tester.tap(find.text('UNREAD'));
      await tester.pumpAndSettle();

      expect(find.text('Task Assigned: Flutter Auth'), findsOneWidget);
      expect(find.text('Overdue task: Mobile API Client'), findsOneWidget);
      expect(find.text('Project Milestone Achieved'), findsOneWidget);
      expect(find.text('Daily Report Missing'), findsNothing); // isRead: true is filtered out!

      // Tap TASKS filter
      await tester.tap(find.text('TASKS'));
      await tester.pumpAndSettle();

      expect(find.text('Task Assigned: Flutter Auth'), findsOneWidget);
      expect(find.text('Overdue task: Mobile API Client'), findsOneWidget);
      expect(find.text('Project Milestone Achieved'), findsNothing);

      // Tap REPORTS filter
      await tester.tap(find.text('REPORTS'));
      await tester.pumpAndSettle();

      expect(find.text('Daily Report Missing'), findsOneWidget);
      expect(find.text('Task Assigned: Flutter Auth'), findsNothing);
    });

    testWidgets('Mark all read optimistically updates state and triggers API', (tester) async {
      final mockService = MockNotificationService(
        mockItems: List.from(sampleNotifications),
        unreadCount: 3,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          NotificationsScreen(
            user: testUser,
            notificationService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark all read'), findsOneWidget);
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(mockService.markAllReadCalls, 1);
      // All NEW/URGENT badges cleared
      expect(find.text('NEW'), findsNothing);
      expect(find.text('URGENT'), findsNothing);
      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('Tapping unread card marks it read and deep-links to TaskDetailScreen', (tester) async {
      final mockService = MockNotificationService(
        mockItems: List.from(sampleNotifications),
        unreadCount: 3,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          NotificationsScreen(
            user: testUser,
            notificationService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Task Assigned card
      await tester.tap(find.text('Task Assigned: Flutter Auth'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies markRead was called for ID 101
      expect(mockService.markReadCalls.contains(101), isTrue);

      // Verifies TaskDetailScreen was pushed onto navigation stack
      expect(find.byType(TaskDetailScreen), findsOneWidget);

      // Drain any network timeout timer started by TaskDetailScreen
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('Tapping Mark read inline text button marks read without navigating', (tester) async {
      final mockService = MockNotificationService(
        mockItems: List.from(sampleNotifications),
        unreadCount: 3,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          NotificationsScreen(
            user: testUser,
            notificationService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap inline "Mark read" button on the first unread card
      final markReadButtons = find.text('Mark read');
      expect(markReadButtons, findsWidgets);

      await tester.tap(markReadButtons.first);
      await tester.pumpAndSettle();

      expect(mockService.markReadCalls.contains(101), isTrue);
      // Should NOT have navigated away
      expect(find.byType(TaskDetailScreen), findsNothing);
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('AppSideDrawer displays dynamic unread notification badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            drawer: AppSideDrawer(
              user: testUser,
              currentTabIndex: 0,
              unreadNotifications: 7,
              onTabSelected: (_) {},
              onLogout: () {},
              onComplianceTap: () {},
              onFilterTap: () {},
              onTeamListTap: () {},
              onOverdueTap: () {},
              onNotificationsTap: () {},
              onApprovalsTap: () {},
            ),
            body: const Text('Dashboard Body'),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verify exact dynamic badge '7' is displayed
      expect(find.text('7'), findsOneWidget);
      // Verify hardcoded '9+' is not present
      expect(find.text('9+'), findsNothing);
    });
  });
}
