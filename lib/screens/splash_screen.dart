import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets/projeqta_logo.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'auth/must_change_password_screen.dart';
import 'dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await _apiClient.loadSavedBaseUrl();
    // Artificial small delay for logo presentation
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final token = await _apiClient.getToken();
      if (token != null && token.isNotEmpty) {
        final UserModel user = await _authService.getMe();
        if (!mounted) return;

        if (user.mustChangePassword) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MustChangePasswordScreen(user: user),
            ),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
        );
        return;
      }
    } catch (_) {
      // Invalid/expired token or connection issue on splash
      await _apiClient.clearToken();
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Brand dark background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Official projeqta brand logo
                const ProjeqtaLogo(
                  iconSize: 52,
                  fontSize: 34,
                  isDark: true,
                  spacing: 14,
                ),
                const SizedBox(height: 32),
                Text(
                  'Know what your team did today.',
                  textAlign: TextAlign.center,
                  style: AppTheme.heading(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Projects, tasks and a one-minute daily report from every employee — reviewed by you, in one place.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
