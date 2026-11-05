import 'package:flutter/material.dart';
import '../../core/app_date_utils.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../models/project_model.dart';
import '../../services/directory_service.dart';
import '../../services/project_service.dart';

class ProjectFormScreen extends StatefulWidget {
  final ProjectModel? project;
  final ProjectDetailModel? detail;

  const ProjectFormScreen({super.key, this.project, this.detail});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProjectService _projectService = ProjectService();
  final DirectoryService _directoryService = DirectoryService();

  late final TextEditingController _nameController;
  late final TextEditingController _clientController;
  late final TextEditingController _budgetController;
  late final TextEditingController _scopeController;
  late final TextEditingController _deliverablesController;

  int? _selectedDepartmentId;
  int? _selectedManagerId;
  String _selectedPriority = 'medium';
  String _selectedStatus = 'planned';
  DateTime? _startDate;
  DateTime? _deadline;

  bool _isLoading = false;
  bool _isInitLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _managers = [];
  List<Map<String, dynamic>> _allEmployees = [];
  final Set<int> _selectedMemberIds = {};
  final Set<int> _selectedViewerIds = {};
  String _memberFilterText = '';
  String _viewerFilterText = '';

  bool get isEdit => widget.project != null || widget.detail != null;
  int? get projectId => widget.detail?.project.id ?? widget.project?.id;

