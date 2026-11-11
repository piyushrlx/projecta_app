import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/dashboard_service.dart';
import '../projects/project_detail_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../team/employee_detail_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  final UserModel user;
  final DashboardService? dashboardService;

  const GlobalSearchScreen({
    super.key,
    required this.user,
    this.dashboardService,
  });

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  late final DashboardService _dashboardService =
      widget.dashboardService ?? DashboardService();

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isLoading = false;
  String? _errorMessage;
  String _currentQuery = '';

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _employees = [];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final clean = query.trim();

    if (clean.length < 2) {
      setState(() {
        _currentQuery = clean;
        _isLoading = false;
        _projects = [];
        _tasks = [];
        _employees = [];
        _errorMessage = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(clean);
    });
  }

  Future<void> _executeSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentQuery = query;
    });

    try {
      final results = await _dashboardService.searchGlobal(query);
      if (mounted) {
        setState(() {
          _projects = List<Map<String, dynamic>>.from(
            results['projects'] as List? ?? [],
          );
          _tasks = List<Map<String, dynamic>>.from(
            results['tasks'] as List? ?? [],
          );
          _employees = List<Map<String, dynamic>>.from(
            results['employees'] as List? ?? [],
          );
          _isLoading = false;
        });
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

  int get _totalResults => _projects.length + _tasks.length + _employees.length;

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
      case 'completed':
        return AppTheme.successText;
      case 'in_progress':
        return AppTheme.royalBlue;
      case 'on_hold':
      case 'blocked':
      case 'pending':
        return AppTheme.warningText;
      case 'cancelled':
      case 'inactive':
        return AppTheme.dangerText;
      default:
        return AppTheme.mutedSlate;
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
        return AppTheme.successBg;
      case 'in_progress':
        return AppTheme.infoBg;
      case 'on_hold':
      case 'blocked':
      case 'pending':
        return AppTheme.warningBg;
      case 'cancelled':
      case 'inactive':
        return AppTheme.dangerBg;
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.pureWhite,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.deepSlate),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: AppTheme.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.deepSlate,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.user.isAdmin
                              ? 'Search projects, tasks, employees...'
                              : 'Search projects & tasks...',
                          hintStyle: AppTheme.body(
                            fontSize: 13,
                            color: AppTheme.mutedSlate,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: AppTheme.mutedSlate,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: AppTheme.mutedSlate,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onQueryChanged('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: _onQueryChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.royalBlue),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.dangerText, size: 40),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTheme.body(color: AppTheme.mutedSlate),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentQuery.length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.manage_search, size: 54, color: AppTheme.lightSlate),
            const SizedBox(height: 12),
            Text(
              'Search WorkDesk',
              style: AppTheme.heading(fontSize: 16, color: AppTheme.deepSlate),
            ),
            const SizedBox(height: 4),
            Text(
              widget.user.isAdmin
                  ? 'Type at least 2 characters to find projects, tasks, or employees.'
                  : 'Type at least 2 characters to find projects or tasks.',
              style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_totalResults == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 54, color: AppTheme.lightSlate),
            const SizedBox(height: 12),
            Text(
              'No results found for "$_currentQuery"',
              style: AppTheme.heading(fontSize: 16, color: AppTheme.deepSlate),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching with a different term or keyword.',
              style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Result Summary Banner
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '$_totalResults result(s) for "$_currentQuery"',
            style: AppTheme.heading(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedSlate,
            ),
          ),
        ),

        // 1. Projects Section
        if (_projects.isNotEmpty) ...[
          _buildCategoryHeader('PROJECTS', _projects.length, Icons.folder_outlined),
          ..._projects.map(_buildProjectItem),
          const SizedBox(height: 16),
        ],

        // 2. Tasks Section
        if (_tasks.isNotEmpty) ...[
          _buildCategoryHeader('TASKS', _tasks.length, Icons.check_box_outlined),
          ..._tasks.map(_buildTaskItem),
          const SizedBox(height: 16),
        ],

        // 3. Employees Section (Admin only)
        if (_employees.isNotEmpty) ...[
          _buildCategoryHeader('EMPLOYEES', _employees.length, Icons.people_outline),
          ..._employees.map(_buildEmployeeItem),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildCategoryHeader(String title, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.royalBlue),
          const SizedBox(width: 6),
          Text(
            title,
            style: AppTheme.heading(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: AppTheme.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.mutedSlate,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectItem(Map<String, dynamic> project) {
    final id = (project['id'] as num?)?.toInt() ?? 0;
    final name = (project['name'] ?? '').toString();
    final code = (project['project_code'] ?? '').toString();
    final client = (project['client_name'] ?? '').toString();
    final status = (project['status'] ?? 'active').toString();
    final priority = (project['priority'] ?? 'medium').toString();
    final deadline = project['deadline']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderSubtle, width: 1.0),
      ),
      color: AppTheme.pureWhite,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(projectId: id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: AppTheme.heading(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusBgColor(status),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: AppTheme.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    code,
                    style: AppTheme.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.royalBlue,
                    ),
                  ),
                  if (client.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• $client',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                  ],
                  if (deadline != null && deadline.isNotEmpty) ...[
                    const Spacer(),
                    Text(
                      'Due $deadline',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final id = (task['id'] as num?)?.toInt() ?? 0;
    final title = (task['title'] ?? '').toString();
    final code = (task['task_code'] ?? '').toString();
    final projectName = (task['project_name'] ?? '').toString();
    final status = (task['status'] ?? 'pending').toString();
    final priority = (task['priority'] ?? 'medium').toString();
    final deadline = task['deadline']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderSubtle, width: 1.0),
      ),
      color: AppTheme.pureWhite,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(taskId: id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.heading(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusBgColor(status),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: AppTheme.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    code,
                    style: AppTheme.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.royalBlue,
                    ),
                  ),
                  if (projectName.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '• $projectName',
                        style: AppTheme.body(
                          fontSize: 11,
                          color: AppTheme.mutedSlate,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (deadline != null && deadline.isNotEmpty) ...[
                    Text(
                      'Due $deadline',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeItem(Map<String, dynamic> employee) {
    final id = (employee['id'] as num?)?.toInt() ?? 0;
    final name = (employee['full_name'] ?? employee['name'] ?? '').toString();
    final email = (employee['email'] ?? '').toString();
    final department = (employee['department_name'] ?? '').toString();
    final role = (employee['role'] ?? 'staff').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderSubtle, width: 1.0),
      ),
      color: AppTheme.pureWhite,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmployeeDetailScreen(employeeId: id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.royalBlue,
                child: Text(
                  _getInitials(name),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
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
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (department.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    department,
                    style: AppTheme.body(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: role == 'super_admin'
                      ? const Color(0xFFEDE9FE)
                      : role == 'admin'
                          ? AppTheme.infoBg
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  role.replaceAll('_', ' ').toUpperCase(),
                  style: AppTheme.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: role == 'super_admin'
                        ? const Color(0xFF6D28D9)
                        : role == 'admin'
                            ? AppTheme.royalBlue
                            : AppTheme.mutedSlate,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

