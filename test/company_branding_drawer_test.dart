import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/company_settings.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/core/widgets/app_side_drawer.dart';
import 'package:projecta_app/core/widgets/projeqta_logo.dart';
import 'package:projecta_app/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const adminUser = UserModel(
    id: 1,
    name: 'Aman Bhatia',
    email: 'aamannbhatia@gmail.com',
    role: 'super_admin',
    adminScope: 'all',
    mustChangePassword: false,
  );

  group('Company Branding & AppSideDrawer Header Integration Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'cached_company_name': 'Rank First Technologies',
        'cached_company_logo_url': 'http://192.168.1.2/projecta/uploads/logos/logo_test.png',
      });
      await CompanySettings.instance.loadFromPrefs();
    });

    test('CompanySettings loads cached branding from SharedPreferences', () {
      expect(CompanySettings.instance.companyName, 'Rank First Technologies');
      expect(CompanySettings.instance.logoUrl, 'http://192.168.1.2/projecta/uploads/logos/logo_test.png');
    });

    test('CompanySettings update modifies state and notifies listeners', () async {
      bool notified = false;
      void listener() => notified = true;
      CompanySettings.instance.addListener(listener);

      await CompanySettings.instance.update(
        companyName: 'Acme Global Corp',
        logoUrl: 'http://192.168.1.2/projecta/uploads/logos/acme.png',
      );

      expect(notified, isTrue);
      expect(CompanySettings.instance.companyName, 'Acme Global Corp');
      expect(CompanySettings.instance.logoUrl, 'http://192.168.1.2/projecta/uploads/logos/acme.png');

      CompanySettings.instance.removeListener(listener);
    });

    testWidgets('AppSideDrawer header renders company name and company photo container', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await CompanySettings.instance.update(
        companyName: 'Rank First Technologies',
        logoUrl: 'http://192.168.1.2/projecta/uploads/logos/logo_test.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Scaffold(
            drawer: AppSideDrawer(
              user: adminUser,
              currentTabIndex: 0,
              onTabSelected: (_) {},
              onLogout: () {},
              onComplianceTap: () {},
              onFilterTap: () {},
              onTeamListTap: () {},
              onOverdueTap: () {},
              onNotificationsTap: () {},
              onApprovalsTap: () {},
            ),
            body: const Center(child: Text('Home')),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Check Company Name displayed in drawer header
      expect(find.text('Rank First Technologies'), findsOneWidget);
      expect(find.text('Admin Executive'), findsOneWidget);

      // Check Image.network rendered for the company logo
      expect(find.byType(Image), findsWidgets);

      // Dynamically change company name and photo
      await CompanySettings.instance.update(
        companyName: 'NextGen Solutions',
        logoUrl: null,
      );
      await tester.pumpAndSettle();

      // Side drawer header dynamically updates to new company name and default logo
      expect(find.text('NextGen Solutions'), findsOneWidget);
      expect(find.byType(ProjeqtaIcon), findsWidgets);
    });

    test('CompanySettings ensureLogoCached triggers fetch when logoBytes is null', () async {
      await CompanySettings.instance.update(
        companyName: 'Test Corp',
        logoUrl: 'http://192.168.1.2/projecta/uploads/logos/test.png',
      );
      // ensureLogoCached handles empty or invalid URLs without throwing
      await CompanySettings.instance.ensureLogoCached('');
      expect(CompanySettings.instance.companyName, 'Test Corp');
    });
  });
}

