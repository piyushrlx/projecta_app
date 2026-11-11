import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/contact/contact_messages_screen.dart';
import 'package:projecta_app/services/dashboard_service.dart';

class FakeContactService extends DashboardService {
  int? readId;
  int? deletedId;

  @override
  Future<Map<String, dynamic>> getContactMessages({bool unreadOnly = false}) async {
    return {
      'unread_count': 1,
      'messages': [
        {
          'id': 1,
          'name': 'Sarah Connor',
          'email': 'sarah@example.com',
          'phone': '+1 555-0199',
          'subject': 'Enterprise License Inquiry',
          'message': 'We would like to discuss deploying Projeqta across 500 seats.',
          'is_read': 0,
          'created_at': '2026-11-11 12:00:00',
        },
        {
          'id': 2,
          'name': 'John Doe',
          'email': 'john@example.com',
          'phone': '',
          'subject': 'API Webhook Support',
          'message': 'Does the system support outgoing webhooks for Jira sync?',
          'is_read': 1,
          'created_at': '2026-11-10 10:00:00',
        },
      ],
    };
  }

  @override
  Future<void> markContactMessageRead(int id) async {
    readId = id;
  }

  @override
  Future<void> deleteContactMessage(int id) async {
    deletedId = id;
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

  Widget createTestWidget({FakeContactService? service}) {
    return MaterialApp(
      theme: AppTheme.themeData,
      home: ContactMessagesScreen(
        currentUser: superAdmin,
        dashboardService: service ?? FakeContactService(),
      ),
    );
  }

  group('Phase 3: ContactMessagesScreen Widget & Interaction Tests', () {
    testWidgets('Renders inquiry list and unread count badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Contact Messages'), findsOneWidget);
      expect(find.text('Unread messages: '), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(find.text('Enterprise License Inquiry'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('API Webhook Support'), findsOneWidget);
    });

    testWidgets('Opens reader dialog on tap and marks message as read', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = FakeContactService();
      await tester.pumpWidget(createTestWidget(service: fakeService));
      await tester.pumpAndSettle();

      // Tap first message card
      await tester.tap(find.text('Enterprise License Inquiry'));
      await tester.pumpAndSettle();

      expect(fakeService.readId, equals(1));
      expect(find.text('From: Sarah Connor (sarah@example.com)'), findsOneWidget);
      expect(find.text('Phone: +1 555-0199'), findsOneWidget);
      expect(find.text('We would like to discuss deploying Projeqta across 500 seats.'), findsNWidgets(2)); // Card preview + Dialog body
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Deletes contact message with confirmation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = FakeContactService();
      await tester.pumpWidget(createTestWidget(service: fakeService));
      await tester.pumpAndSettle();

      // Open reader dialog
      await tester.tap(find.text('Enterprise License Inquiry'));
      await tester.pumpAndSettle();

      // Tap Delete in dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirmation dialog pops up
      expect(find.text('Delete Message'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this message?'), findsOneWidget);

      // Confirm delete
      final confirmBtn = find.widgetWithText(FilledButton, 'Delete');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(fakeService.deletedId, equals(1));
      expect(find.text('Message deleted.'), findsOneWidget);
    });
  });
}
