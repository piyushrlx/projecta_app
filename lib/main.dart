import 'dart:async';
import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'core/async_server_discovery.dart';
import 'core/company_settings.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().loadSavedBaseUrl();
  await CompanySettings.instance.loadFromPrefs();
  // Asynchronously discover fastest server and fetch company branding in background
  unawaited(AsyncServerDiscovery.probeAndSelectFastest());
  unawaited(CompanySettings.instance.fetchFromApi());
  runApp(const ProjeqtaApp());
}

class ProjeqtaApp extends StatelessWidget {
  const ProjeqtaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'projeqta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const SplashScreen(),
    );
  }
}
