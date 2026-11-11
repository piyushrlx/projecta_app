import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/audit/audit_log_screen.dart';
import 'package:projecta_app/services/dashboard_service.dart';

class FakeAuditService extends DashboardService {
  String? queriedAction;

  @override
  Future<List<dynamic>> getAuditLogs({
    int? userId,
    String? action,
    String? entityType,
    String? from,
    String? to,
  }) async {
    queriedAction = action;
    return [
      {
        'id': 1,
        'actor_name': 'Aman Bhatia',
        'actor_role': 'super_admin',
        'action': 'user.profile_update',
        'entity_type': 'user',
        'entity_id': 1,
        'created_at': '2026-11-11 15:05:00',
        'ip_address': '192.168.1.5',
        'old_values': '{"phone": "+91 9876543210"}',
        'new_values': '{"phone": "+91 9999999999"}',
      },
      {
        'id': 2,
        'actor_name': 'Amul Bhatia',
        'actor_role': 'super_admin',
        'action': 'task.status_move',
        'entity_type': 'task',
        'entity_id': 42,
        'created_at': '2026-11-11 14:30:00',
        'ip_address': '192.168.1.10',
        'old_values': null,
        'new_values': '{"status": "in_progress"}',
      },
    ];
  }
}

void main() {
  const superAdmin = UserModel(
    id: 1,
    name: 'Aman Bhatia',
    email: 'aamannbhatia@gmail.com',
    role: 'super_admin',
    adminScope: 'all',
    mustChangePassword: false,
  );

  Widget createTestWidget({FakeAuditService? service}) {
    return MaterialApp(
      theme: AppTheme.themeData,
      home: AuditLogScreen(
        currentUser: superAdmin,
        dashboardService: service ?? FakeAuditService(),
      ),
    );
  }

  group('Phase 3: AuditLogScreen Widget & Interaction Tests', () {
    testWidgets('Renders audit log stream and filter input', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Audit Log Viewer'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Aman Bhatia'), findsOneWidget);
      expect(find.text('user.profile_update'), findsOneWidget);
      expect(find.text('user #1'), findsOneWidget);
      expect(find.text('Amul Bhatia'), findsOneWidget);
      expect(find.text('task.status_move'), findsOneWidget);
      expect(find.text('task #42'), findsOneWidget);
    });

    testWidgets('Expands JSON diff inspector tile and displays state changes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final inspectTile = find.text('Inspect State Diff').first;
      await tester.tap(inspectTile);
      await tester.pumpAndSettle();

      expect(find.text('Before:'), findsOneWidget);
      expect(find.text('After:'), findsOneWidget);
      expect(find.textContaining('+91 9876543210'), findsOneWidget);
      expect(find.textContaining('+91 9999999999'), findsOneWidget);
    });
  });
}

