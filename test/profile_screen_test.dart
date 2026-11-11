import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:projecta_app/screens/profile/profile_screen.dart';
import 'package:projecta_app/services/auth_service.dart';

class FakeAuthService extends AuthService {
  FakeAuthService() : super.forTesting();

  String? lastUpdatedName;
  String? lastUpdatedPhone;
  bool? lastRemovePhoto;
  String? lastCurrentPassword;
  String? lastNewPassword;
  bool shouldFailUpdate = false;
  bool shouldFailPassword = false;

  @override
  Future<UserModel> updateProfile({
    required String fullName,
    String? phone,
    List<int>? photoBytes,
    String? photoFileName,
    String? photoPath,
    bool removePhoto = false,
  }) async {
    if (shouldFailUpdate) {
      throw Exception('Server error updating profile');
    }
    lastUpdatedName = fullName;
    lastUpdatedPhone = phone;
    lastRemovePhoto = removePhoto;
    return UserModel(
      id: 1,
      name: fullName,
      email: 'aamannbhatia@gmail.com',
      role: 'super_admin',
      adminScope: 'all',
      mustChangePassword: false,
      phone: phone,
      departmentName: 'Executive',
      employeeCode: 'EMP-0001',
      designation: 'Director',
      joiningDate: '29 Oct 2026',
      reportingRequired: false,
      lastLoginAt: '11 Nov 2026, 15:05',
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (shouldFailPassword) {
      throw Exception('Current password incorrect');
    }
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
  }
}

void main() {
  const testUser = UserModel(
    id: 1,
    name: 'Aman Bhatia',
    email: 'aamannbhatia@gmail.com',
    role: 'super_admin',
    adminScope: 'all',
    mustChangePassword: false,
    phone: '+91 9876543210',
    departmentName: 'Executive',
    employeeCode: 'EMP-0001',
    designation: 'Director',
    joiningDate: '29 Oct 2026',
    reportingRequired: false,
    lastLoginAt: '11 Nov 2026, 15:05',
  );

  Widget createTestWidget({FakeAuthService? authService, UserModel? user}) {
    return MaterialApp(
      theme: AppTheme.themeData,
      home: ProfileScreen(
        user: user ?? testUser,
        authService: authService ?? FakeAuthService(),
      ),
    );
  }

  group('Phase 1: ProfileScreen Widget & Interaction Tests', () {
    testWidgets(
      'Renders user dossier, photo section, and account metadata card',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('My Profile'), findsOneWidget);
        expect(find.text('Aman Bhatia'), findsNWidgets(2)); // Dossier + Form
        expect(
          find.text('aamannbhatia@gmail.com'),
          findsNWidgets(2),
        ); // Dossier + Field
        expect(find.text('SUPER ADMIN'), findsOneWidget);
        expect(
          find.text('Executive'),
          findsNWidgets(2),
        ); // Dossier tag + Account card
        expect(find.text('Profile Information'), findsOneWidget);
        expect(find.text('Profile photo'), findsOneWidget);
        expect(find.text('Choose File'), findsOneWidget);
        expect(find.text('No file chosen'), findsOneWidget);
        expect(find.text('JPG, PNG or WebP, max 2 MB.'), findsOneWidget);
        expect(find.text('Change Password'), findsOneWidget);
        expect(find.text('Save Changes'), findsOneWidget);
        expect(find.text('Update Password'), findsOneWidget);

        // Account Card Parity Assertions
        expect(find.text('Account'), findsOneWidget);
        expect(find.text('Employee code'), findsOneWidget);
        expect(find.text('EMP-0001'), findsOneWidget);
        expect(find.text('Role'), findsOneWidget);
        expect(find.text('Super Admin'), findsOneWidget);
        expect(find.text('Department'), findsOneWidget);
        expect(find.text('Reports to'), findsOneWidget);
        expect(find.text('Joining date'), findsOneWidget);
        expect(find.text('29 Oct 2026'), findsOneWidget);
        expect(find.text('Daily report'), findsOneWidget);
        expect(find.text('Not required'), findsOneWidget);
        expect(find.text('Last login'), findsOneWidget);
        expect(find.text('11 Nov 2026, 15:05'), findsOneWidget);
      },
    );

    testWidgets('Validates empty name when saving profile', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Clear the name input
      final nameField = find.widgetWithText(TextFormField, 'Aman Bhatia');
      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name'), findsOneWidget);
    });

    testWidgets('Submits profile update and renders success snackbar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeAuth = FakeAuthService();
      await tester.pumpWidget(createTestWidget(authService: fakeAuth));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Aman Bhatia');
      await tester.enterText(nameField, 'Aman Bhatia (Updated)');

      final phoneField = find.widgetWithText(TextFormField, '+91 9876543210');
      await tester.enterText(phoneField, '+91 9999999999');

      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(fakeAuth.lastUpdatedName, equals('Aman Bhatia (Updated)'));
      expect(fakeAuth.lastUpdatedPhone, equals('+91 9999999999'));
      expect(find.text('Profile updated successfully.'), findsOneWidget);
    });

    testWidgets('Validates password constraints (empty, short, mismatch)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Update Password with empty inputs
      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your current password'), findsOneWidget);

      // Enter current password but short new password
      final fields = find.byType(TextFormField);
      final total = tester.widgetList(fields).length;
      final currentField = fields.at(total - 3);
      final newField = fields.at(total - 2);
      final confirmField = fields.at(total - 1);
      await tester.enterText(currentField, 'oldPass123');
      await tester.enterText(newField, 'short');
      await tester.enterText(confirmField, 'short');

      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters long'),
        findsOneWidget,
      );

      // Enter mismatched confirm password
      await tester.enterText(newField, 'validPassword123');
      await tester.enterText(confirmField, 'differentPassword123');

      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Submits password update successfully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeAuth = FakeAuthService();
      await tester.pumpWidget(createTestWidget(authService: fakeAuth));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      final total = tester.widgetList(fields).length;
      final currentField = fields.at(total - 3);
      final newField = fields.at(total - 2);
      final confirmField = fields.at(total - 1);

      await tester.enterText(currentField, 'oldPass123');
      await tester.enterText(newField, 'newSecretPassword123');
      await tester.enterText(confirmField, 'newSecretPassword123');

      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(fakeAuth.lastCurrentPassword, equals('oldPass123'));
      expect(fakeAuth.lastNewPassword, equals('newSecretPassword123'));
      expect(find.text('Password updated successfully.'), findsOneWidget);
    });
  });
}
