import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/dashboard/staff_dashboard_view.dart';

void main() {
  final staffUser = UserModel(
    id: 42,
    username: 'piyush.bhatt',
    name: 'Piyush Bhatt',
    email: 'piyush@projeqta.io',
    role: 'staff',
    adminScope: 'none',
    mustChangePassword: false,
    designation: 'Software Engineer',
    departmentId: 2,
    departmentName: 'Engineering',
  );

  final comprehensiveStaffData = {
    'role': 'staff',
    'date': '2026-11-12',
    'compliance': {
      'status_key': 'not_due',
      'label': 'Not Due',
      'deadline_time': '20:00',
      'is_late': false,
      'reports_count': 0,
    },
    'kpis': {
      'active_projects': 3,
      'open_tasks': 3,
      'due_today': 0,
      'overdue': 2,
      'pending_review': 1,
      'completed': 0,
    },
    'what_to_work_on_next': [
      {
        'id': 101,
        'title': 'test_task title',
        'project_name': 'Projeqta',
        'progress': 30,
        'priority': 'critical',
        'status': 'in_progress',
        'reason': 'Overdue by 1 day(s)',
        'is_overdue': true,
        'deadline': '2026-11-11',
      },
      {
        'id': 102,
        'title': 'Api Parameter Audit',
        'project_name': 'Projeqta',
        'progress': 0,
        'priority': 'medium',
        'status': 'not_started',
        'reason': 'Due in 4 day(s)',
        'is_overdue': false,
        'deadline': '2026-11-16',
      },
    ],
    'my_tasks': [
      {
        'id': 201,
        'title': 'Revision 1 requirements',
        'project_name': 'Ambiora Hotel ERP',
        'deadline': '2026-10-30',
        'deadline_formatted': '30 Oct 2026',
        'priority': 'high',
        'status': 'pending_review',
        'progress': 90,
        'responsibility': 'contributor',
        'open_deps': 0,
        'is_overdue': true,
        'days_late': 13,
      },
      {
        'id': 101,
        'title': 'test_task title',
        'project_name': 'Projeqta',
        'deadline': '2026-11-11',
        'deadline_formatted': '11 Nov 2026',
        'priority': 'critical',
        'status': 'in_progress',
        'progress': 30,
        'responsibility': 'contributor',
        'open_deps': 0,
        'is_overdue': true,
        'days_late': 1,
      },
      {
        'id': 102,
        'title': 'Api Parameter Audit',
        'project_name': 'Projeqta',
        'deadline': '2026-11-16',
        'deadline_formatted': '16 Nov 2026',
        'priority': 'medium',
        'status': 'not_started',
        'progress': 0,
        'responsibility': 'contributor',
        'open_deps': 0,
        'is_overdue': false,
        'days_late': 0,
      },
    ],
    'deadlines': {
      'overdue': [
        {
          'id': 201,
          'title': 'Revision 1 requirements',
          'project_name': 'Ambiora Hotel ERP',
          'deadline': '2026-10-30',
          'days_late': 13,
          'priority': 'high',
          'status': 'pending_review',
        },
        {
          'id': 101,
          'title': 'test_task title',
          'project_name': 'Projeqta',
          'deadline': '2026-11-11',
          'days_late': 1,
          'priority': 'critical',
          'status': 'in_progress',
        },
      ],
      'due_today': <Map<String, dynamic>>[],
      'upcoming': [
        {
          'id': 102,
          'title': 'Api Parameter Audit',
          'project_name': 'Projeqta',
          'deadline': '2026-11-16',
          'deadline_formatted': '16 Nov 2026',
          'priority': 'medium',
          'status': 'not_started',
        },
      ],
    },
    'today_reports': [
      {
        'id': 501,
        'project_name': 'Projeqta',
        'task_title': 'test_task title',
        'work_summary':
            'Investigated API endpoints and updated backend routes.',
        'minutes_spent': 120,
        'time_spent_formatted': '2h 00m',
        'status': 'submitted',
        'is_late': false,
      },
    ],
    'recent_feedback': [
      {
        'reviewer_name': 'Admin Supervisor',
        'report_date': '2026-11-11',
        'review_comment':
            'Good progress on API endpoints, ensure tests cover edge cases.',
        'status': 'approved',
      },
    ],
    'my_projects': [
      {'id': 1, 'name': 'Projeqta', 'completion_percent': 65},
      {'id': 2, 'name': 'Ambiora Hotel ERP', 'completion_percent': 40},
    ],
  };

  testWidgets(
    'StaffDashboardView renders complete web screenshot parity elements',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Scaffold(
            body: StaffDashboardView(
              user: staffUser,
              data: comprehensiveStaffData,
              onRefresh: () {},
            ),
          ),
        ),
      );

      // 1. Welcome Header
      expect(find.text('Welcome back, Piyush 👋'), findsOneWidget);
      expect(find.text('Daily Report'), findsOneWidget);

      // 2. 6-Card KPI Grid
      expect(find.text('Active Projects'), findsOneWidget);
      expect(find.text('My Open Tasks'), findsOneWidget);
      expect(find.text('Due Today'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Awaiting Review'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // 3. Daily Report Reminder Callout
      expect(
        find.textContaining("Today's report is due by 20:00"),
        findsOneWidget,
      );
      expect(find.textContaining('Submit it now →'), findsOneWidget);

      // 4. "What should I work on next?" Section
      expect(find.text('What should I work on next?'), findsOneWidget);
      expect(find.text('Next Up (#1 Hero)'), findsOneWidget);
      expect(find.text('Update Status'), findsOneWidget);
      expect(find.text('test_task title'), findsWidgets);
      expect(find.text('Api Parameter Audit'), findsWidgets);

      // 5. "My tasks" Section
      expect(find.text('My tasks'), findsOneWidget);
      expect(find.text('View all →'), findsOneWidget);
      expect(find.text('Revision 1 requirements'), findsWidgets);
      expect(find.text('shared'), findsWidgets);

      // 6. "Deadlines" Breakdown
      expect(find.text('Deadlines'), findsOneWidget);
      expect(find.text('Overdue (2)'), findsOneWidget);
      expect(find.text('13d late'), findsOneWidget);
      expect(find.text('1d late'), findsOneWidget);
      expect(find.text('Due today (0)'), findsOneWidget);
      expect(find.text('Upcoming (next 7 days)'), findsOneWidget);

      // 7. "Today's submitted reports" Section
      expect(find.text("Today's submitted reports"), findsOneWidget);
      expect(find.text('History →'), findsOneWidget);
      expect(find.text('2h 00m'), findsOneWidget);
      expect(
        find.text('Investigated API endpoints and updated backend routes.'),
        findsOneWidget,
      );

      // 8. "Recent feedback" Section
      expect(find.text('Recent feedback'), findsOneWidget);
      expect(find.text('Admin Supervisor'), findsOneWidget);
      expect(
        find.text(
          'Good progress on API endpoints, ensure tests cover edge cases.',
        ),
        findsOneWidget,
      );

      // 9. "My projects" Section
      await tester.scrollUntilVisible(find.text('My projects'), 300);
      expect(find.text('My projects'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    },
  );

  testWidgets(
    'StaffDashboardView renders helpful empty states when reports or tasks are empty',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final emptyStaffData = {
        'role': 'staff',
        'date': '2026-11-12',
        'compliance': {
          'status_key': 'not_due',
          'label': 'Not Due',
          'deadline_time': '20:00',
          'is_late': false,
          'reports_count': 0,
        },
        'kpis': {
          'active_projects': 0,
          'open_tasks': 0,
          'due_today': 0,
          'overdue': 0,
          'pending_review': 0,
          'completed': 0,
        },
        'what_to_work_on_next': <Map<String, dynamic>>[],
        'my_tasks': <Map<String, dynamic>>[],
        'deadlines': {
          'overdue': <Map<String, dynamic>>[],
          'due_today': <Map<String, dynamic>>[],
          'upcoming': <Map<String, dynamic>>[],
        },
        'today_reports': <Map<String, dynamic>>[],
        'recent_feedback': <Map<String, dynamic>>[],
        'my_projects': <Map<String, dynamic>>[],
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Scaffold(
            body: StaffDashboardView(
              user: staffUser,
              data: emptyStaffData,
              onRefresh: () {},
            ),
          ),
        ),
      );

      // Empty states should render
      expect(find.text('Nothing Urgent'), findsOneWidget);
      expect(find.text('No open tasks assigned to you.'), findsOneWidget);
      expect(
        find.text('No report entries logged for today yet.'),
        findsOneWidget,
      );
      expect(find.text('Submit Now'), findsOneWidget);
    },
  );
}
