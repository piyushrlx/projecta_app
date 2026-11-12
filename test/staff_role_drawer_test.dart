import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/core/widgets/app_side_drawer.dart';
import 'package:projecta_app/models/user_model.dart';

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
  );

  final adminUser = UserModel(
    id: 1,
    username: 'aman.bhatia',
    name: 'Aman Bhatia',
    email: 'aman@projeqta.io',
    role: 'admin',
    adminScope: 'all',
    mustChangePassword: false,
    designation: 'Project Director',
  );

  group('Staff vs Admin Role-Gated Drawer Tests', () {
    testWidgets(
      'Staff user sees scoped items and does NOT see Admin / System modules',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: Scaffold(
              body: AppSideDrawer(
                user: staffUser,
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

        // Subtitle shows Staff Executive
        expect(find.text('Staff Executive'), findsOneWidget);

        // 1. Workspace Section
        expect(find.text('Dashboard / Pulse'), findsOneWidget);
        expect(find.text('Tasks'), findsOneWidget);
        expect(find.text('Projects'), findsOneWidget);
        expect(find.text('Team Management'), findsNothing); // Hidden for staff

        // 2. Reporting Section
        expect(find.text('REPORTING'), findsOneWidget);
        expect(find.text('Submit Daily Report'), findsOneWidget);
        expect(find.text('Daily Reports'), findsOneWidget);
        expect(find.text('Reports & Analytics'), findsOneWidget);
        expect(find.text('Calendar'), findsOneWidget);
        expect(find.text('Approvals'), findsNothing); // Hidden for staff
        expect(find.text('Attendance & Activities'), findsNothing); // Hidden for staff

        // 3. Monitoring Section
        expect(find.text('Overdue Backlog'), findsOneWidget);
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('Risks & Alerts'), findsNothing); // Hidden for staff
        expect(find.text('Reporting Compliance'), findsNothing); // Hidden for staff

        // 4. System Section
        expect(find.text('SYSTEM'), findsNothing); // Hidden for staff
        expect(find.text('Settings'), findsNothing); // Hidden for staff
        expect(find.text('Audit Log'), findsNothing); // Hidden for staff
        expect(find.text('Contact Messages'), findsNothing); // Hidden for staff
      },
    );

    testWidgets(
      'Admin user sees full management, operations, and system modules',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: Scaffold(
              body: AppSideDrawer(
                user: adminUser,
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

        // Subtitle shows Admin Executive
        expect(find.text('Admin Executive'), findsOneWidget);

        // 1. Workspace Section with Team Management
        expect(find.text('Dashboard / Pulse'), findsOneWidget);
        expect(find.text('Tasks'), findsOneWidget);
        expect(find.text('Projects'), findsOneWidget);
        expect(find.text('Team Management'), findsOneWidget);

        // 2. Operations Section
        expect(find.text('OPERATIONS'), findsOneWidget);
        expect(find.text('Reports'), findsOneWidget);
        expect(find.text('Reports & Analytics'), findsOneWidget);
        expect(find.text('Approvals'), findsOneWidget);
        expect(find.text('Attendance & Activities'), findsOneWidget);
        expect(find.text('Calendar'), findsOneWidget);
        expect(find.text('Submit Daily Report'), findsNothing); // Staff only

        // 3. Monitoring Section
        expect(find.text('Risks & Alerts'), findsOneWidget);
        expect(find.text('Reporting Compliance'), findsOneWidget);

        // 4. System Section
        expect(find.text('SYSTEM'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Audit Log'), findsOneWidget);
      },
    );
  });
}

