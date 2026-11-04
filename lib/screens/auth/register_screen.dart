import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets/projeqta_logo.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _authService.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final bool autoApproved = res['auto_approved'] == true;
      final String message =
          res['message']?.toString() ??
          (autoApproved
              ? 'Your account has been created successfully!'
              : 'Registration submitted. Your account is waiting for approval.');

      if (autoApproved && _authService.currentUser != null) {
        // User was automatically approved & logged in
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.successText,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(user: _authService.currentUser!),
          ),
          (route) => false,
        );
      } else {
        // Show success alert and navigate back to sign in
        await showDialog(
          context: context,
          barrierDismissible: false,
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
                    color: AppTheme.successBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.successText,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Account Created',
                  style: AppTheme.heading(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: AppTheme.body(fontSize: 14, color: AppTheme.mutedSlate),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, _emailController.text.trim());
                },
                child: const Text('Go to Sign In'),
              ),
            ],
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage =
            'An unexpected error occurred during registration. Please verify connection.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showTermsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Terms of Service',
                style: AppTheme.heading(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Workspace & Accounts:\nA workspace is created by the person who registers; that person becomes its Admin. The Admin is responsible for managing projects, adding employees, and assigning tasks.\n\n'
                '2. Acceptable Use:\nYou agree to use projeqta solely for legitimate enterprise reporting, daily task management, and project coordination.\n\n'
                '3. Data & Privacy:\nYour workspace data belongs to your organization and is handled in strict compliance with applicable data privacy practices.',
                style: AppTheme.body(
                  fontSize: 14,
                  color: AppTheme.mutedSlate,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Privacy Policy',
                style: AppTheme.heading(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Information Collected:\nWe collect name, work email, and authentication details required to establish your admin profile.\n\n'
                '2. Purpose of Use:\nYour information is used strictly to provide workspace management, report aggregation, task assignments, and security notifications.\n\n'
                '3. Security:\nPasswords are cryptographically hashed and tokens are securely managed. We do not sell or share your workspace information with third-party advertisers.',
                style: AppTheme.body(
                  fontSize: 14,
                  color: AppTheme.mutedSlate,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.deepSlate),
          tooltip: 'Back to Sign In',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header
                  const Center(
                    child: ProjeqtaLogo(
                      iconSize: 40,
                      fontSize: 26,
                      spacing: 10,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title & Subtitle
                  Text(
                    'Create your admin account',
                    textAlign: TextAlign.center,
                    style: AppTheme.heading(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Free, no card needed. You'll add employees after signing in.",
                    textAlign: TextAlign.center,
                    style: AppTheme.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.mutedSlate,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card Form Container
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
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.dangerText,
                                  size: 18,
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
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Your name Field
                        Text(
                          'Your name',
                          style: AppTheme.heading(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.deepSlate,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          style: AppTheme.body(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name.';
                            }
                            if (value.trim().length > 150) {
                              return 'Name must not exceed 150 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Work email Field
                        Text(
                          'Work email',
                          style: AppTheme.heading(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.deepSlate,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: AppTheme.body(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'name@company.com',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your work email.';
                            }
                            final emailRegex = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            );
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Please enter a valid work email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Password Field
                        Text(
                          'Password',
                          style: AppTheme.heading(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.deepSlate,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleRegister(),
                          style: AppTheme.body(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Create a secure password',
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
                              return 'Please enter a password.';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters.';
                            }
                            final hasLetter = RegExp(
                              r'[a-zA-Z]',
                            ).hasMatch(value);
                            final hasDigit = RegExp(r'[0-9]').hasMatch(value);
                            if (!hasLetter || !hasDigit) {
                              return 'Password must contain both letters and numbers.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'At least 8 characters with letters and numbers.',
                          style: AppTheme.body(
                            fontSize: 12,
                            color: AppTheme.lightSlate,
                          ),
                        ),
                        const SizedBox(height: 26),

                        // Create Account Button (Royal Blue)
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.royalBlue,
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
                                    'Create account',
                                    style: AppTheme.heading(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.pureWhite,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Terms and Privacy Legal Text
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'By creating an account you agree to the ',
                              style: AppTheme.body(
                                fontSize: 12,
                                color: AppTheme.mutedSlate,
                              ),
                            ),
                            GestureDetector(
                              onTap: _showTermsDialog,
                              child: Text(
                                'Terms of service',
                                style: AppTheme.body(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.royalBlue,
                                ),
                              ),
                            ),
                            Text(
                              ' and ',
                              style: AppTheme.body(
                                fontSize: 12,
                                color: AppTheme.mutedSlate,
                              ),
                            ),
                            GestureDetector(
                              onTap: _showPrivacyPolicyDialog,
                              child: Text(
                                'Privacy policy',
                                style: AppTheme.body(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.royalBlue,
                                ),
                              ),
                            ),
                            Text(
                              '.',
                              style: AppTheme.body(
                                fontSize: 12,
                                color: AppTheme.mutedSlate,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer: Already have an account? Sign in
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTheme.body(
                          fontSize: 14,
                          color: AppTheme.mutedSlate,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Sign in',
                          style: AppTheme.heading(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.royalBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
