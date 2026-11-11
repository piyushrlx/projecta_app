import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/analytics/analytics_hub_screen.dart';
import 'package:projecta_app/services/report_service.dart';

class FakeReportService extends ReportService {
  String? lastType;

  @override
  Future<Map<String, dynamic>> getAnalyticsData({
    required String type,
    String? from,
    String? to,
    int? departmentId,
    int? userId,
    int? projectId,
  }) async {
    lastType = type;

    if (type == 'employee') {
      return {
        'summary': {
          'total_employees': 12,
          'total_completed_tasks': 48,
          'total_open_tasks': 16,
        },
        'rows': [
          {
            'user_id': 1,
            'full_name': 'Aman Bhatia',
            'employee_code': 'EMP-0001',
            'designation': 'Director',
            'completed_tasks': 10,
            'open_tasks': 3,
            'reports_submitted': 25,
          },
        ],
      };
    } else if (type == 'project') {
      return {
        'summary': {
          'total_projects': 5,
          'active_projects': 4,
          'completed_projects': 1,
        },
        'rows': [
          {
            'project_id': 10,
            'name': 'Customer Portal 2.0',
            'code': 'PRJ-PORTAL',
            'completed_tasks': 18,
            'total_tasks': 20,
            'progress_percent': 90,
          },
        ],
      };
    }

    return {'summary': {}, 'rows': []};
  }
}

void main() {
  const adminUser = UserModel(
    id: 1,
    name: 'Aman Bhatia',
    email: 'aamannbhatia@gmail.com',
    role: 'super_admin',
    adminScope: 'all',
    mustChangePassword: false,
  );

  const staffUser = UserModel(
    id: 5,
    name: 'Gautam Staff',
    email: 'gautam@rankfirst.tech',
    role: 'staff',
    adminScope: 'assigned',
    mustChangePassword: false,
  );

  Widget createTestWidget({UserModel? user, FakeReportService? service}) {
    return MaterialApp(
      theme: AppTheme.themeData,
      home: AnalyticsHubScreen(
        currentUser: user ?? adminUser,
        reportService: service ?? FakeReportService(),
      ),
    );
  }

  group('Phase 2: AnalyticsHubScreen Widget & Interaction Tests', () {
    testWidgets('Renders all 6 dimensions for Admin and displays summary metrics', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Reports & Analytics Hub'), findsOneWidget);
      expect(find.text('Employee Performance'), findsOneWidget);
      expect(find.text('Project Progress'), findsOneWidget);
      expect(find.text('Daily Work Log'), findsOneWidget);
      expect(find.text('Pending Backlog'), findsOneWidget);
      expect(find.text('Deadlines & Delay'), findsOneWidget);
      expect(find.text('Compliance Trends'), findsOneWidget);

      // Summary metrics
      expect(find.text('Summary Overview'), findsOneWidget);
      expect(find.text('12'), findsOneWidget); // total_employees
      expect(find.text('48'), findsOneWidget); // total_completed_tasks
      expect(find.text('Aman Bhatia'), findsOneWidget);
      expect(find.text('EMP-0001 · Director'), findsOneWidget);
    });

    testWidgets('Switches to Project Progress dimension and renders progress metrics', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = FakeReportService();
      await tester.pumpWidget(createTestWidget(service: fakeService));
      await tester.pumpAndSettle();

      // Tap Project Progress chip
      await tester.ensureVisible(find.text('Project Progress'));
      await tester.tap(find.text('Project Progress'));
      await tester.pumpAndSettle();

      expect(fakeService.lastType, equals('project'));
      expect(find.text('Customer Portal 2.0'), findsOneWidget);
      expect(find.text('PRJ-PORTAL'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('18 / 20 tasks'), findsOneWidget);
    });

    testWidgets('Restricts Staff users to own Employee & Daily reports only', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(user: staffUser));
      await tester.pumpAndSettle();

      expect(find.text('Employee Performance'), findsOneWidget);
      expect(find.text('Daily Work Log'), findsOneWidget);
      expect(find.text('Project Progress'), findsNothing);
      expect(find.text('Pending Backlog'), findsNothing);
      expect(find.text('Deadlines & Delay'), findsNothing);
      expect(find.text('Compliance Trends'), findsNothing);
    });

    testWidgets('Triggers CSV Export action and displays snackbar confirmation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pumpAndSettle();

      expect(find.textContaining('Exporting 1 records for EMPLOYEE report to CSV...'), findsOneWidget);
    });
  });
}
