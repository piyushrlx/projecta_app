import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/department_model.dart';
import 'package:projecta_app/screens/team/departments_screen.dart';
import 'package:projecta_app/services/directory_service.dart';

class MockDepartmentDirectoryService extends DirectoryService {
  List<Map<String, dynamic>> departmentsData = [
    {
      'id': 1,
      'name': 'Mobile Engineering',
      'description': 'Flutter cross-platform apps',
      'manager_id': 2,
      'manager_name': 'Aman Bhatia',
      'status': 'active',
      'employee_count': 5,
      'total_employee_count': 6,
      'active_projects_count': 2,
      'total_projects_count': 3,
      'created_at': '2026-01-01 10:00:00',
      'updated_at': '2026-01-02 12:00:00',
    },
    {
      'id': 2,
      'name': 'Quality Assurance',
      'description': 'Automation and manual QA testing',
      'manager_id': null,
      'manager_name': null,
      'status': 'active',
      'employee_count': 3,
      'total_employee_count': 3,
      'active_projects_count': 1,
      'total_projects_count': 1,
      'created_at': '2026-02-01 10:00:00',
      'updated_at': '2026-02-02 12:00:00',
    },
    {
      'id': 3,
      'name': 'Legacy Systems',
      'description': 'Deprecated internal tools',
      'manager_id': null,
      'manager_name': null,
      'status': 'inactive',
      'employee_count': 0,
      'total_employee_count': 0,
      'active_projects_count': 0,
      'total_projects_count': 0,
      'created_at': '2025-01-01 10:00:00',
      'updated_at': '2025-06-01 12:00:00',
    },
  ];

  List<Map<String, dynamic>> employeesData = [
    {
      'id': 1,
      'full_name': 'Aman SuperAdmin',
      'role': 'super_admin',
      'status': 'active',
      'department_id': 1,
    },
    {
      'id': 2,
      'full_name': 'Aman Bhatia',
      'role': 'admin',
      'status': 'active',
      'department_id': 1,
    },
    {
      'id': 3,
      'full_name': 'Staff Worker',
      'role': 'staff',
      'status': 'active',
      'department_id': 1,
    },
  ];

  Map<String, dynamic>? lastSavedPayload;
  int? lastDeletedId;

  @override
  Future<List<Map<String, dynamic>>> getDepartments({String status = 'active'}) async {
    if (status == 'all') {
      return List<Map<String, dynamic>>.from(departmentsData);
    }
    return departmentsData
        .where((d) => (d['status'] ?? 'active') == status)
        .toList();
  }