  @override
  void initState() {
    super.initState();
    final p = widget.detail?.project ?? widget.project;

    _nameController = TextEditingController(text: p?.name ?? '');
    _clientController = TextEditingController(text: p?.clientName ?? '');
    _budgetController = TextEditingController(
      text: p?.budget != null ? p!.budget.toString() : '',
    );
    _scopeController = TextEditingController(
      text: widget.detail?.scopeOfWork ?? '',
    );
    _deliverablesController = TextEditingController(
      text: widget.detail?.deliverables ?? '',
    );

    _selectedDepartmentId = p?.departmentId;
    _selectedManagerId = p?.managerId;
    _selectedPriority = p?.priority ?? 'medium';
    _selectedStatus = p?.status ?? 'planned';

    if (p?.startDate != null && p!.startDate!.isNotEmpty) {
      _startDate = DateTime.tryParse(p.startDate!);
    }
    if (p?.deadline != null && p!.deadline!.isNotEmpty) {
      _deadline = DateTime.tryParse(p.deadline!);
    }

    // Pre-populate members and viewers from detail if provided
    if (widget.detail != null) {
      for (final m in widget.detail!.members) {
        if (m.memberRole == 'viewer') {
          _selectedViewerIds.add(m.userId);
        } else {
          _selectedMemberIds.add(m.userId);
        }
      }
    }
    if (_selectedManagerId != null) {
      _selectedMemberIds.add(_selectedManagerId!);
    }

    _loadDropdownData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _budgetController.dispose();
    _scopeController.dispose();
    _deliverablesController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    try {
      final depts = await _directoryService.getDepartments();
      final employees = await _directoryService.getEmployees(limit: 100);

      // Filter employees to admins / managers
      final managersList = employees.where((e) {
        final role = e['role']?.toString().toLowerCase();
        return role == 'admin' || role == 'super_admin';
      }).toList();

      // If editing and detail was not passed directly, load details to pre-populate members
      if (widget.detail == null && widget.project != null && widget.project!.id > 0) {
        try {
          final detail = await _projectService.getProjectDetails(widget.project!.id);
          for (final m in detail.members) {
            if (m.memberRole == 'viewer') {
              _selectedViewerIds.add(m.userId);
            } else {
              _selectedMemberIds.add(m.userId);
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _departments = depts;
          _allEmployees = employees;
          _managers = managersList.isNotEmpty ? managersList : employees;
          if (_selectedManagerId != null) {
            _selectedMemberIds.add(_selectedManagerId!);
          }
          _isInitLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitLoading = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate != null &&
        _deadline != null &&
        _deadline!.isBefore(_startDate!)) {
      setState(() {
        _errorMessage = 'Deadline must be on or after the start date.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Ensure manager is always a member
    if (_selectedManagerId != null) {
      _selectedMemberIds.add(_selectedManagerId!);
    }

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'client_name': _clientController.text.trim().isEmpty
          ? null
          : _clientController.text.trim(),
      'department_id': _selectedDepartmentId,
      'manager_id': _selectedManagerId,
      'members': _selectedMemberIds.toList(),
      'viewers': _selectedViewerIds.toList(),
      'priority': _selectedPriority,
      'status': _selectedStatus,
      'start_date': _startDate != null ? _formatDate(_startDate!) : null,
      'deadline': _deadline != null ? _formatDate(_deadline!) : null,
      'budget': _budgetController.text.trim().isEmpty
          ? null
          : _budgetController.text.trim(),
      'scope_of_work': _scopeController.text.trim().isEmpty
          ? null
          : _scopeController.text.trim(),
      'deliverables': _deliverablesController.text.trim().isEmpty
          ? null
          : _deliverablesController.text.trim(),
    };

    try {
      await _projectService.saveProject(payload, id: projectId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Project updated successfully!'
                  : 'Project created successfully!',
              style: AppTheme.body(
                color: AppTheme.pureWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppTheme.navyBlue,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_deadline ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.navyBlue,
              onPrimary: AppTheme.pureWhite,
              surface: AppTheme.pureWhite,
              onSurface: AppTheme.deepSlate,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _deadline = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Project' : 'New Project',
          style: AppTheme.heading(fontSize: 18),
        ),
      ),
      body: _isInitLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.royalBlue,
                strokeWidth: 2.5,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppTheme.dangerText,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTheme.body(
                                  color: AppTheme.dangerText,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildSectionHeader('Project Identity'),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Project Name *',
                      hint: 'e.g. Mobile App Optimization',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Project name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _clientController,
                            label: 'Client Name',
                            hint: 'e.g. Acme Corporation',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Department',
                            value: _selectedDepartmentId,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('— None —'),
                              ),
                              ..._departments.map((d) {
                                return DropdownMenuItem<int?>(
                                  value: d['id'] as int?,
                                  child: Text(d['name']?.toString() ?? ''),
                                );
                              }),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedDepartmentId = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Team'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdown(
                            label: 'Project manager *',
                            value: _selectedManagerId,
                            items: _managers.map((m) {
                              return DropdownMenuItem<int>(
                                value: m['id'] as int?,
                                child: Text(m['full_name']?.toString() ?? ''),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedManagerId = val;
                                if (val != null) {
                                  _selectedMemberIds.add(val);
                                  _selectedViewerIds.remove(val);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTeamMultiSelectSection(
                            label: 'Members',
                            subtitle: '(can be assigned tasks)',
                            helperText:
                                'Tap to toggle. The manager is always a member.',
                            selectedIds: _selectedMemberIds,
                            filterText: _memberFilterText,
                            onFilterChanged: (q) =>
                                setState(() => _memberFilterText = q),
                            onToggle: (id, selected) {
                              setState(() {
                                if (selected) {
                                  _selectedMemberIds.add(id);
                                  _selectedViewerIds.remove(id);
                                } else {
                                  if (id != _selectedManagerId) {
                                    _selectedMemberIds.remove(id);
                                  }
                                }
                              });
                            },
                            lockedId: _selectedManagerId,
                            lockedBadge: 'Manager',
                          ),
                          const SizedBox(height: 16),
                          _buildTeamMultiSelectSection(
                            label: 'Viewers',
                            subtitle: '(read-only access)',
                            helperText:
                                'A user selected in both lists becomes a member.',
                            selectedIds: _selectedViewerIds,
                            filterText: _viewerFilterText,
                            onFilterChanged: (q) =>
                                setState(() => _viewerFilterText = q),
                            onToggle: (id, selected) {
                              setState(() {
                                if (selected) {
                                  _selectedViewerIds.add(id);
                                  _selectedMemberIds.remove(id);
                                } else {
                                  _selectedViewerIds.remove(id);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Status & Priority'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Status',
                            value: _selectedStatus,
                            items: const [
                              DropdownMenuItem(
                                value: 'draft',
                                child: Text('Draft'),
                              ),
                              DropdownMenuItem(
                                value: 'planned',
                                child: Text('Planned'),
                              ),
                              DropdownMenuItem(
                                value: 'active',
                                child: Text('Active'),
                              ),
                              DropdownMenuItem(
                                value: 'on_hold',
                                child: Text('On Hold'),
                              ),
                              DropdownMenuItem(
                                value: 'completed',
                                child: Text('Completed'),
                              ),
                              DropdownMenuItem(
                                value: 'cancelled',
                                child: Text('Cancelled'),
                              ),
                            ],
                            onChanged: (val) => setState(
                              () => _selectedStatus = val ?? 'planned',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Priority',
                            value: _selectedPriority,
                            items: const [
                              DropdownMenuItem(
                                value: 'low',
                                child: Text('Low'),
                              ),
                              DropdownMenuItem(
                                value: 'medium',
                                child: Text('Medium'),
                              ),
                              DropdownMenuItem(
                                value: 'high',
                                child: Text('High'),
                              ),
                              DropdownMenuItem(
                                value: 'critical',
                                child: Text('Critical'),
                              ),
                            ],
                            onChanged: (val) => setState(
                              () => _selectedPriority = val ?? 'medium',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Timeline & Budget'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePickerTile(
                            label: 'Start Date',
                            date: _startDate,
                            onTap: () => _pickDate(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDatePickerTile(
                            label: 'Deadline',
                            date: _deadline,
                            onTap: () => _pickDate(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _budgetController,
                      label: 'Budget (₹ / USD)',
                      hint: 'e.g. 50000.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Scope & Deliverables'),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _scopeController,
                      label: 'Scope of Work',
                      hint:
                          'Describe technical scope, background, and goals...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _deliverablesController,
                      label: 'Deliverables',
                      hint: 'Key outputs, modules, or features to deliver...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: BrutalistPressable(
                        onTap: _isLoading ? () {} : _submitForm,
                        backgroundColor: AppTheme.navyBlue,
                        borderColor: AppTheme.navyBlue,
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.pureWhite,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  isEdit ? 'Save Changes' : 'Create Project',
                                  style: AppTheme.heading(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.pureWhite,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTheme.mono(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.mutedSlate,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.body(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.deepSlate,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.body(fontSize: 13, color: AppTheme.lightSlate),
            filled: true,
            fillColor: AppTheme.pureWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.navyBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.body(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.deepSlate,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.pureWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.body(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.deepSlate,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null ? AppDateUtils.fmtDate(_formatDate(date)) : 'Select date',
                  style: AppTheme.mono(
                    fontSize: 12,
                    color: date != null
                        ? AppTheme.deepSlate
                        : AppTheme.lightSlate,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.mutedSlate,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMultiSelectSection({
    required String label,
    required String subtitle,
    required String helperText,
    required Set<int> selectedIds,
    required String filterText,
    required ValueChanged<String> onFilterChanged,
    required void Function(int id, bool selected) onToggle,
    int? lockedId,
    String? lockedBadge,
  }) {
    final filtered = _allEmployees.where((e) {
      if (filterText.trim().isEmpty) return true;
      final q = filterText.toLowerCase();
      final name = (e['full_name'] ?? '').toString().toLowerCase();
      final dept = (e['department_name'] ?? '').toString().toLowerCase();
      final role = (e['role'] ?? '').toString().toLowerCase();
      return name.contains(q) || dept.contains(q) || role.contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              subtitle,
              style: AppTheme.body(
                fontSize: 11,
                color: AppTheme.mutedSlate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            children: [
              // Search input matching "Type to filter..."
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: TextField(
                  onChanged: onFilterChanged,
                  style: AppTheme.body(fontSize: 12, color: AppTheme.deepSlate),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Type to filter...',
                    hintStyle: AppTheme.body(
                        fontSize: 12, color: AppTheme.lightSlate),
                    prefixIcon: const Icon(Icons.search,
                        size: 16, color: AppTheme.mutedSlate),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 26, minHeight: 26),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No users found',
                            style: AppTheme.body(
                                fontSize: 12, color: AppTheme.mutedSlate),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          indent: 44,
                          color: Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (context, index) {
                          final emp = filtered[index];
                          final id = (emp['id'] as num).toInt();
                          final name =
                              emp['full_name']?.toString() ?? 'User #$id';
                          final dept = emp['department_name']?.toString();
                          final role = emp['role']?.toString();
                          final isLocked = lockedId != null && lockedId == id;
                          final isChecked =
                              isLocked || selectedIds.contains(id);

                          return InkWell(
                            onTap: isLocked
                                ? null
                                : () => onToggle(id, !isChecked),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: isChecked,
                                      onChanged: isLocked
                                          ? null
                                          : (val) =>
                                              onToggle(id, val ?? false),
                                      activeColor: AppTheme.navyBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 11,
                                    backgroundColor: isChecked
                                        ? AppTheme.navyBlue
                                        : const Color(0xFFE2E8F0),
                                    child: Text(
                                      name.isNotEmpty
                                          ? name.substring(0, 1).toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: isChecked
                                            ? AppTheme.pureWhite
                                            : AppTheme.deepSlate,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: AppTheme.body(
                                            fontSize: 12,
                                            fontWeight: isChecked
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: AppTheme.deepSlate,
                                          ),
                                        ),
                                        if (dept != null && dept.isNotEmpty)
                                          Text(
                                            '$dept${role != null && role != 'staff' ? ' · ${role.toUpperCase()}' : ''}',
                                            style: AppTheme.body(
                                              fontSize: 10,
                                              color: AppTheme.mutedSlate,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isLocked && lockedBadge != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        lockedBadge,
                                        style: AppTheme.mono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.mutedSlate,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helperText,
          style: AppTheme.body(fontSize: 10, color: AppTheme.mutedSlate),
        ),
        if (selectedIds.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: selectedIds.map((id) {
              final emp = _allEmployees.firstWhere(
                (e) => (e['id'] as num?)?.toInt() == id,
                orElse: () => {'full_name': 'User #$id'},
              );
              final name = emp['full_name']?.toString() ?? 'User #$id';
              final isLocked = lockedId != null && lockedId == id;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLocked ? const Color(0xFFF1F5F9) : AppTheme.infoBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLocked
                        ? AppTheme.borderSubtle
                        : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTheme.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isLocked ? AppTheme.deepSlate : AppTheme.navyBlue,
                      ),
                    ),
                    if (!isLocked) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => onToggle(id, false),
                        child: const Icon(
                          Icons.close,
                          size: 13,
                          color: AppTheme.navyBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
