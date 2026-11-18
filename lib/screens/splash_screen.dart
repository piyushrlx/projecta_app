import 'dart:async';
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
  Timer? _bootTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Yield back to the Android Looper so WindowManager grants focus to
      // MainActivity before checking session and pushing DashboardScreen.
      _bootTimer = Timer(const Duration(milliseconds: 550), () {
        if (mounted) {
          _checkSession();
        }
      });
    });
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkSession() async {
    await _apiClient.loadSavedBaseUrl();

    try {
      final token = await _apiClient.getToken();
      if (token != null && token.isNotEmpty) {
        UserModel? user;
        try {
          user = await _authService.getMe();
        } on ApiException catch (e) {
          if (e.statusCode == 401 || e.statusCode == 403) {
            // Authentication explicitly rejected by server
            await _apiClient.clearToken();
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
            return;
          }
          // On network failure or offline, retrieve cached user profile
          user = await _authService.getCurrentUser();
        } catch (_) {
          user = await _authService.getCurrentUser();
        }

        if (user != null) {
          if (!mounted) return;
          if (user.mustChangePassword) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MustChangePasswordScreen(user: user!),
              ),
            );
            return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DashboardScreen(user: user!)),
          );
          return;
        }
      }
    } catch (_) {
      // General failure fallback
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
      backgroundColor: AppTheme.scaffoldBg, // Deep Midnight Navy #0B0F29
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
                  isDark: false,
                  spacing: 14,
                ),
                const SizedBox(height: 32),
                Text(
                  'Know what your team did today.',
                  textAlign: TextAlign.center,
                  style: AppTheme.heading(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
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
                    color: AppTheme.mutedSlate,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.electricBlue,
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
