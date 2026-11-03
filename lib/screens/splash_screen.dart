import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
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
          MaterialPageRoute(
            builder: (_) => DashboardScreen(user: user),
          ),
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
      backgroundColor: AppTheme.pitchBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Neo-Brutalist Logo Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.pitchBlack,
                border: Border.all(color: AppTheme.pureWhite, width: 3.0),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.violentRed,
                    offset: Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'PROJECTA',
                    style: AppTheme.heading(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    color: AppTheme.violentRed,
                    child: Text(
                      'WORKDESK',
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.pureWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.violentRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

