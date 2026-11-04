import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().loadSavedBaseUrl();
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
