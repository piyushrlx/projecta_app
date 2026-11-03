import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'must_change_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'harshit');
  final _passwordController = TextEditingController(text: 'Password@123');
  final _authService = AuthService();
  final _apiClient = ApiClient();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    await _apiClient.loadSavedBaseUrl();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final UserModel user = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (user.mustChangePassword) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MustChangePasswordScreen(user: user),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(user: user),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please verify your connection.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showServerSettingsDialog() {
    final serverController = TextEditingController(text: _apiClient.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppTheme.pitchBlack, width: 2.0),
        ),
        title: Text(
          'SERVER CONFIGURATION',
          style: AppTheme.heading(
            fontSize: 16,
            color: AppTheme.pitchBlack,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the backend API Base URL:',
                style: AppTheme.body(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: serverController,
                style: AppTheme.mono(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'http://192.168.1.7/projecta/api/v1',
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Quick Presets:',
                style: AppTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.pitchBlack,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Wi-Fi (192.168.1.7)'),
                    backgroundColor: const Color(0xFFEEEEEE),
                    onPressed: () {
                      serverController.text = 'http://192.168.1.7/projecta/api/v1';
                    },
                  ),
                  ActionChip(
                    label: const Text('Emulator (10.0.2.2)'),
                    backgroundColor: const Color(0xFFEEEEEE),
                    onPressed: () {
                      serverController.text = 'http://10.0.2.2/projecta/api/v1';
                    },
                  ),
                  ActionChip(
                    label: const Text('Localhost'),
                    backgroundColor: const Color(0xFFEEEEEE),
                    onPressed: () {
                      serverController.text = 'http://localhost/projecta/api/v1';
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: AppTheme.mono(color: AppTheme.pitchBlack)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = serverController.text.trim();
              await _apiClient.setBaseUrl(newUrl);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Server URL set to: ${_apiClient.baseUrl}'),
                ),
              );
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pitchBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      color: AppTheme.violentRed,
                      child: Text(
                        'PROJECTA WORKDESK',
                        style: AppTheme.mono(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SIGN IN',
                    textAlign: TextAlign.center,
                    style: AppTheme.heading(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your employee credentials to continue',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(
                      fontSize: 13,
                      color: const Color(0xFFAAAAAA),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Neo-Brutalist Form Card
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: AppTheme.neoCardDecoration(
                      backgroundColor: AppTheme.pureWhite,
                      borderColor: AppTheme.pitchBlack,
                      shadowOffset: 6.0,
                      shadowColor: AppTheme.violentRed,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error Alert Box
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE6E6),
                              border: Border.all(
                                color: AppTheme.violentRed,
                                width: 2.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.violentRed,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTheme.mono(
                                      fontSize: 12,
                                      color: AppTheme.violentRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Username / Email Input
                        Text(
                          'USERNAME / EMAIL',
                          style: AppTheme.mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.pitchBlack,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTheme.body(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'e.g. employee or name@domain.com',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter username or email.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password Input
                        Text(
                          'PASSWORD',
                          style: AppTheme.mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.pitchBlack,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: AppTheme.body(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter your account password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.violentRed,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppTheme.pureWhite,
                                  ),
                                )
                              : Text(
                                  'SIGN IN',
                                  style: AppTheme.heading(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.pureWhite,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Host settings link
                  Center(
                    child: Column(
                      children: [
                        TextButton.icon(
                          onPressed: _showServerSettingsDialog,
                          icon: const Icon(Icons.settings, size: 16, color: AppTheme.pureWhite),
                          label: Text(
                            'CONFIGURE SERVER URL',
                            style: AppTheme.mono(
                              fontSize: 12,
                              color: AppTheme.pureWhite,
                            ),
                          ),
                        ),
                        Text(
                          _apiClient.baseUrl,
                          style: AppTheme.mono(
                            fontSize: 10,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
