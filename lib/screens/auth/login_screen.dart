import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets/projeqta_logo.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'must_change_password_screen.dart';
import 'register_screen.dart';

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
          MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'An unexpected error occurred. Please verify your connection.';
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
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.infoBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.dns_outlined,
                color: AppTheme.navyBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Server Configuration',
              style: AppTheme.heading(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepSlate,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the backend API base endpoint URL:',
                style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: serverController,
                style: AppTheme.mono(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'http://${ApiClient.defaultLanIp}/projecta/api/v1',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick Presets',
                style: AppTheme.heading(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.deepSlate,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _presetChip(
                    'USB (localhost:8080)',
                    'http://localhost:8080/projecta/api/v1',
                    serverController,
                  ),
                  _presetChip(
                    'Wi-Fi (${ApiClient.defaultLanIp})',
                    'http://${ApiClient.defaultLanIp}/projecta/api/v1',
                    serverController,
                  ),
                  _presetChip(
                    'Emulator (10.0.2.2)',
                    'http://10.0.2.2/projecta/api/v1',
                    serverController,
                  ),
                  _presetChip(
                    'Localhost',
                    'http://localhost/projecta/api/v1',
                    serverController,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTheme.heading(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedSlate,
              ),
            ),
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
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(
    String label,
    String url,
    TextEditingController controller,
  ) {
    return InkWell(
      onTap: () => controller.text = url,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.scaffoldBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Text(
          label,
          style: AppTheme.body(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.deepSlate,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Official projeqta brand header
                      const Center(
                        child: ProjeqtaLogo(
                          iconSize: 42,
                          fontSize: 28,
                          spacing: 10,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Know what your team did today.',
                        textAlign: TextAlign.center,
                        style: AppTheme.heading(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepSlate,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Projects, tasks and daily reports — reviewed in one place.',
                        textAlign: TextAlign.center,
                        style: AppTheme.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.mutedSlate,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Refined White Card (16px rounded corners, 1px #E2E8F0 border, soft shadow)
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.borderSubtle,
                            width: 1.0,
                          ),
                          boxShadow: const [AppTheme.softShadow],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Error Alert Box
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.dangerBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.dangerText.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.error_outline,
                                            color: AppTheme.dangerText,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: AppTheme.body(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.dangerText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: InkWell(
                                        onTap: _showServerSettingsDialog,
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.settings_outlined,
                                                size: 15,
                                                color: AppTheme.royalBlue,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Configure Server',
                                                style: AppTheme.heading(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.royalBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Username or Email Input
                            Text(
                              'Username or Email',
                              style: AppTheme.heading(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.deepSlate,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTheme.body(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'e.g. employee or name@company.com',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  size: 20,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter username or email.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password Header with Label & Forgot Password Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Password',
                                  style: AppTheme.heading(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.deepSlate,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ForgotPasswordScreen(
                                          initialEmail:
                                              _usernameController.text.contains(
                                                '@',
                                              )
                                              ? _usernameController.text.trim()
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Forgot password?',
                                    style: AppTheme.body(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.royalBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: AppTheme.body(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
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

                            // Full-width 52px-tall Executive Navy Blue button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.navyBlue,
                                  foregroundColor: AppTheme.pureWhite,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppTheme.pureWhite,
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: AppTheme.heading(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.pureWhite,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer: New here? Create a free admin account
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'New here? ',
                            style: AppTheme.body(
                              fontSize: 14,
                              color: AppTheme.mutedSlate,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final registeredEmail =
                                  await Navigator.push<String>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                              if (registeredEmail != null &&
                                  registeredEmail.isNotEmpty &&
                                  mounted) {
                                setState(() {
                                  _usernameController.text = registeredEmail;
                                  _passwordController.clear();
                                });
                              }
                            },
                            child: Text(
                              'Create a free admin account',
                              style: AppTheme.heading(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.royalBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top-right Server Settings icon button (placed AFTER SingleChildScrollView to ensure top z-index and reliable tap gestures)
            Positioned(
              top: 12,
              right: 16,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.hardEdge,
                child: IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppTheme.mutedSlate,
                    size: 22,
                  ),
                  tooltip: 'Configure Server URL',
                  onPressed: _showServerSettingsDialog,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
