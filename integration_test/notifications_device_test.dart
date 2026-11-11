import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:projecta_app/core/api_client.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/notifications/notifications_screen.dart';
import 'package:projecta_app/screens/tasks/task_detail_screen.dart';
import 'package:projecta_app/services/auth_service.dart';
import 'package:projecta_app/services/notification_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const String deviceApiUrl = 'http://localhost:8080/projecta/api/v1';

  setUpAll(() async {
    ApiClient().setBaseUrl(deviceApiUrl);
  });

  group('Module 8: Live Physical Device Verification (CPH2139)', () {
    testWidgets('Live Notifications & Deep-Linking Test on Android Device',
        (tester) async {
      // 1. Authenticate against live backend
      final authService = AuthService();
      UserModel user;
      try {
        user = await authService.login(
          'aamannbhatia@gmail.com',
          'Password@123',
          deviceName: 'CPH2139 Notification Audit',
        );
      } catch (_) {
        final cached = await authService.getCurrentUser();
        if (cached == null) {
          fail('Could not log in to backend from device.');
        }
        user = cached;
      }

      expect(user.isAdmin, true);

      // 2. Launch NotificationsScreen with live NotificationService
      final notificationService = NotificationService();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: NotificationsScreen(
            user: user,
            notificationService: notificationService,
          ),
        ),
      );

      // Wait for notifications to load from live API
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // 3. Verify screen elements
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('UNREAD'), findsOneWidget);
      expect(find.text('TASKS'), findsOneWidget);
      expect(find.text('PROJECTS'), findsOneWidget);
      expect(find.text('REPORTS'), findsOneWidget);

      // 4. Test 1-tap filter switching on physical screen
      await tester.tap(find.text('UNREAD'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      await tester.tap(find.text('TASKS'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // 5. Test Live Deep-Linking: tap the first task notification card
      final taskCards = find.textContaining('task', findRichText: true);
      if (taskCards.evaluate().isNotEmpty) {
        await tester.tap(taskCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify TaskDetailScreen opened on physical screen
        expect(find.byType(TaskDetailScreen), findsOneWidget);

        // 6. Test Back Navigation without spinner flash
        final backButton = find.byTooltip('Back');
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
        } else {
          final navigator = tester.state<NavigatorState>(find.byType(Navigator));
          navigator.pop();
        }
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verified back on NotificationsScreen
        expect(find.byType(NotificationsScreen), findsOneWidget);
      }

      // Return to ALL filter
      await tester.tap(find.text('ALL'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    });
  });
}
