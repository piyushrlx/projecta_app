import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:projecta_app/core/api_client.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/dashboard/dashboard_screen.dart';
import 'package:projecta_app/screens/dashboard/staff_dashboard_view.dart';
import 'package:projecta_app/screens/projects/projects_list_screen.dart';
import 'package:projecta_app/screens/reports/reports_list_screen.dart';
import 'package:projecta_app/screens/tasks/tasks_screen.dart';
import 'package:projecta_app/services/auth_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const String deviceApiUrl = 'http://localhost:8080/projecta/api/v1';

  setUpAll(() async {
    ApiClient().setBaseUrl(deviceApiUrl);
  });

  group('Comprehensive Live Physical Device Audit (CPH2139)', () {
    testWidgets('Full Workflow Test: Admin, Staff, Navigation, and Modules',
        (tester) async {
      // -------------------------------------------------------------
      // 1. Live Authentication against local backend over ADB Tunnel
      // -------------------------------------------------------------
      final authService = AuthService();
      UserModel adminUser;
      try {
        adminUser = await authService.login(
          'aamannbhatia@gmail.com',
          'Password@123',
          deviceName: 'CPH2139 Full Workflow Audit',
        );
      } catch (e) {
        fail('Live authentication failed on device: $e');
      }

      expect(adminUser.isAdmin, true);
      expect(adminUser.isSuperAdmin, true);

      // -------------------------------------------------------------
      // 2. Launch Full DashboardScreen on Device Screen
      // -------------------------------------------------------------
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: DashboardScreen(user: adminUser),
        ),
      );

      // Allow initial dashboard queries, company settings & animations to settle
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // -------------------------------------------------------------
      // 3. Verify Admin Dashboard & Swiss Grid Neo-Brutalism Elements
      // -------------------------------------------------------------
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('PULSE'), findsOneWidget);
      expect(find.text('TASKS'), findsOneWidget);
      expect(find.text('PROJECTS'), findsOneWidget);
      expect(find.text('REPORTS'), findsOneWidget);
      expect(find.text('MENU'), findsOneWidget);

      // Verify Admin FAB exists
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // -------------------------------------------------------------
      // 4. Test Bottom Navigation Dock Tab 1: TASKS Module
      // -------------------------------------------------------------
      await tester.tap(find.text('TASKS'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify TasksScreen pushed on device
      expect(find.byType(TasksScreen), findsOneWidget);
      expect(find.text('Tasks & Kanban'), findsOneWidget);

      // Pop back to Dashboard
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(DashboardScreen), findsOneWidget);

      // -------------------------------------------------------------
      // 5. Test Bottom Navigation Dock Tab 2: PROJECTS Module
      // -------------------------------------------------------------
      await tester.tap(find.text('PROJECTS'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify ProjectsListScreen pushed on device
      expect(find.byType(ProjectsListScreen), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);

      // Pop back to Dashboard
      navigator.pop();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(DashboardScreen), findsOneWidget);

      // -------------------------------------------------------------
      // 6. Test Bottom Navigation Dock Tab 3: REPORTS Module
      // -------------------------------------------------------------
      await tester.tap(find.text('REPORTS'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify ReportsListScreen pushed on device
      expect(find.byType(ReportsListScreen), findsOneWidget);
      expect(find.text('Daily Reports Inbox'), findsOneWidget);

      // Pop back to Dashboard
      navigator.pop();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(DashboardScreen), findsOneWidget);

      // -------------------------------------------------------------
      // 7. Test App Side Drawer on Physical Screen
      // -------------------------------------------------------------
      final scaffoldState =
          tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify top-level drawer items
      expect(find.text('Dashboard / Pulse'), findsOneWidget);
      expect(find.text('Team Management'), findsOneWidget);

      // Expand Team Management to test Progressive Disclosure
      await tester.tap(find.text('Team Management'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Departments'), findsOneWidget);
      expect(find.text('Team List'), findsOneWidget);

      // Close drawer
      scaffoldState.closeDrawer();
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // -------------------------------------------------------------
      // 8. Test Staff Dashboard Flow Parity
      // -------------------------------------------------------------
      final staffUser = const UserModel(
        id: 3,
        username: 'harshit',
        email: 'harshit@rankfirst.tech',
        name: 'Harshit Kumar',
        role: 'staff',
        adminScope: 'assigned',
        mustChangePassword: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Scaffold(
            body: StaffDashboardView(
              user: staffUser,
              data: const {
                'role': 'staff',
                'compliance': {
                  'status': 'submitted',
                  'label': 'Submitted',
                  'is_late': false,
                  'today_date': '2026-11-14',
                },
                'what_to_work_on_next': [
                  {
                    'id': 1,
                    'task_code': 'T-0001',
                    'title': 'High Priority Staff Assignment',
                    'priority': 'critical',
                    'status': 'in_progress',
                    'progress': 45,
                    'deadline': '2026-11-20',
                    'project_name': 'Enterprise Portal',
                  }
                ],
                'kpis': {
                  'due_today': 1,
                  'overdue': 0,
                  'in_progress': 2,
                  'awaiting_review': 0,
                },
              },
              onRefresh: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify Staff Dashboard components rendered
      expect(find.text('What should I work on next?'), findsOneWidget);
      expect(find.text('My Metrics'), findsOneWidget);
    });
  });
}
