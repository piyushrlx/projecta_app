import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/module_app_bar.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../team/employee_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final AuthService? authService;

  const ProfileScreen({super.key, required this.user, this.authService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();

  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSavingProfile = false;
  bool _isUpdatingPassword = false;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _selectedPhotoName;
  String? _selectedPhotoPath;
  List<int>? _selectedPhotoBytes;
  bool _removePhoto = false;

  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _nameController = TextEditingController(text: _currentUser.fullName);
    _phoneController = TextEditingController(text: _currentUser.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  Future<void> _handlePickPhoto() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (result.isEmpty) return;

      final file = result.first;
      final fileLength = await file.xFile.length();
      if (fileLength > 2 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo must not exceed 2 MB.'),
              backgroundColor: AppTheme.dangerText,
            ),
          );
        }
        return;
      }

      final fileBytes = await file.xFile.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedPhotoName = file.name;
        _selectedPhotoPath = file.path;
        _selectedPhotoBytes = fileBytes;
        _removePhoto = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: AppTheme.dangerText,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);
    final scaffold = ScaffoldMessenger.of(context);

    try {
      final updated = await _authService.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoBytes: _selectedPhotoBytes,
        photoFileName: _selectedPhotoName,
        photoPath: _selectedPhotoPath,
        removePhoto: _removePhoto,
      );

      if (mounted) {
        setState(() {
          _currentUser = updated;
          _selectedPhotoName = null;
          _selectedPhotoPath = null;
          _selectedPhotoBytes = null;
          _removePhoto = false;
          _isSavingProfile = false;
        });
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
            backgroundColor: AppTheme.successText,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingProfile = false);
        scaffold.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException:', '').trim()),
            backgroundColor: AppTheme.dangerText,
          ),
        );
      }
    }
  }

  Future<void> _handleUpdatePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isUpdatingPassword = true);
    final scaffold = ScaffoldMessenger.of(context);

    try {
      await _authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully.'),
            backgroundColor: AppTheme.successText,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingPassword = false);
        scaffold.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException:', '').trim()),
            backgroundColor: AppTheme.dangerText,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: ModuleAppBar(
        title: 'My Profile',
        subtitle: _currentUser.designation?.trim().isNotEmpty == true
            ? _currentUser.designation!
            : 'Account & security',
        onBack: () => Navigator.pop(context, _currentUser),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Dossier Card matching web page-header
            _buildDossierCard(),
            const SizedBox(height: 16),

            // Profile Details Form Card matching web tab-panel profile
            _buildProfileFormCard(),
            const SizedBox(height: 16),

            // Security & Change Password Card matching web tab-panel password
            _buildSecurityCard(),
            const SizedBox(height: 16),

            // Account Details Card matching web side-card account
            _buildAccountCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDossierCard() {
    final photoUrl = _currentUser.profilePhotoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty && !_removePhoto;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.royalBlue,
                backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                child: !hasPhoto
                    ? Text(
                        _getInitials(_currentUser.fullName),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.pureWhite,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser.fullName,
                      style: AppTheme.heading(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.deepSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _currentUser.email,
                      style: AppTheme.body(
                        fontSize: 13,
                        color: AppTheme.mutedSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _currentUser.isSuperAdmin
                                ? const Color(0xFFEDE9FE)
                                : _currentUser.isAdmin
                                ? AppTheme.infoBg
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _currentUser.role
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: AppTheme.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _currentUser.isSuperAdmin
                                  ? const Color(0xFF6D28D9)
                                  : _currentUser.isAdmin
                                  ? AppTheme.royalBlue
                                  : AppTheme.mutedSlate,
                            ),
                          ),
                        ),
                        if (_currentUser.designation != null &&
                            _currentUser.designation!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _currentUser.designation!,
                              style: AppTheme.body(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.deepSlate,
                              ),
                            ),
                          ),
                        if (_currentUser.departmentName != null &&
                            _currentUser.departmentName!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(
                                color: AppTheme.borderSubtle,
                                width: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _currentUser.departmentName!,
                              style: AppTheme.body(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.mutedSlate,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentUser.isAdmin) ...[
            const SizedBox(height: 14),
            const Divider(color: AppTheme.borderSubtle, height: 1),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EmployeeDetailScreen(employeeId: _currentUser.id),
                    ),
                  );
                },
                icon: const Icon(Icons.work_outline, size: 16),
                label: const Text('My work overview'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.deepSlate,
                  side: const BorderSide(color: AppTheme.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileFormCard() {
    final hasExistingPhoto =
        _currentUser.profilePhotoUrl != null &&
        _currentUser.profilePhotoUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: AppTheme.royalBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Profile Information',
                    style: AppTheme.heading(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Full Name Field
            Text(
              'Full name *',
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.badge_outlined, size: 20),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Phone Field
            Text(
              'Phone',
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'e.g. +91 9876543210',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            // Email (Readonly)
            Text(
              'Email',
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: _currentUser.email,
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined, size: 20),
                fillColor: Color(0xFFF8FAFC),
                filled: true,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentUser.isSuperAdmin
                  ? 'Change it from the employee edit page.'
                  : 'Ask your administrator to change your email.',
              style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
            ),
            const SizedBox(height: 14),

            // Username (Readonly)
            Text(
              'Username',
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              initialValue:
                  _currentUser.username ?? _currentUser.email.split('@').first,
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.alternate_email, size: 20),
                fillColor: Color(0xFFF8FAFC),
                filled: true,
              ),
            ),
            const SizedBox(height: 18),

            // Profile Photo Upload Section (Web-parity)
            Text(
              'Profile photo',
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _handlePickPhoto,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppTheme.pureWhite,
                      side: const BorderSide(color: AppTheme.borderSubtle),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Choose File',
                      style: AppTheme.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedPhotoName != null
                          ? _selectedPhotoName!
                          : 'No file chosen',
                      style: AppTheme.body(
                        fontSize: 12,
                        color: _selectedPhotoName != null
                            ? AppTheme.deepSlate
                            : AppTheme.mutedSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedPhotoName != null)
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.mutedSlate,
                      ),
                      onPressed: () => setState(() {
                        _selectedPhotoName = null;
                        _selectedPhotoPath = null;
                        _selectedPhotoBytes = null;
                      }),
                      tooltip: 'Clear selection',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'JPG, PNG or WebP, max 2 MB.',
              style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
            ),
            if (hasExistingPhoto || _selectedPhotoName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _removePhoto,
                      activeColor: AppTheme.royalBlue,
                      onChanged: (val) {
                        setState(() {
                          _removePhoto = val ?? false;
                          if (_removePhoto) {
                            _selectedPhotoName = null;
                            _selectedPhotoPath = null;
                            _selectedPhotoBytes = null;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _removePhoto = !_removePhoto;
                          if (_removePhoto) {
                            _selectedPhotoName = null;
                            _selectedPhotoPath = null;
                            _selectedPhotoBytes = null;
                          }
                        });
                      },
                      child: Text(
                        'Remove current photo',
                        style: AppTheme.body(
                          fontSize: 12,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Save Profile Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: BrutalistPressable(
                onTap: _isSavingProfile ? null : _handleSaveProfile,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.royalBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _isSavingProfile
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.pureWhite,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          semanticsLabel: 'Save profile',
                          style: AppTheme.heading(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: AppTheme.navyBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Change Password',
                    style: AppTheme.heading(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Current Password
            Text(
              'Current Password *',
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                hintText: 'Enter current password',
                prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppTheme.mutedSlate,
                  ),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter your current password';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // New Password
            Text(
              'New Password (min. 8 characters)',
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                hintText: 'Enter new password',
                prefixIcon: const Icon(Icons.lock_reset, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppTheme.mutedSlate,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter a new password';
                }
                if (val.length < 8) {
                  return 'Password must be at least 8 characters long';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Confirm Password
            Text(
              'Confirm New Password',
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                hintText: 'Confirm new password',
                prefixIcon: const Icon(Icons.lock_reset, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppTheme.mutedSlate,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please confirm your new password';
                }
                if (val != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Update Password Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: BrutalistPressable(
                onTap: _isUpdatingPassword ? null : _handleUpdatePassword,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.navyBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _isUpdatingPassword
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.pureWhite,
                          ),
                        )
                      : Text(
                          'Update Password',
                          style: AppTheme.heading(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_box_outlined,
                color: AppTheme.deepSlate,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Account',
                style: AppTheme.heading(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAccountRow('Employee code', _currentUser.employeeCode ?? '—'),
          _buildAccountRowWithWidget(
            'Role',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _currentUser.isSuperAdmin
                    ? const Color(0xFFEDE9FE)
                    : _currentUser.isAdmin
                    ? AppTheme.infoBg
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _currentUser.role == 'super_admin'
                    ? 'Super Admin'
                    : _currentUser.role == 'admin'
                    ? 'Admin / Manager'
                    : 'Staff',
                style: AppTheme.body(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _currentUser.isSuperAdmin
                      ? const Color(0xFF6D28D9)
                      : _currentUser.isAdmin
                      ? AppTheme.royalBlue
                      : AppTheme.mutedSlate,
                ),
              ),
            ),
          ),
          _buildAccountRow('Department', _currentUser.departmentName ?? '—'),
          _buildAccountRow(
            'Reports to',
            _currentUser.reportingManagerName ?? '—',
          ),
          _buildAccountRow('Joining date', _currentUser.joiningDate ?? '—'),
          _buildAccountRow(
            'Daily report',
            _currentUser.reportingRequired
                ? 'Required by 07:00 PM'
                : 'Not required',
          ),
          _buildAccountRow('Last login', _currentUser.lastLoginAt ?? 'Never'),
        ],
      ),
    );
  }

  Widget _buildAccountRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTheme.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountRowWithWidget(String label, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}
