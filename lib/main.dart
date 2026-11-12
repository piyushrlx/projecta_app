import 'dart:async';
import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'core/async_server_discovery.dart';
import 'core/company_settings.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

final ValueNotifier<int> _themeEpoch = ValueNotifier<int>(0);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppTheme.setDeferGoogleFonts(true);
  runApp(const ProjeqtaApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Allow MainActivity's first frame, window focus, and starting-window
    // removal to complete before loading GoogleFonts and background services.
    Future<void>.delayed(const Duration(milliseconds: 520), () {
      AppTheme.setDeferGoogleFonts(false);
      _themeEpoch.value++;
      unawaited(_initAppServices());
    });
  });
}

Future<void> _initAppServices() async {
  await ApiClient().loadSavedBaseUrl();
  await CompanySettings.instance.loadFromPrefs();
  // Defer background network probes slightly past the first Dashboard frame.
  await Future<void>.delayed(const Duration(milliseconds: 400));
  unawaited(AsyncServerDiscovery.probeAndSelectFastest());
  unawaited(CompanySettings.instance.fetchFromApi());
}

class ProjeqtaApp extends StatelessWidget {
  const ProjeqtaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _themeEpoch,
      builder: (context, _, _) {
        return MaterialApp(
          title: 'projeqta',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          home: const SplashScreen(),
        );
      },
    );
  }
}
