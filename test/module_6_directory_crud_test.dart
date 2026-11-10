import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/employee_detail_model.dart';
import 'package:projecta_app/screens/team/departments_sheet.dart';
import 'package:projecta_app/screens/team/employee_detail_screen.dart';
import 'package:projecta_app/screens/team/employee_form_screen.dart';
import 'package:projecta_app/screens/team/team_list_screen.dart';
import 'package:projecta_app/services/directory_service.dart';

class MockDirectoryService extends DirectoryService {
  final Map<String, dynamic> sampleDetailData = {
    'id': 101,
    'employee_code': 'EMP-0101',
    'username': 'john.doe',
    'email': 'john.doe@projeqta.com',
    'full_name': 'John Doe',
    'phone': '+1234567890',
    'designation': 'Senior Flutter Engineer',
    'department_id': 1,
    'department_name': 'Mobile Engineering',
    'reporting_manager_id': 2,
    'reporting_manager_name': 'Aman Bhatia',
    'role': 'staff',
    'admin_scope': 'assigned',
    'admin_departments': <int>[],
    'status': 'active',
    'joining_date': '2024-01-15',
    'reporting_required': true,
    'must_change_password': false,
    'working_days': [1, 2, 3, 4, 5],
    'created_at': '2024-01-15 09:00:00',
    'can_manage': true,
    'kpis': {
      'assigned_tasks': 12,
      'completed_tasks': 9,
      'pending_tasks': 3,
      'overdue_tasks': 1,
      'compliance_rate': 95,
      'reports_count_30d': 22,
    },
    'tasks': [
      {
        'id': 501,
        'task_code': 'TSK-501',
        'title': 'Implement Team Dossier Screen',
        'status': 'in_progress',
        'priority': 'high',
        'deadline': '2026-11-15',
        'progress': 75,
        'project_name': 'Project Alpha Mobile',
        'project_id': 10,
      }
    ],
    'projects': [
      {
        'id': 10,
        'project_code': 'PRJ-10',
        'name': 'Project Alpha Mobile',
        'status': 'active',
        'deadline': '2026-12-31',
        'member_role': 'Lead Developer',
        'manager_name': 'Aman Bhatia',
      }
    ],
    'reports': [
      {
        'id': 901,
        'report_date': '2026-11-10',
        'work_summary': 'Refactored employee directory and added unit tests.',
        'minutes_spent': 480,
        'status': 'submitted',
        'is_late': false,
        'project_name': 'Project Alpha Mobile',
        'task_title': 'Implement Team Dossier Screen',
      }
    ],
    'exemptions': [
      {
        'id': 301,
        'start_date': '2026-10-01',
        'end_date': '2026-10-03',
        'reason': 'Annual Company Offsite Conference',
        'reason_type': 'conference',
        'approved_by_name': 'Aman Bhatia',
      }
    ],
  };

