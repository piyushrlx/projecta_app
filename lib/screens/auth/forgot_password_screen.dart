import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets/projeqta_logo.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  String? _successMessage;
  String? _devLink;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _devLink = null;
    });

    try {
      final res = await _authService.requestPasswordReset(_emailController.text.trim());
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _successMessage = res['message'] ??
            'If an account exists for that email, a reset link has been sent.';
        if (res['dev_link'] != null) {
          _devLink = res['dev_link'].toString();
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo at the top
                  const Center(
                    child: ProjeqtaLogo(iconSize: 42, fontSize: 32),
                  ),
                  const SizedBox(height: 36),

                  // Title matching user's reference image
                  Text(
                    'Reset your password',
                    style: AppTheme.heading(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle matching user's reference image
                  Text(
                    'Enter your email and we\'ll send a one-time link (valid for 60 minutes).',
                    style: AppTheme.body(
                      fontSize: 14,
                      color: AppTheme.mutedSlate,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error notification banner if any
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.dangerText.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.dangerText, size: 18),
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
                    const SizedBox(height: 20),
                  ],

                  // Success notification banner
                  if (_isSuccess) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.successBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.successText.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppTheme.successText, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _successMessage ?? 'Reset instructions sent.',
                                  style: AppTheme.body(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.successText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_devLink != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Dev Mode Link: $_devLink',
                              style: AppTheme.body(
                                fontSize: 11,
                                color: AppTheme.deepSlate,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    // Form with Email input
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
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
                            autofocus: true,
                            style: AppTheme.body(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.mail_outline, size: 20),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your email address.';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Send reset link button
                          SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleResetRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.royalBlue,
                                foregroundColor: AppTheme.pureWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: AppTheme.pureWhite,
                                      ),
                                    )
                                  : Text(
                                      'Send reset link',
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
                    const SizedBox(height: 20),
                  ],

                  // Back to sign in link
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                      ),
                      child: Text(
                        '← Back to sign in',
                        style: AppTheme.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.royalBlue,
                        ),
                      ),
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
