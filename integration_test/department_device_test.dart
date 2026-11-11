import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:projecta_app/core/api_client.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/team/departments_screen.dart';
import 'package:projecta_app/services/auth_service.dart';
import 'package:projecta_app/services/directory_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const String deviceApiUrl = 'http://localhost:8080/projecta/api/v1';

  setUpAll(() async {
    ApiClient().setBaseUrl(deviceApiUrl);
  });

  group('Module 7: Live Physical Device Verification (CPH2139)', () {
    testWidgets('Live End-to-End Department Management on Android Device',
        (tester) async {
      // 1. Direct login via live API
      final authService = AuthService();
      UserModel user;
      try {
        user = await authService.login(
          'aamannbhatia@gmail.com',
          'Password@123',
          deviceName: 'CPH2139 Automated Audit',
        );
      } catch (e) {
        fail('Device authentication failed against local backend: $e');
      }

      expect(user.isAdmin, true);
      expect(user.isSuperAdmin, true);

      // 2. Launch DepartmentsScreen directly with live DirectoryService
      final directoryService = DirectoryService();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: DepartmentsScreen(directoryService: directoryService),
        ),
      );

      // Wait for network response and animations to settle
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 3. Verify Screen Header & 4 KPI Metrics from live database
      expect(find.text('Department Management'), findsOneWidget);
      expect(find.text('Add Dept'), findsOneWidget);

      // Verify the 4 KPI cards exist
      expect(find.text('Total Departments'), findsOneWidget);
      expect(find.text('Active Departments'), findsOneWidget);
      expect(find.text('Staff Assigned'), findsOneWidget);
      expect(find.text('Active Projects'), findsOneWidget);

      // Verify existing database departments rendered
      expect(find.text('Development'), findsOneWidget);
      expect(find.text('Head: '), findsWidgets);
      expect(find.text('Amul Bhatia'), findsOneWidget);
      expect(find.text('ACTIVE'), findsWidgets);

      // 4. Test Live Search Filtering
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Development');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.text('Development'), findsWidgets);
      expect(find.text('Quality Assurance software QA and Testing'),
          findsNothing);

      // Clear search
      final clearButton = find.byIcon(Icons.clear);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      } else {
        await tester.enterText(searchField, '');
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      expect(find.text('Development'), findsOneWidget);

      // 5. Test Status Filter Pills
      await tester.tap(find.text('INACTIVE'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // If no inactive departments, verify empty search state
      expect(find.text('Development'), findsNothing);

      // Switch back to ALL
      await tester.tap(find.text('ALL'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('Development'), findsOneWidget);

      // 6. Test Add Department Dialog & Validation
      await tester.tap(find.text('Add Dept'));
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      expect(find.text('Add New Department'), findsOneWidget);
      expect(find.text('Department Name *'), findsOneWidget);
      expect(find.text('Create Department'), findsOneWidget);

      // Test empty name validation
      await tester.ensureVisible(find.text('Create Department'));
      await tester.tap(find.text('Create Department'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.text('Department name is required.'), findsOneWidget);

      // Test >120 char validation
      final dialogNameField = find.widgetWithText(
          TextField, 'e.g. Mobile Engineering, QA & Testing');
      final longName = 'D' * 125;
      await tester.enterText(dialogNameField, longName);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      await tester.ensureVisible(find.text('Create Department'));
      await tester.tap(find.text('Create Department'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.text('Department name must be under 120 characters.'),
          findsOneWidget);

      // Enter valid unique test department
      final testDeptName =
          'Test DevOps-${DateTime.now().millisecondsSinceEpoch % 10000}';
      await tester.enterText(dialogNameField, testDeptName);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      final descField = find.widgetWithText(
          TextField, 'Scope, key functions, and responsibilities...');
      await tester.enterText(
          descField, 'Automated CI/CD pipelines and infrastructure.');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Submit new department
      await tester.ensureVisible(find.text('Create Department'));
      await tester.tap(find.text('Create Department'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify newly created department appears on screen
      final newDeptFinder = find.text(testDeptName);
      if (newDeptFinder.evaluate().isEmpty) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      expect(newDeptFinder, findsOneWidget);

      // 7. Test Edit Department
      final editButtons = find.byTooltip('Edit Department');
      expect(editButtons, findsWidgets);
      await tester.ensureVisible(editButtons.last);
      await tester.tap(editButtons.last);
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      expect(find.text('Edit Department'), findsOneWidget);
      expect(find.text('Update Department'), findsOneWidget);

      // Update description
      final editDescField = find.widgetWithText(
          TextField, 'Scope, key functions, and responsibilities...');
      await tester.enterText(
          editDescField, 'Updated CI/CD & Kubernetes operations.');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      await tester.ensureVisible(find.text('Update Department'));
      await tester.tap(find.text('Update Department'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 8. Test Deactivate Safety on in-use department (Development)
      final deleteButtons = find.byTooltip('Deactivate Department');
      if (deleteButtons.evaluate().isNotEmpty) {
        await tester.tap(deleteButtons.first);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.text('Deactivate Department'), findsOneWidget);
        expect(
          find.textContaining(
              'cannot be permanently deleted. Mark it as inactive instead?'),
          findsOneWidget,
        );

        // Cancel dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      // 9. Test Permanent Delete on the empty test department
      final allDeleteButtons = find.byTooltip('Delete Department');
      if (allDeleteButtons.evaluate().isNotEmpty) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        await tester.tap(allDeleteButtons.last);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.text('Delete Department'), findsOneWidget);
        expect(
          find.textContaining('permanently delete department'),
          findsOneWidget,
        );

        await tester.tap(find.text('Delete Permanently'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Confirm deleted test department is removed
        expect(find.text(testDeptName), findsNothing);
      }

      // 10. Test Drill-Down navigation to Staff & Projects
      // Drag back up to top to test Development card
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final staffButton = find.textContaining('8 Staff');
      expect(staffButton, findsOneWidget);
      await tester.tap(staffButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should have navigated to TeamListScreen
      expect(find.text('Team Management'), findsOneWidget);

      // Navigate back
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      expect(find.text('Department Management'), findsOneWidget);

      // Verify no exceptions thrown during the entire flow
      expect(tester.takeException(), isNull);
    });
  });
}
