import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/dashboard/admin_dashboard_view.dart';
import 'package:projecta_app/screens/dashboard/dashboard_screen.dart';
import 'package:projecta_app/screens/dashboard/staff_dashboard_view.dart';
import 'package:projecta_app/screens/dashboard/widgets/compliance_card.dart';
import 'package:projecta_app/screens/dashboard/widgets/kpi_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final mockStaffData = {
    'role': 'staff',
    'date': '2026-11-03',
    'compliance_badge': {
      'status_key': 'pending',
      'label': 'Pending',
      'deadline_time': '07:00 PM',
      'is_late': false,
    },
    'kpis': {
      'active_projects': 3,
      'open_tasks': 8,
      'in_progress_tasks': 4,
      'overdue': 2,
      'due_today': 1,
      'completed': 12,
    },
    'what_to_work_on_next': [
      {
        'id': 101,
        'title': 'Implement API Authentication Bridge',
        'project_name': 'Projecta Mobile',
        'progress': 75,
        'priority': 'high',
        'reason': 'Overdue by 1 day',
        'is_overdue': true,
        'deadline': '2026-11-02',
      },
      {
        'id': 102,
        'title': 'Design Neo-Brutalist Layout',
        'project_name': 'Projecta UI',
        'progress': 40,
        'priority': 'medium',
        'reason': 'Due Today',
        'is_overdue': false,
        'deadline': '2026-11-03',
      },
    ],
    'recent_feedback': [
      {
        'reviewer_name': 'Aman Bhatia',
        'report_date': '2026-11-02',
        'review_comment': 'Great progress on the sprint tasks!',
      }
    ],
  };

  final mockAdminData = {
    'role': 'admin',
    'date': '2026-11-03',
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
        }
      ],
      'blocked_tasks': [
        {
          'id': 202,
          'title': 'Deploy to Cloud Server',
          'project_name': 'DevOps Infra',
        }
      ],
    },
    'active_projects': [
      {
        'id': 1,
        'name': 'Projecta Enterprise',
        'manager_name': 'Amul Bhatia',
        'deadline': '2026-12-01',
        'completion_percent': 65,
        'done_tasks': 24,
        'pending_tasks': 12,
        'overdue_tasks': 2,
      }
    ],
  };

  group('Phase 4: KPI Card & Compliance Card Widgets', () {
    testWidgets('KpiCard renders label, value and urgent styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: const Scaffold(
            body: KpiCard(
              label: 'Overdue Tasks',
              value: '5',
              isUrgent: true,
              subtitle: 'Requires attention',
            ),
          ),
        ),
      );

      expect(find.text('OVERDUE TASKS'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Requires attention'), findsOneWidget);
    });

    testWidgets('ComplianceCard renders pending status and submit button', (tester) async {
      bool submitted = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Scaffold(
            body: ComplianceCard(
              badgeData: const {
                'status_key': 'pending',
                'label': 'Pending',
                'deadline_time': '07:00 PM',
              },
              onSubmitReport: () => submitted = true,
            ),
          ),
        ),
      );

      expect(find.text("TODAY'S WORK REPORT"), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('DUE 07:00 PM'), findsOneWidget);
      expect(find.text('SUBMIT DAILY REPORT'), findsOneWidget);

      await tester.tap(find.text('SUBMIT DAILY REPORT'));
      expect(submitted, isTrue);
    });
  });

  group('Phase 4: Staff Dashboard View', () {
    testWidgets('Renders compliance banner, metrics, and priority next tasks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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

      expect(find.text('MY METRICS'), findsOneWidget);
      expect(find.text('ACTIVE PROJECTS'), findsOneWidget);
      expect(find.text('OPEN TASKS'), findsOneWidget);
      expect(find.text('WHAT SHOULD I WORK ON NEXT?'), findsOneWidget);
      expect(find.text('Implement API Authentication Bridge'), findsOneWidget);
      expect(find.text('Design Neo-Brutalist Layout'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('SUPERVISOR FEEDBACK'), findsOneWidget);
      expect(find.text('Great progress on the sprint tasks!'), findsOneWidget);
    });
  });

  group('Phase 4: Admin Dashboard View', () {
    testWidgets('Renders 10 Core Metrics, Alert Center, and Projects Snapshot', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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

      expect(find.text('ADMIN EXECUTIVE CONTROL'), findsOneWidget);
      expect(find.text('REPORTS AWAITING REVIEW'), findsOneWidget);
      expect(find.text('10 CORE METRICS'), findsOneWidget);
      expect(find.text('ACTIVE PROJECTS'), findsOneWidget);
      expect(find.text('COMPLETED PROJ'), findsOneWidget);
      expect(find.text('COMPLETED TASKS'), findsOneWidget);
      expect(find.text('PENDING TASKS'), findsOneWidget);
      expect(find.text('PROJECT RISK & ALERT CENTER'), findsOneWidget);
      expect(find.text('Fix Session Timeout Logic'), findsOneWidget);
      expect(find.text('Deploy to Cloud Server'), findsOneWidget);
      expect(find.text('ACTIVE PROJECTS OVERVIEW'), findsOneWidget);
      expect(find.text('Projecta Enterprise'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
    });
  });

  group('Phase 4: DashboardScreen Role Routing', () {
    testWidgets('Directs admin user to AdminDashboardView', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: const DashboardScreen(user: adminUser),
        ),
      );

      // Verify app bar displays user designation and logout button
      expect(find.text('AMAN ADMIN'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
