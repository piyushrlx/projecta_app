import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/auth/login_screen.dart';
import 'package:projecta_app/screens/auth/must_change_password_screen.dart';
import 'package:projecta_app/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3: UserModel & Auth Logic Tests', () {
    test('UserModel correctly parses must_change_password as true', () {
      final json = {
        'id': 10,
        'full_name': 'Test User',
        'email': 'test@domain.com',
        'role': 'staff',
        'admin_scope': 'assigned',
        'must_change_password': 1,
      };

      final user = UserModel.fromJson(json);
      expect(user.mustChangePassword, isTrue);
      expect(user.isAdmin, isFalse);
      expect(user.isStaff, isTrue);
    });

    test('UserModel correctly parses must_change_password as false', () {
      final json = {
        'id': 1,
        'full_name': 'Admin User',
        'email': 'admin@domain.com',
        'role': 'admin',
        'admin_scope': 'all',
        'must_change_password': 0,
      };

      final user = UserModel.fromJson(json);
      expect(user.mustChangePassword, isFalse);
      expect(user.isAdmin, isTrue);
    });

    test('UserModel copyWith correctly updates mustChangePassword', () {
      final user = const UserModel(
        id: 1,
        name: 'Initial',
        email: 'i@d.com',
        role: 'staff',
        adminScope: 'assigned',
        mustChangePassword: true,
      );

      final updated = user.copyWith(mustChangePassword: false);
      expect(updated.mustChangePassword, isFalse);
      expect(updated.name, equals('Initial'));
    });
  });

  group('Phase 3: Widget Rendering & Validation Tests', () {
    testWidgets('SplashScreen displays Projecta branding', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: const SplashScreen(),
        ),
      );

      // Check initial render before timer advances
      expect(find.text('PROJECTA'), findsOneWidget);
      expect(find.text('WORKDESK'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance past splash delay
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
    });

    testWidgets('LoginScreen displays Neo-Brutalist elements and inputs', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: const LoginScreen(),
        ),
      );

      expect(find.text('SIGN IN'), findsNWidgets(2)); // Heading & Button
      expect(find.text('USERNAME / EMAIL'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('PROJECTA WORKDESK'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'SIGN IN'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('MustChangePasswordScreen displays compliance reset banner and inputs', (
      tester,
    ) async {
      const user = UserModel(
        id: 5,
        name: 'Harshit',
        email: 'harshit@domain.com',
        role: 'staff',
        adminScope: 'assigned',
        mustChangePassword: true,
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: const MustChangePasswordScreen(user: user),
        ),
      );

      expect(find.text('ACTION REQUIRED: INITIAL PASSWORD RESET'), findsOneWidget);
      expect(find.text('CHANGE PASSWORD'), findsOneWidget);
      expect(find.text('CURRENT (TEMPORARY) PASSWORD'), findsOneWidget);
      expect(find.text('NEW PASSWORD (MIN. 8 CHARS)'), findsOneWidget);
      expect(find.text('CONFIRM NEW PASSWORD'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'UPDATE & PROCEED'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('MustChangePasswordScreen enforces validation rules', (
      tester,
    ) async {
      const user = UserModel(
        id: 5,
        name: 'Harshit',
        email: 'harshit@domain.com',
        role: 'staff',
        adminScope: 'assigned',
        mustChangePassword: true,
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: const MustChangePasswordScreen(user: user),
        ),
      );

      // Scroll to button and tap with empty fields
      final submitFinder = find.widgetWithText(ElevatedButton, 'UPDATE & PROCEED');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pump();

      expect(find.text('Please enter your current temporary password.'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters long.'), findsOneWidget);
    });
  });
}
