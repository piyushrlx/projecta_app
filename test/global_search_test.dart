import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/search/global_search_screen.dart';
import 'package:projecta_app/services/dashboard_service.dart';

class FakeDashboardService extends DashboardService {
  String? lastQuery;
  bool shouldFail = false;

  final Map<String, dynamic> sampleResults = {
    'projects': [
      {
        'id': 10,
        'project_code': 'PRJ-001',
        'name': 'Alpha Mobile Platform',
        'client_name': 'Acme Global',
        'status': 'active',
        'priority': 'high',
        'deadline': '2026-12-01',
      },
    ],
    'tasks': [
      {
        'id': 20,
        'task_code': 'TSK-042',
        'title': 'Implement Omnibar Search',
        'project_name': 'Alpha Mobile Platform',
        'status': 'in_progress',
        'priority': 'critical',
        'deadline': '2026-11-20',
      },
    ],
    'employees': [
      {
        'id': 30,
        'full_name': 'Harshit Kumar',
        'email': 'harshit@rankfirst.tech',
        'department_name': 'Development',
        'role': 'staff',
      },
    ],
  };

  @override
  Future<Map<String, dynamic>> searchGlobal(String query) async {
    lastQuery = query;
    if (shouldFail) {
      throw Exception('Network connection timed out');
    }
    if (query == 'empty') {
      return {'projects': [], 'tasks': [], 'employees': []};
    }
    return sampleResults;
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

  Widget createTestWidget({FakeDashboardService? dashboardService, UserModel? user}) {
    return MaterialApp(
      theme: AppTheme.themeData,
      home: GlobalSearchScreen(
        user: user ?? adminUser,
        dashboardService: dashboardService ?? FakeDashboardService(),
      ),
    );
  }

  group('Phase 1: GlobalSearchScreen Widget & Debounce Tests', () {
    testWidgets('Renders empty search state initially', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search WorkDesk'), findsOneWidget);
      expect(
        find.text('Type at least 2 characters to find projects, tasks, or employees.'),
        findsOneWidget,
      );
    });

    testWidgets('Does not trigger search for single character', (tester) async {
      final fakeService = FakeDashboardService();
      await tester.pumpWidget(createTestWidget(dashboardService: fakeService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(fakeService.lastQuery, isNull);
      expect(find.text('Search WorkDesk'), findsOneWidget);
    });

    testWidgets('Debounces search and renders categorized result cards', (tester) async {
      final fakeService = FakeDashboardService();
      await tester.pumpWidget(createTestWidget(dashboardService: fakeService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'alpha');
      // Before debounce fires:
      expect(fakeService.lastQuery, isNull);

      // Advance clock past 300ms debounce:
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(fakeService.lastQuery, equals('alpha'));

      // Check Category Headers
      expect(find.text('PROJECTS'), findsOneWidget);
      expect(find.text('TASKS'), findsOneWidget);
      expect(find.text('EMPLOYEES'), findsOneWidget);

      // Check Result Items
      expect(find.text('Alpha Mobile Platform'), findsOneWidget);
      expect(find.text('• Alpha Mobile Platform'), findsOneWidget);
      expect(find.text('PRJ-001'), findsOneWidget);
      expect(find.text('Implement Omnibar Search'), findsOneWidget);
      expect(find.text('TSK-042'), findsOneWidget);
      expect(find.text('Harshit Kumar'), findsOneWidget);
      expect(find.text('harshit@rankfirst.tech'), findsOneWidget);
    });

    testWidgets('Displays no results state when empty array returned', (tester) async {
      final fakeService = FakeDashboardService();
      await tester.pumpWidget(createTestWidget(dashboardService: fakeService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'empty');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('No results found for "empty"'), findsOneWidget);
    });

    testWidgets('Renders error state gracefully on network failure', (tester) async {
      final fakeService = FakeDashboardService()..shouldFail = true;
      await tester.pumpWidget(createTestWidget(dashboardService: fakeService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'failing');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Exception: Network connection timed out'), findsOneWidget);
    });

    testWidgets('Clear button purges search field and restores initial prompt', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear), findsOneWidget);
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Search WorkDesk'), findsOneWidget);
    });
  });
}
