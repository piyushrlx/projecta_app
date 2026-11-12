import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../core/widgets/module_app_bar.dart';
import '../../core/widgets/user_avatar.dart';
import '../../services/directory_service.dart';
import 'departments_screen.dart';
import 'employee_detail_screen.dart';
import 'employee_form_screen.dart';

class TeamListScreen extends StatefulWidget {
  final int initialTab;
  final DirectoryService? directoryService;
  final int? initialDepartmentId;

  const TeamListScreen({
    super.key,
    this.initialTab = 0,
    this.directoryService,
    this.initialDepartmentId,
  });

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final DirectoryService _directoryService =
      widget.directoryService ?? DirectoryService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'ALL';
  int? _selectedDepartmentId;

  static const List<String> _statusFilters = [
    'ALL',
    'ACTIVE',
    'ON LEAVE',
    'RESIGNED',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDepartmentId = widget.initialDepartmentId;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _loadEmployees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _directoryService.getEmployees(
        status: 'all',
        departmentId: _selectedDepartmentId,
      );
      if (mounted) {
        setState(() {
          _employees = list;
          _isLoading = false;
        });
        _applyFilter();
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

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = _employees.where((emp) {
        final name = (emp['name'] ?? emp['full_name'] ?? '')
            .toString()
            .toLowerCase();
        final designation = (emp['designation'] ?? emp['role'] ?? '')
            .toString()
            .toLowerCase();
        final status = (emp['status'] ?? 'active').toString().toLowerCase();

        final matchesSearch =
            query.isEmpty ||
            name.contains(query) ||
            designation.contains(query);

        final matchesStatus =
            _statusFilter == 'ALL' ||
            (_statusFilter == 'ACTIVE' && status == 'active') ||
            (_statusFilter == 'ON LEAVE' && status == 'on_leave') ||
            (_statusFilter == 'RESIGNED' &&
                (status == 'resigned' || status == 'inactive'));

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.successText;
      case 'on_leave':
        return AppTheme.warningText;
      case 'resigned':
      case 'inactive':
        return AppTheme.dangerText;
      default:
        return AppTheme.mutedSlate;
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.successBg;
      case 'on_leave':
        return AppTheme.warningBg;
      case 'resigned':
      case 'inactive':
        return AppTheme.dangerBg;
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'on_leave':
        return 'On Leave';
      case 'resigned':
        return 'Resigned';
      case 'inactive':
        return 'Inactive';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: ModuleAppBar(
        title: 'Team Management',
        subtitle:
            '${_filtered.length} of ${_employees.length} member${_employees.length == 1 ? '' : 's'}',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.domain_outlined,
              color: AppTheme.deepSlate,
              size: 22,
            ),
            tooltip: 'Departments',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DepartmentsScreen(directoryService: _directoryService),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.deepSlate),
            tooltip: 'Refresh',
            onPressed: _loadEmployees,
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Pill Sub-tabs (Matching Reference Step 5)
          Container(
            color: AppTheme.pureWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.royalBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppTheme.pureWhite,
                unselectedLabelColor: AppTheme.mutedSlate,
                labelStyle: AppTheme.heading(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppTheme.heading(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Team List'),
                  Tab(text: 'Assign Roles'),
                  Tab(text: 'Performance'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTeamListTab(),
                _buildAssignRolesTab(),
                _buildPerformanceTab(),
              ],
            ),
          ),
        ],
      ),
      // Circular Royal Blue FAB (Opens Add Employee)
      floatingActionButton: FloatingActionButton(
        heroTag: 'team_list_fab',
        onPressed: () async {
          HapticFeedback.lightImpact();
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EmployeeFormScreen(directoryService: _directoryService),
            ),
          );
          if (created == true) {
            _loadEmployees();
          }
        },
        backgroundColor: AppTheme.royalBlue,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: AppTheme.pureWhite, size: 26),
      ),
    );
  }

  // â”€â”€â”€ TEAM LIST TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildTeamListTab() {
    return Column(
      children: [
        // Search + filter row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: AppTheme.mutedSlate,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _applyFilter(),
                          decoration: InputDecoration(
                            hintText: 'Search team member...',
                            hintStyle: AppTheme.body(
                              fontSize: 13,
                              color: AppTheme.lightSlate,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: AppTheme.body(
                            fontSize: 13,
                            color: AppTheme.deepSlate,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          color: AppTheme.mutedSlate,
                          onPressed: () {
                            _searchController.clear();
                            _applyFilter();
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Status filter button
              GestureDetector(
                onTap: _showStatusFilterSheet,
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: _statusFilter != 'ALL'
                        ? AppTheme.navyBlue
                        : AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: _statusFilter != 'ALL'
                        ? AppTheme.pureWhite
                        : AppTheme.mutedSlate,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Status filter chips (horizontal scroll)
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _statusFilters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _statusFilters[i];
              final isSelected = _statusFilter == f;
              return GestureDetector(
                onTap: () {
                  setState(() => _statusFilter = f);
                  _applyFilter();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.navyBlue : AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.navyBlue
                          : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Text(
                    f,
                    style: AppTheme.heading(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.pureWhite
                          : AppTheme.mutedSlate,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Members list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.navyBlue,
                  ),
                )
              : _errorMessage != null
              ? _buildErrorState()
              : _filtered.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadEmployees,
                  color: AppTheme.navyBlue,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildMemberCard(_filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> emp) {
    final name = (emp['name'] ?? emp['full_name'] ?? 'Unknown').toString();
    final designation = (emp['designation'] ?? emp['role'] ?? 'Team Member')
        .toString();
    final status = (emp['status'] ?? 'active').toString();
    final department = (emp['department_name'] ?? '').toString();
    final email = (emp['email'] ?? '').toString();

    return BrutalistPressable(
      onTap: () => _onMemberTap(emp),
      backgroundColor: AppTheme.pureWhite,
      borderColor: AppTheme.borderSubtle,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Avatar with initials fallback
          UserAvatar(
            name: name,
            photoUrl: (emp['profile_photo_url'] ?? emp['profile_photo'])
                ?.toString(),
            size: 44,
            backgroundColor: AppTheme.navyBlue,
            textColor: AppTheme.pureWhite,
            fontSize: 15,
            border: Border.all(
              color: AppTheme.royalBlue.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.heading(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  designation,
                  style: AppTheme.body(
                    fontSize: 12,
                    color: AppTheme.mutedSlate,
                  ),
                ),
                if (department.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    department,
                    style: AppTheme.body(
                      fontSize: 11,
                      color: AppTheme.lightSlate,
                    ),
                  ),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: AppTheme.mono(
                      fontSize: 11,
                      color: AppTheme.lightSlate,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Status badge + menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusBgColor(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(status),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: AppTheme.mutedSlate,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (val) {
                  if (val == 'view') _onMemberTap(emp);
                  if (val == 'edit') _onMemberEdit(emp);
                  if (val == 'toggle') _toggleEmployeeStatus(emp);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text('View Profile'),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Employee'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(status == 'active' ? 'Deactivate' : 'Activate'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onMemberTap(Map<String, dynamic> emp) {
    final id = emp['id'] is int
        ? emp['id'] as int
        : int.tryParse(emp['id']?.toString() ?? '0') ?? 0;
    if (id <= 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeDetailScreen(
          employeeId: id,
          directoryService: _directoryService,
        ),
      ),
    ).then((_) {
      if (mounted) _loadEmployees();
    });
  }

  void _onMemberEdit(Map<String, dynamic> emp) async {
    final id = emp['id'] is int
        ? emp['id'] as int
        : int.tryParse(emp['id']?.toString() ?? '0') ?? 0;
    if (id <= 0) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeFormScreen(
          employeeId: id,
          directoryService: _directoryService,
        ),
      ),
    );
    if (updated == true && mounted) {
      _loadEmployees();
    }
  }

  Future<void> _toggleEmployeeStatus(Map<String, dynamic> emp) async {
    final id = emp['id'] is int
        ? emp['id'] as int
        : int.tryParse(emp['id']?.toString() ?? '0') ?? 0;
    if (id <= 0) return;
    final currentStatus = (emp['status'] ?? 'active').toString();
    final isActivating = currentStatus != 'active';
    final name = (emp['name'] ?? emp['full_name'] ?? 'Employee').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isActivating ? 'Activate Account' : 'Deactivate Account',
          style: AppTheme.heading(fontSize: 16, color: AppTheme.deepSlate),
        ),
        content: Text(
          isActivating
              ? 'Reactivate $name\'s account? They will be allowed to log in and submit daily reports.'
              : 'Deactivate $name\'s account? They will no longer be able to log in.',
          style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActivating
                  ? AppTheme.royalBlue
                  : AppTheme.dangerText,
            ),
            child: Text(
              isActivating ? 'Activate' : 'Deactivate',
              style: const TextStyle(color: AppTheme.pureWhite),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final res = await _directoryService.toggleEmployeeStatus(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res['message']?.toString() ?? 'Status updated successfully.',
              ),
              backgroundColor: AppTheme.successText,
            ),
          );
          _loadEmployees();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().replaceAll('ApiException:', '').trim(),
              ),
              backgroundColor: AppTheme.dangerText,
            ),
          );
        }
      }
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.dangerText,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Failed to load team.',
              textAlign: TextAlign.center,
              style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEmployees,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline,
            color: AppTheme.lightSlate,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No team members found.',
            style: AppTheme.body(fontSize: 14, color: AppTheme.mutedSlate),
          ),
        ],
      ),
    );
  }

  void _showStatusFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter by Status',
                style: AppTheme.heading(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ..._statusFilters.map(
                (f) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _statusFilter == f
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _statusFilter == f
                        ? AppTheme.navyBlue
                        : AppTheme.mutedSlate,
                  ),
                  title: Text(
                    f,
                    style: AppTheme.body(
                      fontSize: 14,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                  onTap: () {
                    setState(() => _statusFilter = f);
                    _applyFilter();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ ASSIGN ROLES TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildAssignRolesTab() {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.navyBlue,
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _employees.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final emp = _employees[i];
              final name = (emp['name'] ?? emp['full_name'] ?? 'Unknown')
                  .toString();
              final role = (emp['role'] ?? 'staff').toString();
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                  boxShadow: const [AppTheme.softShadow],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.navyBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(name),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTheme.heading(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.deepSlate,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            role.replaceAll('_', ' ').toUpperCase(),
                            style: AppTheme.mono(
                              fontSize: 11,
                              color: AppTheme.mutedSlate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        role == 'admin' || role == 'super_admin'
                            ? 'ADMIN'
                            : 'STAFF',
                        style: AppTheme.heading(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.infoText,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  // â”€â”€â”€ PERFORMANCE TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPerformanceTab() {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.navyBlue,
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _employees.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final emp = _employees[i];
              final name = (emp['name'] ?? emp['full_name'] ?? 'Unknown')
                  .toString();
              final openTasks =
                  (emp['open_tasks'] ?? emp['task_count'] ?? 0) as int;
              final completedTasks = (emp['completed_tasks'] ?? 0) as int;
              final totalTasks = openTasks + completedTasks;
              final completionRate = totalTasks > 0
                  ? (completedTasks / totalTasks * 100).round()
                  : 0;

              return Container(
                padding: const EdgeInsets.all(14),
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.navyBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(name),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.pureWhite,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            style: AppTheme.heading(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.deepSlate,
                            ),
                          ),
                        ),
                        Text(
                          '$completionRate%',
                          style: AppTheme.mono(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: completionRate >= 70
                                ? AppTheme.successText
                                : completionRate >= 40
                                ? AppTheme.warningText
                                : AppTheme.dangerText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0, end: completionRate / 100),
                        builder: (_, val, _) => LinearProgressIndicator(
                          value: val,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completionRate >= 70
                                ? AppTheme.successText
                                : completionRate >= 40
                                ? AppTheme.warningText
                                : AppTheme.dangerText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '$openTasks open  â€¢  ',
                          style: AppTheme.body(
                            fontSize: 11,
                            color: AppTheme.mutedSlate,
                          ),
                        ),
                        Text(
                          '$completedTasks completed',
                          style: AppTheme.body(
                            fontSize: 11,
                            color: AppTheme.successText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
  }
}
