import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_date_utils.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../models/project_model.dart';
import '../../services/auth_service.dart';
import '../../services/directory_service.dart';
import '../../services/project_service.dart';
import 'project_detail_screen.dart';
import 'project_form_screen.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  final ProjectService _projectService = ProjectService();
  final DirectoryService _directoryService = DirectoryService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isLoading = true;
  String? _errorMessage;
  List<ProjectModel> _projects = [];
  int _totalProjects = 0;

  // Filter States
  String _selectedPill =
      'All'; // All, Active, Planned, At Risk, Completed, On Hold, Archived
  int? _selectedDepartmentId;
  int? _selectedManagerId;
  String _selectedPriority = 'all';
  bool _overdueOnly = false;

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _managers = [];

  bool get hasAdvancedFilters =>
      _selectedDepartmentId != null ||
      _selectedManagerId != null ||
      _selectedPriority != 'all' ||
      _overdueOnly;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _loadProjects();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final depts = await _directoryService.getDepartments();
      final employees = await _directoryService.getEmployees(limit: 100);
      final managersList = employees.where((e) {
        final role = e['role']?.toString().toLowerCase();
        return role == 'admin' || role == 'super_admin';
      }).toList();

      if (mounted) {
        setState(() {
          _departments = depts;
          _managers = managersList.isNotEmpty ? managersList : employees;
        });
      }
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _loadProjects();
    });
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? statusQuery;
      bool? isArchived;
      final upper = _selectedPill.toUpperCase();

      if (upper == 'ACTIVE') statusQuery = 'active';
      if (upper == 'PLANNED') statusQuery = 'planned';
      if (upper == 'COMPLETED') statusQuery = 'completed';
      if (upper == 'ON HOLD') statusQuery = 'on_hold';
      if (upper == 'ARCHIVED') isArchived = true;

      final res = await _projectService.getProjects(
        status: statusQuery,
        priority: _selectedPriority != 'all' ? _selectedPriority : null,
        departmentId: _selectedDepartmentId,
        managerId: _selectedManagerId,
        overdue: _overdueOnly || upper == 'AT RISK',
        archived: isArchived,
        search: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
        limit: 50,
      );

      var list = (res['projects'] as List<ProjectModel>?) ?? [];
      final totalRaw = res['total'];
      final total = totalRaw is num
          ? totalRaw.toInt()
          : (int.tryParse(totalRaw?.toString() ?? '') ?? list.length);

      if (upper == 'AT RISK') {
        list = list.where((p) => p.isAtRisk).toList();
      }

      if (mounted) {
        setState(() {
          _projects = list;
          _totalProjects = total;
          _isLoading = false;
        });
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

  void _onPillSelected(String pill) {
    if (_selectedPill == pill) return;
    setState(() {
      _selectedPill = pill;
    });
    _loadProjects();
  }

  void _resetAllFilters() {
    setState(() {
      _selectedPill = 'All';
      _searchController.clear();
      _selectedDepartmentId = null;
      _selectedManagerId = null;
      _selectedPriority = 'all';
      _overdueOnly = false;
    });
    _loadProjects();
  }

  void _openAdvancedFilterSheet() {
    int? tempDept = _selectedDepartmentId;
    int? tempMgr = _selectedManagerId;
    String tempPri = _selectedPriority;
    bool tempOverdue = _overdueOnly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Material(
          color: AppTheme.pureWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Projects',
                      style: AppTheme.heading(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Department Dropdown
                DropdownButtonFormField<int?>(
                  initialValue: tempDept,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Departments'),
                    ),
                    ..._departments.map(
                      (d) => DropdownMenuItem<int?>(
                        value: d['id'] as int?,
                        child: Text(d['name']?.toString() ?? ''),
                      ),
                    ),
                  ],
                  onChanged: (val) => setSheetState(() => tempDept = val),
                ),
                const SizedBox(height: 12),

                // Manager Dropdown
                DropdownButtonFormField<int?>(
                  initialValue: tempMgr,
                  decoration: const InputDecoration(
                    labelText: 'Project Manager',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Managers'),
                    ),
                    ..._managers.map(
                      (m) => DropdownMenuItem<int?>(
                        value: m['id'] as int?,
                        child: Text(m['full_name']?.toString() ?? ''),
                      ),
                    ),
                  ],
                  onChanged: (val) => setSheetState(() => tempMgr = val),
                ),
                const SizedBox(height: 12),

                // Priority Dropdown
                DropdownButtonFormField<String>(
                  initialValue: tempPri,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All Priorities'),
                    ),
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(
                      value: 'critical',
                      child: Text('Critical'),
                    ),
                  ],
                  onChanged: (val) =>
                      setSheetState(() => tempPri = val ?? 'all'),
                ),
                const SizedBox(height: 12),

                // Overdue Only Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Overdue projects only',
                    style: AppTheme.body(fontSize: 14),
                  ),
                  value: tempOverdue,
                  activeThumbColor: AppTheme.navyBlue,
                  onChanged: (val) => setSheetState(() => tempOverdue = val),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _resetAllFilters();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppTheme.borderSubtle),
                        ),
                        child: const Text('Reset All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedDepartmentId = tempDept;
                            _selectedManagerId = tempMgr;
                            _selectedPriority = tempPri;
                            _overdueOnly = tempOverdue;
                          });
                          _loadProjects();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navyBlue,
                          foregroundColor: AppTheme.pureWhite,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCreateProject() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
    );
    if (created == true) {
      _loadProjects();
    }
  }

  void _navigateToEditProject(ProjectModel project) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProjectFormScreen(project: project)),
    );
    if (updated == true) {
      _loadProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService().currentUser?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Projects', style: AppTheme.heading(fontSize: 18)),
            Text(
              '$_totalProjects project${_totalProjects == 1 ? '' : 's'}${_overdueOnly ? ' · overdue only' : ''}',
              style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
            ),
          ],
        ),
        actions: [
          // Filter Funnel with Active Indicator Dot
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                tooltip: 'Advanced Filters',
                onPressed: _openAdvancedFilterSheet,
              ),
              if (hasAdvancedFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.royalBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppTheme.royalBlue,
              ),
              tooltip: 'New Project',
              onPressed: _navigateToCreateProject,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadProjects,
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _navigateToCreateProject,
              backgroundColor: AppTheme.navyBlue,
              tooltip: 'New Project',
              child: const Icon(Icons.add, color: AppTheme.pureWhite),
            )
          : null,
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Horizontal Filter Pills
          _buildFilterChips(isAdmin),

          // Active Filter Chips Bar (if advanced filters active)
          if (hasAdvancedFilters) _buildActiveFilterBanner(),

          // Projects List or Loader/Error
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.royalBlue,
                      strokeWidth: 2.5,
                    ),
                  )
                : _errorMessage != null
                ? _buildErrorView()
                : _projects.isEmpty
                ? _buildEmptyView()
                : RefreshIndicator(
                    onRefresh: _loadProjects,
                    color: AppTheme.royalBlue,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _projects.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, index) {
                        return _buildProjectCard(_projects[index], isAdmin);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
        decoration: InputDecoration(
          hintText: 'Search by project name, code, or client...',
          hintStyle: AppTheme.body(fontSize: 13, color: AppTheme.lightSlate),
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
                    _loadProjects();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
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
    );
  }

  Widget _buildFilterChips(bool isAdmin) {
    final filters = [
      'All',
      'Active',
      'Planned',
      'At Risk',
      'Completed',
      'On Hold',
    ];
    if (isAdmin) {
      filters.add('Archived');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.pureWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedPill.toUpperCase() == f.toUpperCase();
            final isAtRisk = f.toUpperCase() == 'AT RISK';
            final isArchived = f.toUpperCase() == 'ARCHIVED';

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _onPillSelected(f),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isAtRisk
                              ? AppTheme.dangerBg
                              : isArchived
                              ? const Color(0xFF475569)
                              : AppTheme.navyBlue)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? (isAtRisk
                                ? const Color(0xFFFECACA)
                                : isArchived
                                ? const Color(0xFF475569)
                                : AppTheme.navyBlue)
                          : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Text(
                    f,
                    style: AppTheme.heading(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (isAtRisk
                                ? AppTheme.dangerText
                                : AppTheme.pureWhite)
                          : AppTheme.mutedSlate,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActiveFilterBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFFEF3C7),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 14, color: Color(0xFFB45309)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Filtered by: ${_selectedPriority != 'all' ? 'Priority ($_selectedPriority) ' : ''}${_selectedDepartmentId != null ? 'Department ' : ''}${_overdueOnly ? 'Overdue ' : ''}',
              style: AppTheme.body(
                fontSize: 11,
                color: const Color(0xFFB45309),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: _resetAllFilters,
            child: Text(
              'Clear All',
              style: AppTheme.mono(
                fontSize: 11,
                color: const Color(0xFFB45309),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project, bool isAdmin) {
    final completionClamped = (project.completionPercent / 100).clamp(0.0, 1.0);
    final canManage = project.canManage || isAdmin;

    // Subtitle Triad: Code · Client · Department
    final subtitleParts = <String>[project.projectCode];
    if (project.clientName != null && project.clientName!.isNotEmpty) {
      subtitleParts.add(project.clientName!);
    }
    if (project.departmentName != null && project.departmentName!.isNotEmpty) {
      subtitleParts.add(project.departmentName!);
    }

    return BrutalistPressable(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(projectId: project.id),
          ),
        );
        _loadProjects();
      },
      backgroundColor: AppTheme.pureWhite,
      borderColor: project.isAtRisk
          ? const Color(0xFFFECACA)
          : AppTheme.borderSubtle,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Row: Status Badge + Priority Tag + Quick Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildStatusBadge(
                    project.status,
                    project.isAtRisk,
                    project.isArchived,
                  ),
                  const SizedBox(width: 6),
                  _buildPriorityTag(project.priority),
                ],
              ),
              if (canManage)
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppTheme.mutedSlate,
                  ),
                  tooltip: 'Edit Project',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _navigateToEditProject(project),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Project Title
          Text(
            project.name,
            style: AppTheme.heading(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          const SizedBox(height: 4),

          // 3. Subtitle Triad: Code · Client · Department
          Text(
            subtitleParts.join(' · '),
            style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
          ),
          const SizedBox(height: 14),

          // 4. Dates & Manager Row (Matching Web Table Columns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timeline',
                      style: AppTheme.body(
                        fontSize: 10,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      project.startDate != null &&
                              project.startDate!.trim().isNotEmpty
                          ? 'Start ${AppDateUtils.fmtDate(project.startDate)}'
                          : 'Start —',
                      style: AppTheme.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      project.deadline != null &&
                              project.deadline!.trim().isNotEmpty
                          ? 'Due   ${AppDateUtils.fmtDate(project.deadline)}${project.isOverdue ? ' (${project.daysOverdue}d late)' : ''}'
                          : 'Due   —',
                      style: AppTheme.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: project.isOverdue
                            ? AppTheme.dangerText
                            : AppTheme.deepSlate,
                      ),
                    ),
                  ],
                ),
              ),
              if (project.managerName != null &&
                  project.managerName!.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manager',
                        style: AppTheme.body(
                          fontSize: 10,
                          color: AppTheme.mutedSlate,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        project.managerName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 5. Team Avatar Stack
          if (project.teamMembers.isNotEmpty) ...[
            Row(
              children: [
                _buildAvatarStack(project.teamMembers, project.memberCount),
                const SizedBox(width: 8),
                Text(
                  '${project.memberCount} member${project.memberCount == 1 ? '' : 's'}',
                  style: AppTheme.body(
                    fontSize: 11,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // 6. Progress Bar with calculation methodology
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress (${project.isWeighted ? 'weighted' : 'average'})',
                style: AppTheme.heading(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedSlate,
                ),
              ),
              Text(
                '${project.completionPercent.toStringAsFixed(0)}%',
                style: AppTheme.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completionClamped,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                project.isAtRisk ? AppTheme.dangerText : AppTheme.royalBlue,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 7. Task Triad Badges: Done, Pending, Overdue (Matching Web Table Columns)
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildTaskBadge(
                      'Done',
                      project.doneTasks,
                      const Color(0xFFDEF7EC),
                      const Color(0xFF03543F),
                    ),
                    _buildTaskBadge(
                      'Pending',
                      project.pendingTasks,
                      const Color(0xFFF1F5F9),
                      AppTheme.mutedSlate,
                    ),
                    _buildTaskBadge(
                      'Overdue',
                      project.overdueTasks,
                      project.overdueTasks > 0
                          ? AppTheme.dangerBg
                          : const Color(0xFFF1F5F9),
                      project.overdueTasks > 0
                          ? AppTheme.dangerText
                          : AppTheme.mutedSlate,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppTheme.lightSlate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack(List<Map<String, dynamic>> members, int totalCount) {
    const double size = 26.0;
    const double overlap = 16.0;

    final displayList = members.take(4).toList();
    final remaining = totalCount - displayList.length;

    return SizedBox(
      height: size,
      width:
          (displayList.length * overlap) +
          (remaining > 0 ? 30 : size - overlap),
      child: Stack(
        children: [
          for (int i = 0; i < displayList.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.pureWhite, width: 2),
                  color: const Color(0xFFCBD5E1),
                ),
                child: Center(
                  child: Text(
                    displayList[i]['full_name'] != null &&
                            displayList[i]['full_name'].toString().isNotEmpty
                        ? displayList[i]['full_name']
                              .toString()
                              .substring(0, 1)
                              .toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: displayList.length * overlap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.pureWhite, width: 2),
                  color: AppTheme.navyBlue,
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskBadge(String label, int count, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: AppTheme.mono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.body(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityTag(String priority) {
    final p = priority.toLowerCase();
    Color bg = const Color(0xFFF1F5F9);
    Color fg = AppTheme.mutedSlate;

    if (p == 'critical' || p == 'urgent') {
      bg = AppTheme.dangerBg;
      fg = AppTheme.dangerText;
    } else if (p == 'high') {
      bg = AppTheme.warningBg;
      fg = AppTheme.warningText;
    } else if (p == 'medium') {
      bg = AppTheme.infoBg;
      fg = AppTheme.infoText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority[0].toUpperCase() + priority.substring(1).toLowerCase(),
        style: AppTheme.heading(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isAtRisk, bool isArchived) {
    if (isArchived) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Archived',
          style: AppTheme.heading(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
      );
    }

    if (isAtRisk) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.dangerBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'At Risk',
          style: AppTheme.heading(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.dangerText,
          ),
        ),
      );
    }

    final isCompleted = status.toLowerCase() == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.successBg : AppTheme.infoBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.isEmpty
            ? 'Active'
            : status[0].toUpperCase() + status.substring(1).toLowerCase(),
        style: AppTheme.heading(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isCompleted ? AppTheme.successText : AppTheme.infoText,
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_open_outlined,
            size: 48,
            color: AppTheme.mutedSlate,
          ),
          const SizedBox(height: 12),
          Text('No Projects Found', style: AppTheme.heading(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            hasAdvancedFilters
                ? 'Try resetting the filters to see more projects'
                : 'No projects matching filter "$_selectedPill"',
            style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
          ),
          if (hasAdvancedFilters) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _resetAllFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBlue,
                foregroundColor: AppTheme.pureWhite,
              ),
              child: const Text('Reset All Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.dangerBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.dangerText.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load projects',
                style: AppTheme.heading(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.dangerText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred.',
                style: AppTheme.body(color: AppTheme.deepSlate, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadProjects,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