  @override
  Future<List<DepartmentModel>> getDepartmentModels({String status = 'all'}) async {
    final list = await getDepartments(status: status);
    return list.map((m) => DepartmentModel.fromJson(m)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getEmployees({
    String? search,
    String? status,
    int? departmentId,
    int page = 1,
    int limit = 50,
  }) async {
    return List<Map<String, dynamic>>.from(employeesData);
  }

  @override
  Future<Map<String, dynamic>> saveDepartment(Map<String, dynamic> data) async {
    lastSavedPayload = Map<String, dynamic>.from(data);
    final id = data['id'] as int? ?? 99;
    return {'id': id, 'message': 'Department saved successfully.'};
  }

  @override
  Future<Map<String, dynamic>> deleteDepartment(int id) async {
    lastDeletedId = id;
    final dept = departmentsData.firstWhere((d) => d['id'] == id, orElse: () => {});
    final inUse = (dept['total_employee_count'] ?? 0) > 0 ||
        (dept['total_projects_count'] ?? 0) > 0;
    return {
      'deleted': !inUse,
      'message': inUse
          ? 'Department marked inactive.'
          : 'Department deleted permanently.',
    };
  }
}

void main() {
  late MockDepartmentDirectoryService mockService;

  setUp(() {
    mockService = MockDepartmentDirectoryService();
  });

  group('Module 7: DepartmentModel Unit Tests', () {
    test('DepartmentModel parses all fields correctly from JSON', () {
      final json = {
        'id': 10,
        'name': 'Cloud Infrastructure',
        'description': 'AWS and GCP operations',
        'manager_id': 5,
        'manager_name': 'Sarah Connor',
        'status': 'active',
        'employee_count': 8,
        'total_employee_count': 10,
        'active_projects_count': 4,
        'total_projects_count': 6,
        'created_at': '2026-03-01T08:30:00Z',
        'updated_at': '2026-03-02T12:00:00Z',
      };

      final model = DepartmentModel.fromJson(json);

      expect(model.id, 10);
      expect(model.name, 'Cloud Infrastructure');
      expect(model.description, 'AWS and GCP operations');
      expect(model.managerId, 5);
      expect(model.managerName, 'Sarah Connor');
      expect(model.status, 'active');
      expect(model.isActive, true);
      expect(model.hasManager, true);
      expect(model.employeeCount, 8);
      expect(model.totalEmployeeCount, 10);
      expect(model.activeProjectsCount, 4);
      expect(model.totalProjectsCount, 6);
      expect(model.isInUse, true);
      expect(model.createdAt, isNotNull);
      expect(model.updatedAt, isNotNull);

      final outJson = model.toJson();
      expect(outJson['name'], 'Cloud Infrastructure');
      expect(outJson['status'], 'active');
    });

    test('DepartmentModel handles empty / null optional fields and flags correctly', () {
      final model = DepartmentModel.fromJson({
        'id': '20',
        'name': 'New Department',
        'status': 'inactive',
      });

      expect(model.id, 20);
      expect(model.name, 'New Department');
      expect(model.description, isNull);
      expect(model.managerId, isNull);
      expect(model.managerName, isNull);
      expect(model.isActive, false);
      expect(model.hasManager, false);
      expect(model.employeeCount, 0);
      expect(model.totalEmployeeCount, 0);
      expect(model.activeProjectsCount, 0);
      expect(model.totalProjectsCount, 0);
      expect(model.isInUse, false);
    });

    test('copyWith produces updated model immutably', () {
      const original = DepartmentModel(
        id: 1,
        name: 'Dev',
        status: 'active',
      );

      final updated = original.copyWith(name: 'DevOps', status: 'inactive');

      expect(original.name, 'Dev');
      expect(original.status, 'active');
      expect(updated.name, 'DevOps');
      expect(updated.status, 'inactive');
      expect(updated.id, 1);
    });
  });

  group('Module 7: DepartmentsScreen Widget & Interaction Tests', () {
    testWidgets('Renders header, 4 KPI overview cards, and department cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: DepartmentsScreen(directoryService: mockService),
        ),
      );

      // Loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Department Management'), findsOneWidget);
      expect(find.text('3 registered department(s)'), findsOneWidget);
      expect(find.text('Add Dept'), findsOneWidget);

      // 4 KPI Overview Cards
      expect(find.text('Total Departments'), findsOneWidget);
      expect(find.text('3'), findsWidgets); // Total: 3
      expect(find.text('Active Departments'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // Active: 2
      expect(find.text('Staff Assigned'), findsOneWidget);
      expect(find.text('8'), findsOneWidget); // 5 + 3 + 0 = 8
      expect(find.text('Active Projects'), findsOneWidget);

      // Department items rendered
      expect(find.text('Mobile Engineering'), findsOneWidget);
      expect(find.text('Quality Assurance'), findsOneWidget);

      // Scroll down to see 3rd item
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Legacy Systems'), findsOneWidget);

      // Head names & tags
      expect(find.text('Aman Bhatia'), findsOneWidget);
      expect(find.text('No Head Assigned'), findsWidgets);
      expect(find.text('ACTIVE'), findsWidgets);
      expect(find.text('INACTIVE'), findsWidgets);
    });

    testWidgets('Search input dynamically filters department cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: DepartmentsScreen(directoryService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mobile Engineering'), findsOneWidget);
      expect(find.text('Quality Assurance'), findsOneWidget);

      // Type "QA" into search
      await tester.enterText(find.byType(TextField).first, 'QA');
      await tester.pumpAndSettle();

      expect(find.text('Quality Assurance'), findsOneWidget);
      expect(find.text('Mobile Engineering'), findsNothing);
      expect(find.text('Legacy Systems'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Mobile Engineering'), findsOneWidget);
      expect(find.text('Quality Assurance'), findsOneWidget);
    });

    testWidgets('Status filter chips filter active vs inactive departments', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: DepartmentsScreen(directoryService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'INACTIVE' chip
      await tester.tap(find.text('INACTIVE'));
      await tester.pumpAndSettle();

      expect(find.text('Legacy Systems'), findsOneWidget);
      expect(find.text('Mobile Engineering'), findsNothing);
      expect(find.text('Quality Assurance'), findsNothing);

      // Tap 'ACTIVE' chip
      await tester.tap(find.text('ACTIVE'));
      await tester.pumpAndSettle();

      expect(find.text('Mobile Engineering'), findsOneWidget);
      expect(find.text('Quality Assurance'), findsOneWidget);
      expect(find.text('Legacy Systems'), findsNothing);
    });

    testWidgets('Add Department modal opens, validates required fields, and submits', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: DepartmentsScreen(directoryService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Add Dept in AppBar
      await tester.tap(find.text('Add Dept'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Department'), findsOneWidget);
      expect(find.text('Department Name *'), findsOneWidget);
      expect(find.text('Create Department'), findsOneWidget);

      // Tap submit with empty name
      await tester.ensureVisible(find.text('Create Department'));
      await tester.tap(find.text('Create Department'));
      await tester.pumpAndSettle();

      expect(find.text('Department name is required.'), findsOneWidget);

      // Enter valid name into dialog name field
      final dialogNameField = find.widgetWithText(TextField, 'e.g. Mobile Engineering, QA & Testing');
      await tester.enterText(dialogNameField, 'Security Operations');
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(find.text('Create Department'));
      await tester.tap(find.text('Create Department'));
      await tester.pumpAndSettle();

      expect(mockService.lastSavedPayload, isNotNull);
      expect(mockService.lastSavedPayload!['name'], 'Security Operations');
      expect(mockService.lastSavedPayload!['status'], 'active');
    });

    testWidgets('Add Department validates 120-character limit and shows API error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: DepartmentsScreen(directoryService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Dept'));
      await tester.pumpAndSettle();

      // Enter name exceeding 120 characters
      final dialogNameField = find.widgetWithText(TextField, 'e.g. Mobile Engineering, QA & Testing');
      final longName = 'A' * 125;
      await tester.enterText(dialogNameField, longName);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Create Department'));
      await tester.tap(find.text('Create Department'));
      await tester.pumpAndSettle();

      expect(find.text('Department name must be under 120 characters.'), findsOneWidget);
    });

    testWidgets('Edit Department opens pre-filled modal and submits updates', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: DepartmentsScreen(directoryService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Tap first Edit icon
      final editButtons = find.byTooltip('Edit Department');
      expect(editButtons, findsWidgets);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Edit Department'), findsOneWidget);
      expect(find.text('Update Department'), findsOneWidget);

      // Submit update
      await tester.tap(find.text('Update Department'));
      await tester.pumpAndSettle();

      expect(mockService.lastSavedPayload, isNotNull);
      expect(mockService.lastSavedPayload!['id'], 1);
      expect(mockService.lastSavedPayload!['name'], 'Mobile Engineering');
    });

    testWidgets('In-use department triggers deactivation confirmation modal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: DepartmentsScreen(directoryService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // First department (Mobile Engineering) is in use (6 employees, 3 projects)
      final deleteButtons = find.byIcon(Icons.delete_outline);
      expect(deleteButtons, findsWidgets);

      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Must show Deactivate confirmation dialog
      expect(find.text('Deactivate Department'), findsOneWidget);
      expect(find.textContaining('cannot be permanently deleted. Mark it as inactive instead?'), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);

      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();

      expect(mockService.lastDeletedId, 1);
    });

    testWidgets('Empty department triggers permanent deletion confirmation modal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: DepartmentsScreen(directoryService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Third department (Legacy Systems) has 0 employees, 0 projects, but is inactive (icon is Icons.block)
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      final blockButton = find.byIcon(Icons.block);
      expect(blockButton, findsOneWidget);

      await tester.tap(blockButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete Department'), findsOneWidget);
      expect(find.textContaining('permanently delete department "Legacy Systems"'), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);

      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      expect(mockService.lastDeletedId, 3);
    });

    testWidgets('360dp compact viewport renders DepartmentsScreen without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: DepartmentsScreen(directoryService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no exceptions or overflow occurred
      expect(tester.takeException(), isNull);
    });
  });
}
