import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/auth/login_screen.dart';
import 'package:projecta_app/screens/auth/must_change_password_screen.dart';
import 'package:projecta_app/screens/auth/register_screen.dart';
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
    testWidgets('SplashScreen displays projeqta branding and copy', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.themeData, home: const SplashScreen()),
      );

      // Check initial render before timer advances
      expect(find.text('projeqta'), findsOneWidget);
      expect(find.text('Know what your team did today.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance past splash delay
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'LoginScreen displays Enterprise elements, branding, and inputs',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.themeData, home: const LoginScreen()),
        );

        expect(find.text('projeqta'), findsOneWidget);
        expect(find.text('WORKFORCE SYNC 2.4'), findsOneWidget);
        expect(find.text('Know what your team did today.'), findsOneWidget);
        expect(
          find.text(
            'Projects, tasks and daily reports — reviewed in one place.',
          ),
          findsOneWidget,
        );
        expect(find.text('Username or Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
        expect(find.text('Create a free admin account'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'MustChangePasswordScreen displays compliance reset banner and inputs',
      (tester) async {
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

        expect(
          find.text('Action Required: Initial Password Reset'),
          findsOneWidget,
        );
        expect(find.text('Change Password'), findsOneWidget);
        expect(find.text('Current (Temporary) Password'), findsOneWidget);
        expect(find.text('New Password (min. 8 chars)'), findsOneWidget);
        expect(find.text('Confirm New Password'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Update & Proceed'),
          findsOneWidget,
        );
        expect(find.byType(TextFormField), findsNWidgets(3));
      },
    );

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
      final submitFinder = find.widgetWithText(
        ElevatedButton,
        'Update & Proceed',
      );
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pump();

      expect(
        find.text('Please enter your current temporary password.'),
        findsOneWidget,
      );
      expect(
        find.text('Password must be at least 8 characters long.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'LoginScreen displays New here footer and navigates to RegisterScreen',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.themeData, home: const LoginScreen()),
        );

        final createAccountLink = find.text('Create a free admin account');
        expect(createAccountLink, findsOneWidget);
        expect(find.text('New here? '), findsOneWidget);

        await tester.ensureVisible(createAccountLink);
        await tester.tap(createAccountLink);
        await tester.pumpAndSettle();

        // Should now be on RegisterScreen
        expect(find.text('Create your admin account'), findsOneWidget);
        expect(
          find.text(
            "Free, no card needed. You'll add employees after signing in.",
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'RegisterScreen displays elements, enforces validation, and excludes back to website',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.themeData, home: const RegisterScreen()),
        );

        // Core UI elements
        expect(find.text('Create your admin account'), findsOneWidget);
        expect(
          find.text(
            "Free, no card needed. You'll add employees after signing in.",
          ),
          findsOneWidget,
        );
        expect(find.text('Your name'), findsOneWidget);
        expect(find.text('Work email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(
          find.text('At least 8 characters with letters and numbers.'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ElevatedButton, 'Create account'),
          findsOneWidget,
        );
        expect(find.text('Terms of service'), findsOneWidget);
        expect(find.text('Privacy policy'), findsOneWidget);
        expect(find.text('Already have an account? '), findsOneWidget);
        expect(find.text('Sign in'), findsOneWidget);

        // Explicit user requirement: "Back to website" MUST NOT be present
        expect(find.textContaining('Back to website'), findsNothing);

        // Test form validation upon tapping "Create account" with empty fields
        final submitButton = find.widgetWithText(
          ElevatedButton,
          'Create account',
        );
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pump();

        expect(find.text('Please enter your name.'), findsOneWidget);
        expect(find.text('Please enter your work email.'), findsOneWidget);
        expect(find.text('Please enter a password.'), findsOneWidget);

        // Test Terms of Service modal opening
        final termsLink = find.text('Terms of service');
        await tester.ensureVisible(termsLink);
        await tester.tap(termsLink);
        await tester.pumpAndSettle();

        expect(find.text('Terms of Service'), findsOneWidget);
        expect(find.textContaining('Workspace & Accounts'), findsOneWidget);
        final closeBtn = find.widgetWithText(ElevatedButton, 'Close');
        await tester.tap(closeBtn);
        await tester.pumpAndSettle();

        // Test Privacy Policy modal opening
        final privacyLink = find.text('Privacy policy');
        await tester.ensureVisible(privacyLink);
        await tester.tap(privacyLink);
        await tester.pumpAndSettle();

        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.textContaining('Information Collected'), findsOneWidget);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Close'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'RegisterScreen navigation: Sign in returns to LoginScreen with prefill capability',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.themeData, home: const LoginScreen()),
        );

        // Open Register Screen
        final createAccountLink = find.text('Create a free admin account');
        await tester.ensureVisible(createAccountLink);
        await tester.tap(createAccountLink);
        await tester.pumpAndSettle();

        expect(find.text('Create your admin account'), findsOneWidget);

        // Tap "Sign in" link
        final signInLink = find.text('Sign in');
        await tester.ensureVisible(signInLink);
        await tester.tap(signInLink);
        await tester.pumpAndSettle();

        // Verify returned to Login Screen
        expect(find.text('Know what your team did today.'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
      },
    );

    testWidgets('RegisterScreen password visibility toggle works correctly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.themeData, home: const RegisterScreen()),
      );

      // Initially password is obscured and shows visibility toggle icon
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap eye toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Icon should switch to visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
