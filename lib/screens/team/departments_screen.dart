import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../core/widgets/module_app_bar.dart';
import '../../models/department_model.dart';
import '../../services/directory_service.dart';
import '../projects/projects_list_screen.dart';
import 'team_list_screen.dart';

class DepartmentsScreen extends StatefulWidget {
  final DirectoryService? directoryService;

  const DepartmentsScreen({super.key, this.directoryService});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  late final DirectoryService _directoryService =
      widget.directoryService ?? DirectoryService();
  final TextEditingController _searchController = TextEditingController();

  List<DepartmentModel> _departments = [];
  List<DepartmentModel> _filteredDepartments = [];
  List<Map<String, dynamic>> _managers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'ALL'; // ALL, ACTIVE, INACTIVE

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final depts = await _directoryService.getDepartmentModels(status: 'all');
      final employees = await _directoryService.getEmployees(
        status: 'all',
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _departments = depts;
          _managers = employees.where((e) {
            final role = (e['role'] ?? '').toString().toLowerCase();
            final status = (e['status'] ?? 'active').toString().toLowerCase();
            return (role == 'admin' || role == 'super_admin') &&
                status == 'active';
          }).toList();
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredDepartments = _departments.where((dept) {
        final matchesStatus = switch (_statusFilter) {
          'ACTIVE' => dept.isActive,
          'INACTIVE' => !dept.isActive,
          _ => true,
        };

        final name = dept.name.toLowerCase();
        final desc = (dept.description ?? '').toLowerCase();
        final mgr = (dept.managerName ?? '').toLowerCase();
        final matchesQuery =
            query.isEmpty ||
            name.contains(query) ||
            desc.contains(query) ||
            mgr.contains(query);

        return matchesStatus && matchesQuery;
      }).toList();
    });
  }

  // KPI Calculations
  int get _totalDepartments => _departments.length;
  int get _activeDepartments => _departments.where((d) => d.isActive).length;
  int get _totalAssignedEmployees =>
      _departments.fold(0, (sum, d) => sum + d.employeeCount);
  int get _totalActiveProjects =>
      _departments.fold(0, (sum, d) => sum + d.activeProjectsCount);

  Future<void> _openDepartmentDialog({DepartmentModel? department}) async {
    final isEdit = department != null;
    final nameController = TextEditingController(text: department?.name ?? '');
    final descController = TextEditingController(
      text: department?.description ?? '',
    );
    int? selectedManagerId = department?.managerId;
    String status = department?.status ?? 'active';
    String? formError;
    bool isSaving = false;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final mediaQuery = MediaQuery.of(ctx);
          return Container(
            margin: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.royalBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_note : Icons.add_business,
                          color: AppTheme.royalBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit ? 'Edit Department' : 'Add New Department',
                          style: AppTheme.heading(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.deepSlate,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.mutedSlate,
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.borderSubtle, height: 24),

                  if (formError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.dangerText.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppTheme.dangerText,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formError!,
                              style: AppTheme.body(
                                fontSize: 12,
                                color: AppTheme.dangerText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Department Name
                  Text(
                    'Department Name *',
                    style: AppTheme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: AppTheme.body(
                      fontSize: 14,
                      color: AppTheme.deepSlate,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Mobile Engineering, QA & Testing',
                      hintStyle: AppTheme.body(color: AppTheme.lightSlate),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.borderSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.royalBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: AppTheme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    style: AppTheme.body(
                      fontSize: 14,
                      color: AppTheme.deepSlate,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Scope, key functions, and responsibilities...',
                      hintStyle: AppTheme.body(color: AppTheme.lightSlate),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.borderSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.royalBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Department Head
                  Text(
                    'Department Head / Manager',
                    style: AppTheme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedManagerId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.borderSubtle,
                        ),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('— None (Unassigned) —'),
                      ),
                      ..._managers.map(
                        (m) => DropdownMenuItem<int?>(
                          value: m['id'] as int,
                          child: Text(
                            '${m['full_name'] ?? m['name']} (${(m['role'] ?? 'admin').toString().toUpperCase()})',
                            style: AppTheme.body(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) =>
                        setSheetState(() => selectedManagerId = val),
                  ),
                  const SizedBox(height: 16),

                  // Status Toggle
                  Text(
                    'Operational Status',
                    style: AppTheme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: BrutalistPressable(
                          onTap: () => setSheetState(() => status = 'active'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: status == 'active'
                                  ? AppTheme.successBg
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: status == 'active'
                                    ? AppTheme.successText
                                    : AppTheme.borderSubtle,
                                width: status == 'active' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: status == 'active'
                                      ? AppTheme.successText
                                      : AppTheme.mutedSlate,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'ACTIVE',
                                  style: AppTheme.mono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: status == 'active'
                                        ? AppTheme.successText
                                        : AppTheme.mutedSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BrutalistPressable(
                          onTap: () => setSheetState(() => status = 'inactive'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: status == 'inactive'
                                  ? AppTheme.dangerBg
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: status == 'inactive'
                                    ? AppTheme.dangerText
                                    : AppTheme.borderSubtle,
                                width: status == 'inactive' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cancel,
                                  size: 16,
                                  color: status == 'inactive'
                                      ? AppTheme.dangerText
                                      : AppTheme.mutedSlate,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'INACTIVE',
                                  style: AppTheme.mono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: status == 'inactive'
                                        ? AppTheme.dangerText
                                        : AppTheme.mutedSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(sheetContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: AppTheme.borderSubtle,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTheme.heading(
                              fontSize: 14,
                              color: AppTheme.mutedSlate,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  if (name.isEmpty) {
                                    setSheetState(
                                      () => formError =
                                          'Department name is required.',
                                    );
                                    return;
                                  }
                                  if (name.length > 120) {
                                    setSheetState(
                                      () => formError =
                                          'Department name must be under 120 characters.',
                                    );
                                    return;
                                  }

                                  setSheetState(() {
                                    isSaving = true;
                                    formError = null;
                                  });

                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final navigator = Navigator.of(sheetContext);

                                  try {
                                    final payload = <String, dynamic>{
                                      if (isEdit) 'id': department.id,
                                      'name': name,
                                      'description': descController.text.trim(),
                                      'manager_id': ?selectedManagerId,
                                      'status': status,
                                    };

                                    final res = await _directoryService
                                        .saveDepartment(payload);
                                    if (!mounted) return;
                                    navigator.pop(true);
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          res['message']?.toString() ??
                                              'Department saved successfully.',
                                        ),
                                        backgroundColor: AppTheme.successText,
                                      ),
                                    );
                                    _loadData();
                                  } catch (e) {
                                    setSheetState(() {
                                      isSaving = false;
                                      formError = e
                                          .toString()
                                          .replaceAll('ApiException:', '')
                                          .trim();
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.royalBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.pureWhite,
                                  ),
                                )
                              : Text(
                                  isEdit
                                      ? 'Update Department'
                                      : 'Create Department',
                                  style: AppTheme.heading(
                                    fontSize: 14,
                                    color: AppTheme.pureWhite,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleDeleteOrDeactivate(DepartmentModel dept) async {
    final inUse = dept.isInUse;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: Row(
          children: [
            Icon(
              inUse ? Icons.warning_amber_rounded : Icons.delete_outline,
              color: inUse ? const Color(0xFFF59E0B) : AppTheme.dangerText,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                inUse ? 'Deactivate Department' : 'Delete Department',
                style: AppTheme.heading(
                  fontSize: 17,
                  color: AppTheme.deepSlate,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          inUse
              ? 'Department "${dept.name}" is assigned to ${dept.totalEmployeeCount} employee(s) and ${dept.totalProjectsCount} project(s).\n\nTo preserve historical records, it cannot be permanently deleted. Mark it as inactive instead?'
              : 'Are you sure you want to permanently delete department "${dept.name}"?\n\nThis action cannot be undone.',
          style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTheme.body(fontSize: 14, color: AppTheme.mutedSlate),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: inUse
                  ? const Color(0xFFF59E0B)
                  : AppTheme.dangerText,
            ),
            child: Text(
              inUse ? 'Deactivate' : 'Delete Permanently',
              style: AppTheme.heading(fontSize: 13, color: AppTheme.pureWhite),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await _directoryService.deleteDepartment(dept.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ??
                (inUse ? 'Department deactivated.' : 'Department deleted.'),
          ),
          backgroundColor: inUse
              ? const Color(0xFFF59E0B)
              : AppTheme.successText,
        ),
      );
      _loadData();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException:', '').trim()),
          backgroundColor: AppTheme.dangerText,
        ),
      );
    }
  }

  void _navigateToStaff(DepartmentModel dept) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeamListScreen(initialDepartmentId: dept.id),
      ),
    );
  }

  void _navigateToProjects(DepartmentModel dept) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectsListScreen(initialDepartmentId: dept.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: ModuleAppBar(
        title: 'Department Management',
        subtitle: '${_departments.length} registered department(s)',
        actions: [
          IconButton(
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.refresh, color: AppTheme.deepSlate),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          const SizedBox(width: 2),
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ElevatedButton.icon(
              onPressed: () => _openDepartmentDialog(),
              icon: const Icon(Icons.add, size: 15),
              label: const Text('Add Dept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.royalBlue,
                foregroundColor: AppTheme.pureWhite,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                textStyle: AppTheme.heading(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.royalBlue,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.royalBlue),
              )
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 48,
                        color: AppTheme.mutedSlate,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTheme.body(color: AppTheme.mutedSlate),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.royalBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : CustomScrollView(
                slivers: [
                  // 1. KPI Summary Matrix Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          final itemWidth = (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildKpiCard(
                                width: itemWidth,
                                label: 'Total Departments',
                                value: '$_totalDepartments',
                                icon: Icons.domain_outlined,
                                accentColor: AppTheme.royalBlue,
                              ),
                              _buildKpiCard(
                                width: itemWidth,
                                label: 'Active Departments',
                                value: '$_activeDepartments',
                                icon: Icons.check_circle_outline,
                                accentColor: AppTheme.successText,
                              ),
                              _buildKpiCard(
                                width: itemWidth,
                                label: 'Staff Assigned',
                                value: '$_totalAssignedEmployees',
                                icon: Icons.people_outline,
                                accentColor: const Color(0xFF8B5CF6),
                              ),
                              _buildKpiCard(
                                width: itemWidth,
                                label: 'Active Projects',
                                value: '$_totalActiveProjects',
                                icon: Icons.assignment_outlined,
                                accentColor: const Color(0xFFF59E0B),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // 2. Search & Filter Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Search Input
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.pureWhite,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => _applyFilters(),
                              style: AppTheme.body(
                                fontSize: 13,
                                color: AppTheme.deepSlate,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Search by name, description, or head...',
                                hintStyle: AppTheme.body(
                                  fontSize: 13,
                                  color: AppTheme.lightSlate,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 18,
                                  color: AppTheme.mutedSlate,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          size: 16,
                                          color: AppTheme.mutedSlate,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          _applyFilters();
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Status Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('ALL', _departments.length),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'ACTIVE',
                                  _departments.where((d) => d.isActive).length,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'INACTIVE',
                                  _departments.where((d) => !d.isActive).length,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Department Cards List
                  if (_filteredDepartments.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.folder_off_outlined,
                                size: 48,
                                color: AppTheme.lightSlate,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No departments match your filters.',
                                style: AppTheme.body(
                                  color: AppTheme.mutedSlate,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _openDepartmentDialog(),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Department'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.royalBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) =>
                              _buildDepartmentCard(_filteredDepartments[i]),
                          childCount: _filteredDepartments.length,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildKpiCard({
    required double width,
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const Spacer(),
              Text(
                value,
                style: AppTheme.heading(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.deepSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.body(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedSlate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _statusFilter == label;
    return BrutalistPressable(
      onTap: () {
        setState(() {
          _statusFilter = label;
        });
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.royalBlue : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.royalBlue : AppTheme.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.mono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.pureWhite : AppTheme.deepSlate,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.pureWhite.withValues(alpha: 0.25)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: AppTheme.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppTheme.pureWhite : AppTheme.mutedSlate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(DepartmentModel dept) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dept.isActive ? AppTheme.borderSubtle : AppTheme.dangerBg,
          width: 1.0,
        ),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon, Title, Status Pill, More Options
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dept.isActive
                      ? AppTheme.royalBlue.withValues(alpha: 0.08)
                      : AppTheme.dangerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.domain_outlined,
                    size: 22,
                    color: dept.isActive
                        ? AppTheme.royalBlue
                        : AppTheme.dangerText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dept.name,
                            style: AppTheme.heading(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.deepSlate,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: dept.isActive
                                ? AppTheme.successBg
                                : AppTheme.dangerBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            dept.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: AppTheme.mono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: dept.isActive
                                  ? AppTheme.successText
                                  : AppTheme.dangerText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (dept.description != null &&
                        dept.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        dept.description!,
                        style: AppTheme.body(
                          fontSize: 12,
                          color: AppTheme.mutedSlate,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Department Head Information
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.royalBlue.withValues(alpha: 0.2),
                  child: Text(
                    dept.hasManager
                        ? (dept.managerName?.substring(0, 1).toUpperCase() ??
                              'M')
                        : '—',
                    style: AppTheme.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.royalBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Head: ',
                  style: AppTheme.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightSlate,
                  ),
                ),
                Expanded(
                  child: Text(
                    dept.managerName ?? 'No Head Assigned',
                    style: AppTheme.body(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: dept.hasManager
                          ? AppTheme.deepSlate
                          : AppTheme.mutedSlate,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Row 3: Metrics & Drill-Down Buttons
          Row(
            children: [
              // Staff Drill-down
              Expanded(
                child: BrutalistPressable(
                  onTap: () => _navigateToStaff(dept),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 14,
                          color: AppTheme.royalBlue,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${dept.employeeCount} Staff',
                            style: AppTheme.body(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.deepSlate,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: AppTheme.lightSlate,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Projects Drill-down
              Expanded(
                child: BrutalistPressable(
                  onTap: () => _navigateToProjects(dept),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.folder_outlined,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${dept.activeProjectsCount} Projects',
                            style: AppTheme.body(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.deepSlate,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: AppTheme.lightSlate,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Edit Action
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppTheme.royalBlue,
                ),
                tooltip: 'Edit Department',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: () => _openDepartmentDialog(department: dept),
              ),

              // Delete or Deactivate Action
              IconButton(
                icon: Icon(
                  dept.isActive ? Icons.delete_outline : Icons.block,
                  size: 18,
                  color: dept.isActive
                      ? AppTheme.dangerText
                      : AppTheme.mutedSlate,
                ),
                tooltip: dept.isInUse
                    ? 'Deactivate Department'
                    : 'Delete Department',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: () => _handleDeleteOrDeactivate(dept),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
