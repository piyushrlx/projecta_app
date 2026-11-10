import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:projecta_app/core/api_client.dart';
import 'package:projecta_app/models/report_model.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/reports/compliance_matrix_view.dart';
import 'package:projecta_app/screens/reports/reports_list_screen.dart';
import 'package:projecta_app/services/report_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyAdmin = UserModel(
    id: 1,
    name: 'Aman Bhatia',
    email: 'aman@example.com',
    role: 'super_admin',
    adminScope: 'all',
    mustChangePassword: false,
    departmentId: 1,
  );

  final dummyStaff = UserModel(
    id: 6,
    name: 'Piyush Bhatt',
    email: 'piyush@example.com',
    role: 'staff',
    adminScope: 'assigned',
    mustChangePassword: false,
    departmentId: 1,
  );

  final sampleComplianceJson = {
    'ok': true,
    'date': '2026-11-10',
    'deadline_time': '08:00 PM',
    'deadline_passed': false,
    'is_working_day': true,
    'is_holiday': false,
    'summary': {
      'rows': [
        {
          'id': 7,
          'employee_code': 'EMP-0007',
          'full_name': 'Gautam Kumar',
          'department_id': 1,
          'department_name': 'Development',
          'status': 'pending',
          'reports': 0,
          'last_submitted_at': null,
          'pending_tasks': 3,
          'required': true,
          'returned': 0,
          'profile_photo_url': null,
        },
        {
          'id': 6,
          'employee_code': 'EMP-0006',
          'full_name': 'Piyush Bhatt',
          'department_id': 1,
          'department_name': 'Development',
          'status': 'submitted',
          'reports': 1,
          'last_submitted_at': '2026-11-10 18:30:00',
          'pending_tasks': 1,
          'required': true,
          'returned': 0,
          'profile_photo_url': null,
        },
        {
          'id': 3,
          'employee_code': 'EMP-0003',
          'full_name': 'Harshit Kumar',
          'department_id': 1,
          'department_name': 'Development',
          'status': 'submitted_late',
          'reports': 1,
          'last_submitted_at': '2026-11-10 20:30:00',
          'pending_tasks': 2,
          'required': true,
          'returned': 0,
          'profile_photo_url': null,
        },
        {
          'id': 4,
          'employee_code': 'EMP-0004',
          'full_name': 'Karan Sharma',
          'department_id': 1,
          'department_name': 'Development',
          'status': 'returned',
          'reports': 1,
          'last_submitted_at': '2026-11-10 17:00:00',
          'pending_tasks': 0,
          'required': true,
          'returned': 1,
          'profile_photo_url': null,
        },
        {
          'id': 8,
          'employee_code': 'EMP-0008',
          'full_name': 'Mohit Verma',
          'department_id': 1,
          'department_name': 'Development',
          'status': 'not_due',
          'reports': 0,
          'last_submitted_at': null,
          'pending_tasks': 0,
          'required': false,
          'returned': 0,
          'profile_photo_url': null,
        },
      ],
      'required': 4,
      'compliant': 2,
      'percent': 50,
      'kpis': {
        'percent': 50,
        'required': 4,
        'compliant': 2,
        'submitted_on_time': 1,
        'submitted_late': 1,
        'pending': 1,
        'returned': 1,
        'not_due': 1,
      },
    },
    'trend_7_days': [
      {'date': '2026-11-04', 'percent': 75, 'required': 4, 'compliant': 3},
      {'date': '2026-11-05', 'percent': 100, 'required': 4, 'compliant': 4},
      {'date': '2026-11-06', 'percent': 50, 'required': 4, 'compliant': 2},
      {'date': '2026-11-07', 'percent': 100, 'required': 0, 'compliant': 0},
      {'date': '2026-11-08', 'percent': 100, 'required': 0, 'compliant': 0},
      {'date': '2026-11-09', 'percent': 25, 'required': 4, 'compliant': 1},
      {'date': '2026-11-10', 'percent': 50, 'required': 4, 'compliant': 2},
    ],
  };

  group('Module 5: Compliance Models Unit Tests', () {
    test('ComplianceEmployeeRow parses correctly and calculates getters', () {
      final row = ComplianceEmployeeRow.fromJson({
        'id': 7,
        'full_name': 'Gautam Kumar',
        'employee_code': 'EMP-0007',
        'department_name': 'Development',
        'status': 'pending',
        'reports': 0,
        'pending_tasks': 3,
        'required': 1,
        'returned': 0,
      });

      expect(row.id, 7);
      expect(row.fullName, 'Gautam Kumar');
      expect(row.employeeCode, 'EMP-0007');
      expect(row.isPending, isTrue);
      expect(row.isSubmitted, isFalse);
      expect(row.statusLabel, 'Pending');
      expect(row.pendingTasks, 3);
    });

    test('ComplianceDayTrend parses and produces dayLabel', () {
      final trend = ComplianceDayTrend.fromJson({
        'date': '2026-11-10',
        'percent': 85,
        'required': 7,
        'compliant': 6,
      });

      expect(trend.date, '2026-11-10');
      expect(trend.percent, 85);
      expect(trend.dayLabel, contains('10'));
    });

    test(
      'ComplianceSummaryModel parses full payload and calculates fallbacks',
      () {
        final model = ComplianceSummaryModel.fromJson(sampleComplianceJson);

        expect(model.date, '2026-11-10');
        expect(model.deadlineTime, '08:00 PM');
        expect(model.deadlinePassed, isFalse);
        expect(model.isWorkingDay, isTrue);
        expect(model.percent, 50);
        expect(model.required, 4);
        expect(model.compliant, 2);
        expect(model.submittedOnTime, 1);
        expect(model.submittedLate, 1);
        expect(model.pendingCount, 1);
        expect(model.returnedCount, 1);
        expect(model.notDueCount, 1);
        expect(model.rows.length, 5);
        expect(model.trend.length, 7);
      },
    );
  });

  group('Module 5: ReportService Integration Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      ApiClient().resetHttpClient();
    });

    test(
      'getComplianceSummary calls GET /compliance/summary and returns model',
      () async {
        ApiClient().customHttpClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, contains('/compliance/summary'));
          expect(request.url.queryParameters['date'], '2026-11-10');
          return http.Response(jsonEncode(sampleComplianceJson), 200);
        });

        final service = ReportService();
        final summary = await service.getComplianceSummary('2026-11-10');

        expect(summary.date, '2026-11-10');
        expect(summary.percent, 50);
        expect(summary.rows.length, 5);
      },
    );

    test(
      'remindDefaulter calls POST /reports/remind with user_id and date',
      () async {
        ApiClient().customHttpClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, contains('/reports/remind'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['user_id'], 7);
          expect(body['date'], '2026-11-10');
          return http.Response(
            jsonEncode({
              'ok': true,
              'message': 'Reminder successfully sent to Gautam Kumar.',
              'sent': true,
            }),
            200,
          );
        });

        final service = ReportService();
        final res = await service.remindDefaulter(
          userId: 7,
          date: '2026-11-10',
        );
        expect(res['sent'], isTrue);
        expect(res['message'], contains('Gautam Kumar'));
      },
    );

    test(
      'createExemption calls POST /reports/exemption with parameters',
      () async {
        ApiClient().customHttpClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, contains('/reports/exemption'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['user_id'], 7);
          expect(body['start_date'], '2026-11-10');
          expect(body['end_date'], '2026-11-12');
          expect(body['type'], 'leave');
          expect(body['reason'], 'Doctor appointment');
          return http.Response(
            jsonEncode({
              'ok': true,
              'message': 'Exemption recorded successfully.',
              'id': 42,
            }),
            200,
          );
        });

        final service = ReportService();
        final res = await service.createExemption(
          userId: 7,
          startDate: '2026-11-10',
          endDate: '2026-11-12',
          type: 'leave',
          reason: 'Doctor appointment',
        );
        expect(res['id'], 42);
      },
    );
  });

  group('Module 5: ComplianceMatrixView Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      ApiClient().resetHttpClient();
    });

    testWidgets(
      'Renders Date Navigator, Cutoff Banner, 6 KPI cards, and 7-day trend',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        ApiClient().customHttpClient = MockClient((request) async {
          return http.Response(jsonEncode(sampleComplianceJson), 200);
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ComplianceMatrixView(
                user: dummyAdmin,
                initialDate: '2026-11-10',
              ),
            ),
          ),
        );

        // Loading state initially
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();

        // 1. Date Navigator
        expect(find.text('Prev'), findsOneWidget);
        expect(find.text('2026-11-10'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);

        // 2. Cutoff Banner
        expect(find.textContaining('Cutoff: 08:00 PM'), findsOneWidget);
        expect(find.textContaining('Submissions on-time'), findsOneWidget);

        // 3. 6 KPI Cards
        expect(find.text('50%'), findsWidgets); // KPI card & trend
        expect(find.text('Compliance Rate'), findsOneWidget);
        expect(find.text('Required to Report'), findsOneWidget);
        expect(find.text('Submitted Reports'), findsOneWidget);
        expect(find.text('Pending (Missing)'), findsOneWidget);
        expect(find.text('Returned / Clarify'), findsOneWidget);
        expect(find.text('Not Due'), findsWidgets);

        // 4. 7-Day Trend Chart
        expect(find.text('7-Day Compliance Trend'), findsOneWidget);
        expect(find.text('Tap day to jump'), findsOneWidget);

        // 5. Employee roster rendered
        expect(find.text('Gautam Kumar'), findsOneWidget);
        expect(find.text('Piyush Bhatt'), findsOneWidget);
        expect(find.text('Harshit Kumar'), findsOneWidget);
        expect(find.text('Karan Sharma'), findsOneWidget);
        expect(find.text('Mohit Verma'), findsOneWidget);

        // 6. Remind button present for Gautam Kumar (pending defaulter)
        expect(find.text('Remind'), findsOneWidget);
      },
    );

    testWidgets('Filter chip taps filter the employee roster correctly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      ApiClient().customHttpClient = MockClient((request) async {
        return http.Response(jsonEncode(sampleComplianceJson), 200);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplianceMatrixView(
              user: dummyAdmin,
              initialDate: '2026-11-10',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Pending (Defaulters)" filter chip
      final pendingChip = find.text('Pending (Defaulters)');
      expect(pendingChip, findsOneWidget);
      await tester.tap(pendingChip);
      await tester.pumpAndSettle();

      // Only Gautam Kumar should remain
      expect(find.text('Gautam Kumar'), findsOneWidget);
      expect(find.text('Piyush Bhatt'), findsNothing);
      expect(find.text('Harshit Kumar'), findsNothing);
    });

    testWidgets(
      'Tapping Remind button opens confirmation dialog and triggers API',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        bool remindApiCalled = false;
        ApiClient().customHttpClient = MockClient((request) async {
          if (request.url.path.contains('/reports/remind')) {
            remindApiCalled = true;
            return http.Response(
              jsonEncode({
                'ok': true,
                'message': 'Reminder sent to Gautam Kumar.',
                'sent': true,
              }),
              200,
            );
          }
          return http.Response(jsonEncode(sampleComplianceJson), 200);
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ComplianceMatrixView(
                user: dummyAdmin,
                initialDate: '2026-11-10',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll down to reveal employee cards
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -350),
        );
        await tester.pumpAndSettle();

        // Find and tap Remind button
        final remindBtn = find.text('Remind');
        expect(remindBtn, findsOneWidget);
        await tester.tap(remindBtn);
        await tester.pumpAndSettle();

        // Confirmation dialog should appear
        expect(find.text('Send Missing Report Reminder'), findsOneWidget);
        expect(
          find.textContaining('Send an immediate reminder notification'),
          findsOneWidget,
        );

        // Tap confirm "Send Reminder"
        final confirmBtn = find.widgetWithText(ElevatedButton, 'Send Reminder');
        expect(confirmBtn, findsOneWidget);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(remindApiCalled, isTrue);
        // Remind button should now display "Reminded"
        expect(find.text('Reminded'), findsOneWidget);
        // Success snackbar displayed
        expect(find.text('Reminder sent to Gautam Kumar.'), findsOneWidget);
      },
    );
  });

  group('Module 5: ReportsListScreen Segmented Switch Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      ApiClient().resetHttpClient();
    });

    testWidgets(
      'Admin user sees top segment switch and can toggle to Compliance Matrix',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        ApiClient().customHttpClient = MockClient((request) async {
          if (request.url.path.contains('/compliance/summary')) {
            return http.Response(jsonEncode(sampleComplianceJson), 200);
          }
          return http.Response(
            jsonEncode({'ok': true, 'reports': [], 'total': 0, 'page': 1}),
            200,
          );
        });

        await tester.pumpWidget(
          MaterialApp(home: ReportsListScreen(user: dummyAdmin)),
        );

        await tester.pumpAndSettle();

        // Segment switch must be present for admin
        expect(find.text('Submissions Queue'), findsOneWidget);
        expect(find.text('Compliance Matrix'), findsOneWidget);

        // Initially on Submissions Queue
        expect(find.text('Daily Reports Inbox'), findsOneWidget);

        // Tap Compliance Matrix
        await tester.tap(find.text('Compliance Matrix'));
        await tester.pumpAndSettle();

        // Title adjusts and ComplianceMatrixView is rendered
        expect(find.text('Reporting Compliance'), findsOneWidget);
        expect(find.text('7-Day Compliance Trend'), findsOneWidget);
        expect(find.text('Gautam Kumar'), findsOneWidget);
      },
    );

    testWidgets(
      'Staff user DOES NOT see the segment switch (preserves staff UX)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        ApiClient().customHttpClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'ok': true, 'reports': [], 'total': 0, 'page': 1}),
            200,
          );
        });

        await tester.pumpWidget(
          MaterialApp(home: ReportsListScreen(user: dummyStaff)),
        );

        await tester.pumpAndSettle();

        // No segment switch for staff
        expect(find.text('Submissions Queue'), findsNothing);
        expect(find.text('Compliance Matrix'), findsNothing);
        expect(find.text('My Daily Reports'), findsOneWidget);
      },
    );

    testWidgets(
      'initialViewMode: compliance opens Compliance Matrix directly',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        ApiClient().customHttpClient = MockClient((request) async {
          if (request.url.path.contains('/compliance/summary')) {
            return http.Response(jsonEncode(sampleComplianceJson), 200);
          }
          return http.Response(
            jsonEncode({'ok': true, 'reports': [], 'total': 0, 'page': 1}),
            200,
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: ReportsListScreen(
              user: dummyAdmin,
              initialViewMode: 'compliance',
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Reporting Compliance'), findsOneWidget);
        expect(find.text('7-Day Compliance Trend'), findsOneWidget);
      },
    );
  });
}
