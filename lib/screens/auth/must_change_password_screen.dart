import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';

class MustChangePasswordScreen extends StatefulWidget {
  final UserModel user;

  const MustChangePasswordScreen({super.key, required this.user});

  @override
  State<MustChangePasswordScreen> createState() =>
      _MustChangePasswordScreenState();
}

class _MustChangePasswordScreenState extends State<MustChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully. Welcome to Projecta!'),
        ),
      );

      final updatedUser = widget.user.copyWith(mustChangePassword: false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(user: updatedUser)),
      );
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage =
            'Failed to update password. Please check your credentials.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Security Compliance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.deepSlate),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Action Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warningBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.warningText.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_clock_outlined,
                          size: 18,
                          color: AppTheme.warningText,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Action Required: Initial Password Reset',
                            textAlign: TextAlign.center,
                            style: AppTheme.heading(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warningText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Change Password',
                    style: AppTheme.heading(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome, ${widget.user.fullName}. Your administrator requires you to set a personal secure password before accessing your workdesk.',
                    style: AppTheme.body(
                      fontSize: 14,
                      color: AppTheme.mutedSlate,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Refined Form Card
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
                        // Error Alert
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
                          const SizedBox(height: 20),
                        ],

                        // Current Temporary Password
                        Text(
                          'Current (Temporary) Password',
                          style: AppTheme.heading(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.deepSlate,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrent,
                          style: AppTheme.body(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter temporary password',
                            prefixIcon: const Icon(
                              Icons.key_outlined,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrent
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureCurrent = !_obscureCurrent;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your current temporary password.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // New Password
                        Text(
                          'New Password (min. 8 chars)',
                          style: AppTheme.heading(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.deepSlate,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          style: AppTheme.body(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter new password',
                            prefixIcon: const Icon(
                              Icons.lock_reset_outlined,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNew = !_obscureNew;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'Password must be at least 8 characters long.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Confirm New Password
                        Text(
                          'Confirm New Password',
                          style: AppTheme.heading(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.deepSlate,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          style: AppTheme.body(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Re-type new password',
                            prefixIcon: const Icon(
                              Icons.check_circle_outline,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirm = !_obscureConfirm;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Submit Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
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
                                    'Update & Proceed',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
