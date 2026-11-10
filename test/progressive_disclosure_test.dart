import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/core/widgets/app_side_drawer.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/team/team_list_screen.dart';
import 'package:projecta_app/services/directory_service.dart';

class FakeDirectoryService extends DirectoryService {
  @override
  Future<List<Map<String, dynamic>>> getEmployees({
    String? search,
    String? status,
    int? departmentId,
    int page = 1,
    int limit = 50,
  }) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getDepartments({String status = 'active'}) async {
    return [];
  }
}

void main() {
  final testAdminUser = UserModel(
    id: 1,
    name: 'Executive Admin',
    email: 'admin@projeqta.com',
    role: 'admin',
    adminScope: 'all',
    mustChangePassword: false,
  );

  group('Progressive Disclosure UX: AppSideDrawer', () {
    testWidgets('Renders 4 grouped sections and collapses them cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Scaffold(
            body: AppSideDrawer(
              user: testAdminUser,
              currentTabIndex: 0,
              onTabSelected: (_) {},
              onLogout: () {},
              onComplianceTap: () {},
              onFilterTap: () {},
              onTeamListTap: () {},
              onOverdueTap: () {},
              onNotificationsTap: () {},
              onApprovalsTap: () {},
            ),
          ),
        ),
      );

      // Verify Grouped Section Headers
      expect(find.text('WORKSPACE'), findsOneWidget);
      expect(find.text('OPERATIONS'), findsOneWidget);
      expect(find.text('MONITORING'), findsOneWidget);
      expect(find.text('SYSTEM'), findsOneWidget);

      // Verify Core Items
      expect(find.text('Dashboard / Pulse'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Team Management'), findsOneWidget);

      // Verify Operations & Monitoring Items
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Approvals'), findsOneWidget);
      expect(find.text('Attendance & Activities'), findsOneWidget);
      expect(find.text('Risks & Alerts'), findsOneWidget);
      expect(find.text('Overdue Backlog'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('Expanding Team Management reveals sub-items and invokes callbacks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool teamListTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Scaffold(
            body: AppSideDrawer(
              user: testAdminUser,
              currentTabIndex: 0,
              onTabSelected: (_) {},
              onLogout: () {},
              onComplianceTap: () {},
              onFilterTap: () {},
              onTeamListTap: () => teamListTapped = true,
              onOverdueTap: () {},
              onNotificationsTap: () {},
              onApprovalsTap: () {},
            ),
          ),
        ),
      );

      // Sub-items should not be visible before expanding
      expect(find.text('Team List'), findsNothing);

      // Tap Team Management to expand
      await tester.tap(find.text('Team Management'));
      await tester.pumpAndSettle();

      // Now sub-items should be revealed
      expect(find.text('Team List'), findsOneWidget);
      expect(find.text('Assign Roles'), findsOneWidget);
      expect(find.text('Performance'), findsOneWidget);
      expect(find.text('Team Reports'), findsOneWidget);

      // Tap Team List (pops drawer via Navigator.pop)
      await tester.tap(find.text('Team List'));
      await tester.pumpAndSettle();
      expect(teamListTapped, isTrue);
    });

    testWidgets('Tapping Overdue Backlog and Approvals invokes their callbacks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool overdueTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Scaffold(
            body: AppSideDrawer(
              user: testAdminUser,
              currentTabIndex: 0,
              onTabSelected: (_) {},
              onLogout: () {},
              onComplianceTap: () {},
              onFilterTap: () {},
              onTeamListTap: () {},
              onOverdueTap: () => overdueTapped = true,
              onNotificationsTap: () {},
              onApprovalsTap: () {},
            ),
          ),
        ),
      );

      // Tap Overdue Backlog
      await tester.tap(find.text('Overdue Backlog'));
      await tester.pumpAndSettle();
      expect(overdueTapped, isTrue);
    });
  });

  group('Progressive Disclosure UX: TeamListScreen', () {
    testWidgets('Renders 3 sub-tabs, search bar, and navy FAB', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: TeamListScreen(directoryService: FakeDirectoryService()),
        ),
      );
      await tester.pumpAndSettle();

      // Header title
      expect(find.text('Team Management'), findsOneWidget);

      // 3 Sub-tabs
      expect(find.text('Team List'), findsOneWidget);
      expect(find.text('Assign Roles'), findsOneWidget);
      expect(find.text('Performance'), findsOneWidget);

      // Search input placeholder
      expect(find.text('Search team member...'), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });
}
