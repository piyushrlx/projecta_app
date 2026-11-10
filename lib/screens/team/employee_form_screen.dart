import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/employee_detail_model.dart';
import '../../services/directory_service.dart';

class EmployeeFormScreen extends StatefulWidget {
  final int? employeeId;
  final DirectoryService? directoryService;

  const EmployeeFormScreen({
    super.key,
    this.employeeId,
    this.directoryService,
  });

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  late final DirectoryService _directoryService =
      widget.directoryService ?? DirectoryService();

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _designationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  int? _selectedDepartmentId;
  int? _selectedManagerId;
  String _selectedRole = 'staff';
  String _selectedScope = 'assigned';
  String _selectedStatus = 'active';
  String? _joiningDate;
  bool _reportingRequired = true;
  bool _mustChangePassword = false;
  List<int> _workingDays = [1, 2, 3, 4, 5];

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isInitLoading = true;
  String? _initError;

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _managers = [];

  bool get _isEdit => widget.employeeId != null && widget.employeeId! > 0;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _employeeCodeController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isInitLoading = true;
      _initError = null;
    });

    try {
      final depts = await _directoryService.getDepartments();
      final emps = await _directoryService.getEmployees();

      EmployeeDetailModel? existing;
      if (_isEdit) {
        existing = await _directoryService.getEmployeeDetail(widget.employeeId!);
      }

      if (mounted) {
        setState(() {
          _departments = depts;
          _managers = emps;

          if (existing != null) {
            _fullNameController.text = existing.fullName;
            _emailController.text = existing.email;
            _usernameController.text = existing.username;
            _employeeCodeController.text = existing.employeeCode ?? '';
            _phoneController.text = existing.phone ?? '';
            _designationController.text = existing.designation ?? '';
            _selectedDepartmentId = existing.departmentId;
            _selectedManagerId = existing.reportingManagerId;
            _selectedRole = existing.role;
            _selectedScope = existing.adminScope;
            _selectedStatus = existing.status;
            _joiningDate = existing.joiningDate;
            _reportingRequired = existing.reportingRequired;
            _mustChangePassword = existing.mustChangePassword;
            _workingDays = List.from(existing.workingDays);
          } else {
            // Default generated username prefix
            _workingDays = [1, 2, 3, 4, 5];
            _mustChangePassword = true;
          }

          _isInitLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = e.toString().replaceAll('ApiException:', '').trim();
          _isInitLoading = false;
        });
      }
    }
  }

  Future<void> _selectJoiningDate() async {
    final now = DateTime.now();
    DateTime initial = now;
    if (_joiningDate != null) {
      final parsed = DateTime.tryParse(_joiningDate!);
      if (parsed != null) initial = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.navyBlue,
            onPrimary: AppTheme.pureWhite,
            surface: AppTheme.pureWhite,
            onSurface: AppTheme.deepSlate,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _joiningDate =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _toggleWorkingDay(int day) {
    setState(() {
      if (_workingDays.contains(day)) {
        if (_workingDays.length > 1) {
          _workingDays.remove(day);
        }
      } else {
        _workingDays.add(day);
        _workingDays.sort();
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEdit && _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password is required for new accounts.'),
          backgroundColor: AppTheme.dangerText,
        ),
      );
      return;
    }

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppTheme.dangerText,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      if (_isEdit) 'id': widget.employeeId,
      'full_name': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'username': _usernameController.text.trim(),
      if (_employeeCodeController.text.trim().isNotEmpty)
        'employee_code': _employeeCodeController.text.trim(),
      if (_phoneController.text.trim().isNotEmpty)
        'phone': _phoneController.text.trim(),
      if (_designationController.text.trim().isNotEmpty)
        'designation': _designationController.text.trim(),
      if (_selectedDepartmentId != null)
        'department_id': _selectedDepartmentId,
      if (_selectedManagerId != null)
        'reporting_manager_id': _selectedManagerId,
      if (_joiningDate != null)
        'joining_date': _joiningDate,
      'role': _selectedRole,
      'admin_scope': _selectedScope,
      'status': _selectedStatus,
      'working_days': _workingDays.join(','),
      'reporting_required': _reportingRequired ? 1 : 0,
      'must_change_password': _mustChangePassword ? 1 : 0,
      if (_passwordController.text.isNotEmpty)
        'password': _passwordController.text,
      if (_passwordConfirmController.text.isNotEmpty)
        'password_confirm': _passwordConfirmController.text,
    };

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final res = await _directoryService.saveEmployee(payload);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Employee saved successfully.'),
            backgroundColor: AppTheme.successText,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        scaffoldMessenger.showSnackBar(
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.pureWhite,
            border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: AppTheme.deepSlate),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Employee' : 'Add New Employee',
                      style: AppTheme.heading(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ),
                  if (!_isInitLoading && _initError == null)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.pureWhite,
                              ),
                            )
                          : const Text('Save'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isInitLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.navyBlue))
          : _initError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.dangerText, size: 40),
                    const SizedBox(height: 12),
                    Text(_initError!, textAlign: TextAlign.center, style: AppTheme.body(color: AppTheme.mutedSlate)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadFormData,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyBlue),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader('Basic Details'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name *',
                      hint: 'e.g. John Doe',
                      validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _emailController,
                            label: 'Email Address *',
                            hint: 'john@projeqta.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email is required';
                              if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _usernameController,
                            label: 'Username *',
                            hint: 'johndoe',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Username required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _employeeCodeController,
                            label: 'Employee Code',
                            hint: 'EMP-0012',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _phoneController,
                            label: 'Phone',
                            hint: '+91 9876543210',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _designationController,
                      label: 'Designation / Title',
                      hint: 'e.g. Senior Software Engineer',
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Organization & Hierarchy'),
                    const SizedBox(height: 12),
                    _buildDepartmentDropdown(),
                    const SizedBox(height: 12),
                    _buildManagerDropdown(),
                    const SizedBox(height: 12),
                    _buildJoiningDatePicker(),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Access & Roles'),
                    const SizedBox(height: 12),
                    _buildRoleSelector(),
                    if (_selectedRole == 'admin') ...[
                      const SizedBox(height: 12),
                      _buildAdminScopeSelector(),
                    ],
                    const SizedBox(height: 12),
                    _buildStatusSelector(),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Reporting & Work Schedule'),
                    const SizedBox(height: 12),
                    _buildWorkingDaysPicker(),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Reporting Required',
                        style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.deepSlate),
                      ),
                      subtitle: Text(
                        'User must file daily compliance work reports',
                        style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
                      ),
                      value: _reportingRequired,
                      activeColor: AppTheme.navyBlue,
                      onChanged: (val) => setState(() => _reportingRequired = val ?? true),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Authentication & Password'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _passwordController,
                      label: _isEdit ? 'New Password (leave blank to keep current)' : 'Password *',
                      hint: 'At least 8 characters',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppTheme.mutedSlate,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _passwordConfirmController,
                      label: 'Confirm Password',
                      hint: 'Re-enter password',
                      obscureText: _obscurePassword,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Must Change Password on Next Login',
                        style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.deepSlate),
                      ),
                      value: _mustChangePassword,
                      activeColor: AppTheme.navyBlue,
                      onChanged: (val) => setState(() => _mustChangePassword = val ?? false),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.heading(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navyBlue),
        ),
        const SizedBox(height: 4),
        const Divider(color: AppTheme.borderSubtle, height: 1),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.deepSlate),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.body(fontSize: 13, color: AppTheme.lightSlate),
            filled: true,
            fillColor: AppTheme.pureWhite,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.navyBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Department',
          style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.deepSlate),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _selectedDepartmentId,
              isExpanded: true,
              hint: Text('Select department', style: AppTheme.body(fontSize: 13, color: AppTheme.lightSlate)),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('No Department')),
                ..._departments.map(
                  (d) => DropdownMenuItem<int?>(
                    value: d['id'] as int,
                    child: Text(
                      d['name']?.toString() ?? '',
                      style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
                    ),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedDepartmentId = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManagerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reporting Manager',
          style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.deepSlate),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _selectedManagerId,
              isExpanded: true,
              hint: Text('Select reporting manager', style: AppTheme.body(fontSize: 13, color: AppTheme.lightSlate)),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('No Manager')),
                ..._managers
                    .where((m) => !_isEdit || m['id'] != widget.employeeId)
                    .map(
                      (m) => DropdownMenuItem<int?>(
                        value: m['id'] as int,
                        child: Text(
                          "${m['full_name'] ?? m['name']} (${(m['role'] ?? 'staff').toString().toUpperCase()})",
                          style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
                        ),
                      ),
                    ),
              ],
              onChanged: (val) => setState(() => _selectedManagerId = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoiningDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Joining Date',
          style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.deepSlate),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _selectJoiningDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.mutedSlate),
                const SizedBox(width: 10),
                Text(
                  _joiningDate ?? 'Select joining date',
                  style: AppTheme.body(
                    fontSize: 13,
                    color: _joiningDate != null ? AppTheme.deepSlate : AppTheme.lightSlate,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    const roles = [
      {'val': 'staff', 'label': 'Staff'},
      {'val': 'admin', 'label': 'Admin / Manager'},
      {'val': 'super_admin', 'label': 'Super Admin'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role',
          style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.deepSlate),
        ),
        const SizedBox(height: 6),
        Row(
          children: roles.map((r) {
            final isSelected = _selectedRole == r['val'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedRole = r['val']!),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.navyBlue : AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppTheme.navyBlue : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      r['label']!,
                      style: AppTheme.heading(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppTheme.pureWhite : AppTheme.deepSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdminScopeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Scope Jurisdiction',
            style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.deepSlate),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedScope = 'assigned'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedScope == 'assigned' ? AppTheme.royalBlue : AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedScope == 'assigned' ? AppTheme.royalBlue : AppTheme.borderSubtle,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Assigned Depts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedScope == 'assigned' ? AppTheme.pureWhite : AppTheme.deepSlate,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedScope = 'all'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedScope == 'all' ? AppTheme.royalBlue : AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedScope == 'all' ? AppTheme.royalBlue : AppTheme.borderSubtle,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Company-wide',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedScope == 'all' ? AppTheme.pureWhite : AppTheme.deepSlate,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Status',
          style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.deepSlate),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedStatus = 'active'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedStatus == 'active' ? AppTheme.successBg : AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedStatus == 'active' ? AppTheme.successText : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'ACTIVE',
                      style: AppTheme.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _selectedStatus == 'active' ? AppTheme.successText : AppTheme.mutedSlate,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedStatus = 'inactive'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedStatus == 'inactive' ? AppTheme.dangerBg : AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedStatus == 'inactive' ? AppTheme.dangerText : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'INACTIVE',
                      style: AppTheme.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _selectedStatus == 'inactive' ? AppTheme.dangerText : AppTheme.mutedSlate,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkingDaysPicker() {
    const dayNames = {1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Working Days (Mon - Sun)',
          style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.deepSlate),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = i + 1;
            final isSelected = _workingDays.contains(day);
            return GestureDetector(
              onTap: () => _toggleWorkingDay(day),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.navyBlue : AppTheme.pureWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.navyBlue : AppTheme.borderSubtle,
                  ),
                ),
                child: Center(
                  child: Text(
                    dayNames[day]!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppTheme.pureWhite : AppTheme.mutedSlate,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

