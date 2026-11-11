import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/calendar/calendar_screen.dart';
import 'package:projecta_app/services/dashboard_service.dart';

class FakeDashboardService extends DashboardService {
  @override
  Future<Map<String, dynamic>> getCalendarData({
    DateTime? date,
    String view = 'month',
    int? projectId,
    int? userId,
  }) async {
    final now = date ?? DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return {
      'view': view,
      'date': todayStr,
      'heading': 'November 2026',
      'tasks': [
        {
          'id': 101,
          'task_code': 'TSK-101',
          'title': 'Implement Calendar View',
          'status': 'in_progress',
          'priority': 'high',
          'deadline': todayStr,
          'project_name': 'Mobile App Revamp',
        },
      ],
      'milestones': [
        {
          'id': 201,
          'title': 'Phase 2 Operational Release',
          'due_date': todayStr,
          'status': 'open',
          'project_name': 'Mobile App Revamp',
        },
      ],
      'holidays': [
        {
          'id': 301,
          'holiday_date': todayStr,
          'name': 'Company Innovation Day',
        },
      ],
      'upcoming': [
        {
          'id': 102,
          'task_code': 'TSK-102',
          'title': 'QA Release Checklist',
          'deadline': todayStr,
          'project_name': 'Mobile App Revamp',
        },
      ],
    };
  }
}

void main() {
  const testUser = UserModel(
    id: 1,
    name: 'Aman Bhatia',
    email: 'aamannbhatia@gmail.com',
    role: 'super_admin',
    adminScope: 'all',
    mustChangePassword: false,
  );

  Widget createTestWidget({FakeDashboardService? service}) {
    return MaterialApp(
      theme: AppTheme.themeData,
      home: CalendarScreen(
        currentUser: testUser,
        dashboardService: service ?? FakeDashboardService(),
      ),
    );
  }

  group('Phase 2: CalendarScreen Widget & Interaction Tests', () {
    testWidgets('Renders calendar heading, view switcher, and legend', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Calendar & Deadlines'), findsOneWidget);
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Due Soon'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Milestone'), findsOneWidget);
      expect(find.text('Holiday'), findsOneWidget);
    });

    testWidgets('Displays holiday, milestone, and task for selected date', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Holiday: Company Innovation Day'), findsOneWidget);
      expect(find.text('Phase 2 Operational Release'), findsOneWidget);
      expect(find.text('TSK-101'), findsOneWidget);
      expect(find.text('Implement Calendar View'), findsOneWidget);
    });

    testWidgets('Renders 14-day upcoming deadlines feed', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Deadlines (Next 14 Days)'), findsOneWidget);
      expect(find.text('TSK-102 · Mobile App Revamp'), findsOneWidget);
      expect(find.text('QA Release Checklist'), findsOneWidget);
    });
  });
}

