import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/widgets/module_app_bar.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/employee_detail_model.dart';
import '../../services/directory_service.dart';
import 'employee_form_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  final DirectoryService? directoryService;

  const EmployeeDetailScreen({
    super.key,
    required this.employeeId,
    this.directoryService,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late final DirectoryService _directoryService =
      widget.directoryService ?? DirectoryService();
  late TabController _tabController;

  EmployeeDetailModel? _employee;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final detail = await _directoryService.getEmployeeDetail(
        widget.employeeId,
      );
      if (mounted) {
        setState(() {
          _employee = detail;
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

  Future<void> _onToggleStatus() async {
    final emp = _employee;
    if (emp == null) return;
    final isActivating = !emp.isActive;

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
              ? 'Reactivate ${emp.fullName}\'s account? They will be allowed to log in and submit daily reports.'
              : 'Deactivate ${emp.fullName}\'s account? They will no longer be able to log in.',
          style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTheme.body(
                color: AppTheme.mutedSlate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActivating
                  ? AppTheme.successText
                  : AppTheme.dangerText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(isActivating ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final res = await _directoryService.toggleEmployeeStatus(emp.id);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              res['message']?.toString() ?? 'Status updated successfully.',
            ),
            backgroundColor: isActivating
                ? AppTheme.successText
                : AppTheme.dangerText,
          ),
        );
        _loadDetails();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException:', '').trim()),
            backgroundColor: AppTheme.dangerText,
          ),
        );
      }
    }
  }

  Future<void> _onResetPassword() async {
    final emp = _employee;
    if (emp == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Password',
          style: AppTheme.heading(fontSize: 16, color: AppTheme.deepSlate),
        ),
        content: Text(
          'Generate a password reset link for ${emp.fullName} (${emp.email})?',
          style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTheme.body(color: AppTheme.mutedSlate),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navyBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Generate Link'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final res = await _directoryService.resetEmployeePassword(emp.id);
      final link = res['link']?.toString();
      if (!mounted) return;

      if (link != null && link.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.pureWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Password Reset Link',
              style: AppTheme.heading(fontSize: 16, color: AppTheme.deepSlate),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share this one-time link with the employee (expires in 60 minutes):',
                  style: AppTheme.body(
                    fontSize: 13,
                    color: AppTheme.mutedSlate,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: SelectableText(
                    link,
                    style: AppTheme.mono(
                      fontSize: 12,
                      color: AppTheme.royalBlue,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                  Navigator.pop(ctx);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard.'),
                      backgroundColor: AppTheme.successText,
                    ),
                  );
                },
                child: const Text('Copy Link'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navyBlue,
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              res['message']?.toString() ?? 'Password reset link sent.',
            ),
            backgroundColor: AppTheme.successText,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException:', '').trim()),
            backgroundColor: AppTheme.dangerText,
          ),
        );
      }
    }
  }

  void _onEdit() async {
    final emp = _employee;
    if (emp == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeFormScreen(
          employeeId: emp.id,
          directoryService: _directoryService,
        ),
      ),
    );
    if (updated == true) {
      _loadDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: ModuleAppBar(
        title: 'Employee Profile',
        subtitle: _employee?.fullName,
        actions: [
          if (_employee != null && _employee!.canManage) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.royalBlue),
              tooltip: 'Edit Profile',
              onPressed: _onEdit,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.deepSlate),
              onSelected: (val) {
                if (val == 'toggle') _onToggleStatus();
                if (val == 'reset') _onResetPassword();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        _employee!.isActive
                            ? Icons.block
                            : Icons.check_circle_outline,
                        size: 18,
                        color: _employee!.isActive
                            ? AppTheme.dangerText
                            : AppTheme.successText,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _employee!.isActive ? 'Deactivate' : 'Activate',
                        style: AppTheme.body(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_reset,
                        size: 18,
                        color: AppTheme.royalBlue,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Reset Password',
                        style: AppTheme.body(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.navyBlue),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.dangerText,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTheme.body(color: AppTheme.mutedSlate),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyBlue,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _employee == null
          ? const SizedBox()
          : RefreshIndicator(
              onRefresh: _loadDetails,
              color: AppTheme.navyBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHeaderCard(_employee!),
                    const SizedBox(height: 12),
                    _buildKpiGrid(_employee!),
                    const SizedBox(height: 16),
                    _buildTabBar(),
                    const SizedBox(height: 8),
                    _buildActiveTabContent(_employee!),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeaderCard(EmployeeDetailModel emp) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                name: emp.fullName,
                photoUrl: emp.profilePhotoUrl,
                size: 60,
                backgroundColor: AppTheme.navyBlue,
                textColor: AppTheme.pureWhite,
                fontSize: 22,
                border: Border.all(
                  color: AppTheme.royalBlue.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.fullName,
                      style: AppTheme.heading(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      emp.designation ?? 'Team Member',
                      style: AppTheme.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (emp.departmentName != null &&
                            emp.departmentName!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              emp.departmentName!,
                              style: AppTheme.body(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.deepSlate,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: emp.role == 'super_admin'
                                ? const Color(0xFFEDE9FE)
                                : emp.role == 'admin'
                                ? AppTheme.infoBg
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            emp.role.replaceAll('_', ' ').toUpperCase(),
                            style: AppTheme.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: emp.role == 'super_admin'
                                  ? const Color(0xFF6D28D9)
                                  : emp.role == 'admin'
                                  ? AppTheme.royalBlue
                                  : AppTheme.mutedSlate,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: emp.isActive
                                ? AppTheme.successBg
                                : AppTheme.dangerBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            emp.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: AppTheme.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: emp.isActive
                                  ? AppTheme.successText
                                  : AppTheme.dangerText,
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
          const Divider(height: 24, color: AppTheme.borderSubtle),
          // Meta Rows
          _buildMetaRow(Icons.email_outlined, 'Email', emp.email),
          if (emp.phone != null && emp.phone!.isNotEmpty)
            _buildMetaRow(Icons.phone_outlined, 'Phone', emp.phone!),
          if (emp.employeeCode != null && emp.employeeCode!.isNotEmpty)
            _buildMetaRow(
              Icons.badge_outlined,
              'Employee Code',
              emp.employeeCode!,
            ),
          if (emp.reportingManagerName != null &&
              emp.reportingManagerName!.isNotEmpty)
            _buildMetaRow(
              Icons.person_pin_outlined,
              'Manager',
              emp.reportingManagerName!,
            ),
          if (emp.joiningDate != null && emp.joiningDate!.isNotEmpty)
            _buildMetaRow(
              Icons.calendar_today_outlined,
              'Joined',
              emp.joiningDate!,
            ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.mutedSlate),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(EmployeeDetailModel emp) {
    final k = emp.kpis;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildKpiCard(
              'Tasks',
              '${k.completedTasks}/${k.assignedTasks}',
              '${k.pendingTasks} pending',
              AppTheme.royalBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(
              'Overdue',
              '${k.overdueTasks}',
              k.overdueTasks > 0 ? 'Urgent attention' : 'On schedule',
              k.overdueTasks > 0 ? AppTheme.dangerText : AppTheme.successText,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(
              'Compliance',
              k.complianceRate != null ? '${k.complianceRate}%' : 'N/A',
              'Last 30 days',
              (k.complianceRate ?? 0) >= 90
                  ? AppTheme.successText
                  : (k.complianceRate ?? 0) >= 70
                  ? AppTheme.warningText
                  : AppTheme.dangerText,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(
              'Reports',
              '${k.reportsCount30d}',
              '30d Total',
              AppTheme.deepSlate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.body(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedSlate,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTheme.mono(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTheme.body(fontSize: 9, color: AppTheme.lightSlate),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(minHeight: 38),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        onTap: (_) => setState(() {}),
        indicator: BoxDecoration(
          color: AppTheme.navyBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.pureWhite,
        unselectedLabelColor: AppTheme.mutedSlate,
        labelStyle: AppTheme.heading(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTheme.heading(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(text: 'Tasks (${_employee!.tasks.length})'),
          Tab(text: 'Projects (${_employee!.projects.length})'),
          Tab(text: 'Reports (${_employee!.reports.length})'),
          Tab(text: 'Leaves (${_employee!.exemptions.length})'),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(EmployeeDetailModel emp) {
    switch (_tabController.index) {
      case 0:
        return _buildTasksList(emp.tasks);
      case 1:
        return _buildProjectsList(emp.projects);
      case 2:
        return _buildReportsList(emp.reports);
      case 3:
        return _buildLeavesList(emp.exemptions);
      default:
        return const SizedBox();
    }
  }

  Widget _buildTasksList(List<EmployeeTaskSummary> tasks) {
    if (tasks.isEmpty) {
      return _buildEmptyTabState('No assigned tasks for this employee.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final t = tasks[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    t.taskCode,
                    style: AppTheme.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.royalBlue,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: t.status == 'completed'
                          ? AppTheme.successBg
                          : AppTheme.infoBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      t.status.toUpperCase(),
                      style: AppTheme.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: t.status == 'completed'
                            ? AppTheme.successText
                            : AppTheme.royalBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                t.title,
                style: AppTheme.heading(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.deepSlate,
                ),
              ),
              if (t.projectName != null) ...[
                const SizedBox(height: 2),
                Text(
                  t.projectName!,
                  style: AppTheme.body(
                    fontSize: 11,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: t.progress / 100,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          t.progress == 100
                              ? AppTheme.successText
                              : AppTheme.royalBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${t.progress}%',
                    style: AppTheme.mono(
                      fontSize: 10,
                      color: AppTheme.mutedSlate,
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

  Widget _buildProjectsList(List<EmployeeProjectSummary> projects) {
    if (projects.isEmpty) {
      return _buildEmptyTabState('No active project memberships.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: projects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = projects[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    p.projectCode,
                    style: AppTheme.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.royalBlue,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: p.status == 'active'
                          ? AppTheme.successBg
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      p.status.toUpperCase(),
                      style: AppTheme.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: p.status == 'active'
                            ? AppTheme.successText
                            : AppTheme.mutedSlate,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                p.name,
                style: AppTheme.heading(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.deepSlate,
                ),
              ),
              if (p.memberRole != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Role: ${p.memberRole}',
                  style: AppTheme.body(
                    fontSize: 11,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportsList(List<EmployeeReportSummary> reports) {
    if (reports.isEmpty) {
      return _buildEmptyTabState('No daily reports submitted yet.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = reports[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    r.reportDate,
                    style: AppTheme.heading(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (r.isLate)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'LATE',
                        style: AppTheme.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warningText,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '${r.minutesSpent ~/ 60}h ${r.minutesSpent % 60}m',
                    style: AppTheme.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedSlate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                r.workSummary,
                style: AppTheme.body(fontSize: 12, color: AppTheme.deepSlate),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeavesList(List<EmployeeExemptionSummary> leaves) {
    if (leaves.isEmpty) {
      return _buildEmptyTabState('No leave or exemption records.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: leaves.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final ex = leaves[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.infoBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (ex.reasonType ?? 'LEAVE').toUpperCase(),
                      style: AppTheme.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.royalBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${ex.startDate} → ${ex.endDate}',
                    style: AppTheme.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedSlate,
                    ),
                  ),
                ],
              ),
              if (ex.reason != null && ex.reason!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  ex.reason!,
                  style: AppTheme.body(fontSize: 12, color: AppTheme.deepSlate),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyTabState(String msg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Center(
        child: Text(
          msg,
          style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
        ),
      ),
    );
  }
}
