import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/dashboard/admin_dashboard_view.dart';
import 'package:projecta_app/screens/dashboard/dashboard_screen.dart';
import 'package:projecta_app/screens/dashboard/staff_dashboard_view.dart';
import 'package:projecta_app/screens/dashboard/widgets/activity_timeline_tile.dart';
import 'package:projecta_app/screens/dashboard/widgets/compliance_card.dart';
import 'package:projecta_app/screens/dashboard/widgets/dashboard_filter_sheet.dart';
import 'package:projecta_app/screens/dashboard/widgets/employee_workload_card.dart';
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
    'compliance': {
      'status_key': 'pending',
      'label': 'Pending',
      'deadline_time': '07:00 PM',
      'is_late': false,
    },
    'kpis': {
      'active_projects': 3,
      'open_tasks': 8,
      'pending_review': 3,
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
      },
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
        },
      ],
      'blocked_tasks': [
        {
          'id': 202,
          'title': 'Deploy to Cloud Server',
          'project_name': 'DevOps Infra',
        },
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
      },
    ],
  };

  group('Phase 4: KPI Card & Compliance Card Widgets', () {
    testWidgets('KpiCard renders label, value and urgent styling', (
      tester,
    ) async {
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

      expect(find.text('Overdue Tasks'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Requires attention'), findsOneWidget);
    });

    testWidgets('ComplianceCard renders pending status and submit button', (
      tester,
    ) async {
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

      expect(find.text("Today's Work Report"), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Due 07:00 PM'), findsOneWidget);
      expect(find.text('Submit Daily Report'), findsOneWidget);

      await tester.tap(find.text('Submit Daily Report'));
      expect(submitted, isTrue);
    });
  });

  group('Phase 4: Staff Dashboard View', () {
    testWidgets('Renders compliance banner, metrics, and priority next tasks', (
      tester,
    ) async {
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

      expect(find.text('My Metrics'), findsOneWidget);
      expect(find.text('Active Projects'), findsOneWidget);
      expect(find.text('My Open Tasks'), findsOneWidget);
      expect(find.text('What should I work on next?'), findsOneWidget);
      expect(find.text('Implement API Authentication Bridge'), findsOneWidget);
      expect(find.text('Design Neo-Brutalist Layout'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Recent feedback'), findsOneWidget);
      expect(find.text('Great progress on the sprint tasks!'), findsOneWidget);
    });
  });

  group('Phase 4: Admin Dashboard View', () {
    testWidgets(
      'Renders 10 Core Metrics, Alert Center, and Projects Snapshot',
      (tester) async {
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

        expect(find.text('Admin Executive Control'), findsOneWidget);
        expect(find.text('Reports Awaiting Review'), findsOneWidget);
        expect(find.text('10 Core Metrics'), findsOneWidget);
        expect(find.text('Active Projects'), findsOneWidget);
        expect(find.text('Completed Projects'), findsOneWidget);
        expect(find.text('Completed Tasks'), findsOneWidget);
        expect(find.text('Pending Tasks'), findsOneWidget);
        expect(find.text('Risk & Alert Center'), findsOneWidget);
        expect(find.text('Fix Session Timeout Logic'), findsOneWidget);
        expect(find.text('Deploy to Cloud Server'), findsOneWidget);
        expect(find.text('Active Projects Overview'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Projecta Enterprise'), 200);
        expect(find.text('Projecta Enterprise'), findsOneWidget);
        expect(find.text('65%'), findsOneWidget);
      },
    );
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

      // Verify app bar displays user designation and profile dropdown with down arrow
      expect(find.text('Aman Admin'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Verify tapping profile dropdown displays options (My profile, Notifications, Log out)
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();
      expect(find.text('My profile'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });

  group('Phase 4: Web Dashboard Integration Widgets', () {
    testWidgets(
      'EmployeeWorkloadCard renders name, department, metrics and compliance',
      (tester) async {
        final mockEmployee = {
          'id': 10,
          'full_name': 'Rahul Dhiman',
          'department_name': 'Development',
          'active_projects': 4,
          'assigned': 5,
          'completed': 0,
          'pending': 5,
          'overdue': 2,
          'last_report_relative': '1 days ago',
          'today_status': 'not_due',
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: Scaffold(body: EmployeeWorkloadCard(employee: mockEmployee)),
          ),
        );

        expect(find.text('Rahul Dhiman'), findsOneWidget);
        expect(find.text('Development'), findsOneWidget);
        expect(find.text('Projects'), findsOneWidget);
        expect(find.text('Assigned'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('Overdue'), findsOneWidget);
        expect(find.text('Last report: 1 days ago'), findsOneWidget);
        expect(find.text('Not Due'), findsOneWidget);
        expect(find.text('2 overdue'), findsOneWidget);
      },
    );

    testWidgets(
      'ActivityTimelineTile renders description, time_ago, and tap routing',
      (tester) async {
        final mockActivity = {
          'id': 50,
          'description': 'Harshit Kumar submitted daily report for Litoraai',
          'time_ago': '21 hr ago',
          'task_id': 101,
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: Scaffold(body: ActivityTimelineTile(activity: mockActivity)),
          ),
        );

        expect(
          find.text('Harshit Kumar submitted daily report for Litoraai'),
          findsOneWidget,
        );
        expect(find.text('21 hr ago'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      },
    );

    testWidgets(
      'DashboardFilterSheet renders filter controls and triggers onApply',
      (tester) async {
        final filterOptions = {
          'projects': [
            {'id': 1, 'name': 'Khalsa College ERP'},
            {'id': 2, 'name': 'Staffify'},
          ],
          'departments': [
            {'id': 1, 'name': 'Development'},
            {'id': 2, 'name': 'Marketing'},
          ],
          'employees': [
            {'id': 10, 'full_name': 'Rahul Dhiman'},
            {'id': 11, 'full_name': 'Harshit Kumar'},
          ],
        };

        int? appliedProj;
        int? appliedDept;
        int? appliedUser;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: Scaffold(
              body: DashboardFilterSheet(
                filterOptions: filterOptions,
                selectedProjectId: 1,
                onApply: (p, d, u) {
                  appliedProj = p;
                  appliedDept = d;
                  appliedUser = u;
                },
              ),
            ),
          ),
        );

        expect(find.text('Filter Dashboard'), findsOneWidget);
        expect(find.text('Project'), findsOneWidget);
        expect(find.text('Department'), findsOneWidget);
        expect(find.text('Employee'), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);
        expect(find.text('Apply Filter'), findsOneWidget);

        await tester.tap(find.text('Apply Filter'));
        await tester.pump();

        expect(appliedProj, 1);
        expect(appliedDept, isNull);
        expect(appliedUser, isNull);
      },
    );

    testWidgets(
      'AdminDashboardView renders on 360px screen with sub-tab switching and 0 overflows',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fullMockData = {
          ...mockAdminData,
          'employee_overview': [
            {
              'id': 10,
              'full_name': 'Rahul Dhiman',
              'department_name': 'Development',
              'project_count': 4,
              'assigned_tasks': 5,
              'done_tasks': 0,
              'pending_tasks': 5,
              'overdue_tasks': 2,
              'compliance_today': false,
              'last_report': '1 days ago',
            },
          ],
          'recent_activity': [
            {
              'id': 1,
              'description': 'Aman Bhatia assigned task "create prototype"',
              'time_ago': '23 hr ago',
              'type': 'task',
            },
          ],
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: Scaffold(
              body: AdminDashboardView(
                user: adminUser,
                data: fullMockData,
                onRefresh: () {},
              ),
            ),
          ),
        );

        // Sub-tab 0: Overview
        expect(find.text('Overview'), findsOneWidget);
        expect(find.text('10 Core Metrics'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Switch to Sub-tab 1: Projects
        await tester.tap(find.widgetWithText(InkWell, 'Projects').last);
        await tester.pumpAndSettle();
        expect(find.text('Search projects by name or code...'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Switch to Sub-tab 2: Team
        await tester.tap(find.widgetWithText(InkWell, 'Team').last);
        await tester.pumpAndSettle();
        expect(find.text('Rahul Dhiman'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Switch to Sub-tab 3: Risks & Logs
        await tester.tap(find.widgetWithText(InkWell, 'Risks & Logs').last);
        await tester.pumpAndSettle();
        expect(find.text('Recent Activity'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
