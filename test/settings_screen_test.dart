import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/settings/settings_screen.dart';
import 'package:projecta_app/services/dashboard_service.dart';

class FakeSettingsService extends DashboardService {
  bool didSave = false;
  bool didAddHoliday = false;
  bool didDeleteHoliday = false;

  @override
  Future<Map<String, dynamic>> getFullSettings() async {
    return {
      'settings': {
        'company_name': 'Rank First Technologies',
        'timezone': 'Asia/Kolkata',
        'currency': 'INR',
        'work_start_time': '09:30',
        'work_end_time': '18:30',
        'report_deadline_time': '19:00',
        'report_grace_minutes': 60,
        'staff_can_set_progress': '1',
        'staff_can_upload': '1',
        'require_completion_notes': '1',
      },
      'holidays': [
        {
          'id': 10,
          'holiday_date': '2026-12-25',
          'name': 'Christmas Celebration',
        },
      ],
    };
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> data) async {
    didSave = true;
  }

  @override
  Future<int> addHoliday(String date, String name) async {
    didAddHoliday = true;
    return 99;
  }

  @override
  Future<void> deleteHoliday(int id) async {
    didDeleteHoliday = true;
  }
}

void main() {
  const superAdminUser = UserModel(
    id: 1,
    name: 'Aman Bhatia',
    email: 'aamannbhatia@gmail.com',
    role: 'super_admin',
    adminScope: 'all',
    mustChangePassword: false,
  );

  Widget createTestWidget({FakeSettingsService? service}) {
    return MaterialApp(
      theme: AppTheme.themeData,
      home: SettingsScreen(
        currentUser: superAdminUser,
        dashboardService: service ?? FakeSettingsService(),
      ),
    );
  }

  group('Phase 3: SettingsScreen Widget & Interaction Tests', () {
    testWidgets('Renders settings tabs and general configuration', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Working time'), findsOneWidget);
      expect(find.text('Rules & permissions'), findsOneWidget);
      expect(find.text('Company & Display'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Rank First Technologies'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Asia/Kolkata'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'INR'), findsOneWidget);
    });

    testWidgets('Switches to Holidays tab and renders holiday list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.textContaining('Holidays'));
      await tester.tap(find.textContaining('Holidays'));
      await tester.pumpAndSettle();

      expect(find.text('Company Holidays'), findsOneWidget);
      expect(find.text('Christmas Celebration'), findsOneWidget);
      expect(find.text('2026-12-25'), findsOneWidget);
      expect(find.text('Add Holiday'), findsOneWidget);
    });

    testWidgets('Saves updated general settings and renders success snackbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = FakeSettingsService();
      await tester.pumpWidget(createTestWidget(service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fakeService.didSave, isTrue);
      expect(find.text('Settings saved successfully.'), findsOneWidget);
    });
  });
}