  @override
  Future<List<Map<String, dynamic>>> getEmployees({
    String? search,
    String? status,
    int? departmentId,
    int page = 1,
    int limit = 50,
  }) async {
    return [
      {
        'id': 101,
        'full_name': 'John Doe',
        'designation': 'Senior Flutter Engineer',
        'role': 'staff',
        'status': 'active',
        'department_name': 'Mobile Engineering',
        'email': 'john.doe@projeqta.com',
      },
      {
        'id': 102,
        'full_name': 'Sarah Connor',
        'designation': 'DevOps Specialist',
        'role': 'admin',
        'status': 'active',
        'department_name': 'Infrastructure',
        'email': 'sarah@projeqta.com',
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getDepartments({String status = 'active'}) async {
    return [
      {
        'id': 1,
        'name': 'Mobile Engineering',
        'description': 'Mobile client development',
        'manager_id': 2,
        'manager_name': 'Aman Bhatia',
        'status': 'active',
        'employee_count': 5,
        'active_projects_count': 2,
      },
      {
        'id': 2,
        'name': 'Infrastructure',
        'description': 'DevOps and Cloud Architecture',
        'manager_id': 2,
        'manager_name': 'Aman Bhatia',
        'status': 'active',
        'employee_count': 3,
        'active_projects_count': 1,
      },
    ];
  }

  @override
  Future<EmployeeDetailModel> getEmployeeDetail(int id) async {
    return EmployeeDetailModel.fromJson(sampleDetailData);
  }

  @override
  Future<Map<String, dynamic>> saveEmployee(Map<String, dynamic> data) async {
    return {'id': 101, 'message': 'Employee saved successfully.'};
  }

  @override
  Future<Map<String, dynamic>> toggleEmployeeStatus(int id) async {
    return {'status': 'inactive', 'message': 'Account status toggled successfully.'};
  }

  @override
  Future<Map<String, dynamic>> resetEmployeePassword(int id) async {
    return {'sent': true, 'message': 'Reset link sent.', 'link': 'http://localhost/reset-password.php?token=xyz'};
  }

  @override
  Future<Map<String, dynamic>> updateEmployeeRole(
    int id,
    String role, {
    String adminScope = 'assigned',
  }) async {
    return {'role': role, 'message': 'Role updated successfully.'};
  }

  @override
  Future<Map<String, dynamic>> saveDepartment(Map<String, dynamic> data) async {
    return {'id': 1, 'message': 'Department saved successfully.'};
  }

  @override
  Future<Map<String, dynamic>> deleteDepartment(int id) async {
    return {'deleted': true, 'message': 'Department deleted successfully.'};
  }
}

void main() {
  late MockDirectoryService mockService;

  setUp(() {
    mockService = MockDirectoryService();
  });

  group('Module 6: EmployeeDetailModel Parsing & Serialization', () {
    test('Correctly parses all 6 KPIs, profile info, and collections', () {
      final model = EmployeeDetailModel.fromJson(mockService.sampleDetailData);

      expect(model.id, 101);
      expect(model.fullName, 'John Doe');
      expect(model.email, 'john.doe@projeqta.com');
      expect(model.departmentName, 'Mobile Engineering');
      expect(model.isActive, true);
      expect(model.isStaff, true);
      expect(model.workingDays, [1, 2, 3, 4, 5]);

      // KPIs
      expect(model.kpis.assignedTasks, 12);
      expect(model.kpis.completedTasks, 9);
      expect(model.kpis.pendingTasks, 3);
      expect(model.kpis.overdueTasks, 1);
      expect(model.kpis.complianceRate, 95);
      expect(model.kpis.reportsCount30d, 22);

      // Collections
      expect(model.tasks.length, 1);
      expect(model.tasks.first.title, 'Implement Team Dossier Screen');
      expect(model.projects.length, 1);
      expect(model.projects.first.name, 'Project Alpha Mobile');
      expect(model.reports.length, 1);
      expect(model.reports.first.minutesSpent, 480);
      expect(model.exemptions.length, 1);
      expect(model.exemptions.first.reason, 'Annual Company Offsite Conference');
    });
  });

  group('Module 6: Widget & Screen Tests', () {
    testWidgets('EmployeeDetailScreen renders dossier, 4 KPI cards, and tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: EmployeeDetailScreen(
            employeeId: 101,
            directoryService: mockService,
          ),
        ),
      );

      // Initial loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify Name & Designation header
      expect(find.text('John Doe'), findsWidgets);
      expect(find.text('Senior Flutter Engineer'), findsOneWidget);
      expect(find.text('Mobile Engineering'), findsWidgets);

      // Verify 4 KPI cards
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('9/12'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Compliance'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);

      // Verify 4 Tabs
      expect(find.text('Tasks (1)'), findsOneWidget);
      expect(find.text('Projects (1)'), findsOneWidget);
      expect(find.text('Reports (1)'), findsOneWidget);
      expect(find.text('Leaves (1)'), findsOneWidget);

      // Verify first tab item
      expect(find.text('Implement Team Dossier Screen'), findsOneWidget);
    });

    testWidgets('EmployeeFormScreen validates required fields on submit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: EmployeeFormScreen(
            directoryService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Save button in AppBar
      final saveBtn = find.text('Save');
      expect(saveBtn, findsOneWidget);

      // Tap save without filling required fields
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Required validation messages
      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Username required'), findsOneWidget);
    });

    testWidgets('DepartmentsSheet opens and renders department list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => DepartmentsSheet.show(ctx, directoryService: mockService),
                child: const Text('Open Departments'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Departments'));
      await tester.pumpAndSettle();

      // Verify sheet header
      expect(find.text('Department Management'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      // Verify loaded departments
      expect(find.text('Mobile Engineering'), findsOneWidget);
      expect(find.text('Infrastructure'), findsOneWidget);
      expect(find.text('Head: Aman Bhatia  •  5 staff  •  2 projects'), findsOneWidget);
    });

    testWidgets('TeamListScreen renders members and opens EmployeeForm on FAB tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: TeamListScreen(
            directoryService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify team list loaded
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsOneWidget);

      // Verify FAB opens form
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify navigation to Add Team Member
      expect(find.text('Add New Employee'), findsOneWidget);
    });

    testWidgets('360dp compact viewport renders EmployeeDetailScreen without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: EmployeeDetailScreen(
            employeeId: 101,
            directoryService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // No overflow errors should be thrown
      expect(tester.takeException(), isNull);
    });
  });
}
