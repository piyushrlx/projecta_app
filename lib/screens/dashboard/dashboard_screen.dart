import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/projeqta_logo.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/notification_service.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../projects/projects_list_screen.dart';
import '../reports/report_submission_screen.dart';
import '../reports/reports_list_screen.dart';
import '../tasks/create_task_screen.dart';
import '../tasks/tasks_screen.dart';
import 'admin_dashboard_view.dart';
import 'staff_dashboard_view.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();
  final NotificationService _notificationService = NotificationService();

  int _selectedTabIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String? _errorMessage;
  int _unreadNotifications = 0;
  int? _selectedProjectId;
  int? _selectedDepartmentId;
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadNotificationCount();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _dashboardService.getDashboard(
        projectId: _selectedProjectId,
        departmentId: _selectedDepartmentId,
        userId: _selectedUserId,
      );
      if (mounted) {
        setState(() {
          _dashboardData = data;
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

  Future<void> _loadNotificationCount() async {
    try {
      final res = await _notificationService.getNotifications(limit: 1);
      if (mounted) {
        setState(() {
          _unreadNotifications = (res['unread_count'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        ),
        title: Text(
          'Sign Out Confirmation',
          style: AppTheme.heading(fontSize: 17, color: AppTheme.deepSlate),
        ),
        content: Text(
          'Are you sure you want to sign out from projeqta?',
          style: AppTheme.body(fontSize: 14, color: AppTheme.mutedSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTheme.heading(fontSize: 14, color: AppTheme.mutedSlate),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerText,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _onFabPressed() async {
    if (widget.user.isAdmin) {
      final created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
      );
      if (created == true) {
        _loadDashboard();
      }
    } else {
      final submitted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const ReportSubmissionScreen()),
      );
      if (submitted == true) {
        _loadDashboard();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ProjeqtaIcon(size: 24),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.heading(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.deepSlate,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Role Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: user.isAdmin
                                ? AppTheme.infoBg
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.isAdmin ? 'Admin' : 'Staff',
                            style: AppTheme.heading(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: user.isAdmin
                                  ? AppTheme.infoText
                                  : AppTheme.mutedSlate,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification Bell with Soft Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppTheme.mutedSlate,
                        ),
                        tooltip: 'Notifications',
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                          _loadNotificationCount();
                        },
                      ),
                      if (_unreadNotifications > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerText,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _unreadNotifications > 9
                                  ? '9+'
                                  : _unreadNotifications.toString(),
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.pureWhite,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.mutedSlate),
                    tooltip: 'Refresh',
                    onPressed: () {
                      _loadDashboard();
                      _loadNotificationCount();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppTheme.mutedSlate),
                    tooltip: 'Sign Out',
                    onPressed: _handleLogout,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          // Tab 0: Pulse (Dashboard)
          _buildDashboardTab(),
          // Tab 1: Tasks & Kanban
          const TasksScreen(),
          // Tab 2: Projects Directory
          const ProjectsListScreen(),
          // Tab 3: Daily Reports
          ReportsListScreen(user: user),
        ],
      ),
      // Executive Navy Blue FAB (16px rounded corners, white icon)
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: AppTheme.navyBlue,
        foregroundColor: AppTheme.pureWhite,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(
          user.isAdmin ? Icons.add : Icons.add_comment_outlined,
          size: 26,
        ),
      ),
      // Persistent 4-Tab Bottom Navigation Bar (height 68px, Royal Blue active icon)
      bottomNavigationBar: Container(
        height: 68,
        decoration: const BoxDecoration(
          color: AppTheme.pureWhite,
          border: Border(
            top: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x050F172A),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildNavTab(0, 'Pulse', Icons.speed),
            _buildNavTab(1, 'Tasks', Icons.check_box_outlined),
            _buildNavTab(2, 'Projects', Icons.folder_outlined),
            _buildNavTab(3, 'Reports', Icons.assignment_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(int index, String label, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    final color = isSelected ? AppTheme.royalBlue : AppTheme.mutedSlate;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
          if (index == 0) _loadDashboard();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.heading(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.royalBlue,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.dangerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.dangerText.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.dangerText,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Connection Notice',
                      style: AppTheme.heading(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.dangerText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _loadDashboard,
                  child: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppTheme.royalBlue,
      child: widget.user.isAdmin
          ? AdminDashboardView(
              user: widget.user,
              data: _dashboardData ?? {},
              onRefresh: _loadDashboard,
              selectedProjectId: _selectedProjectId,
              selectedDepartmentId: _selectedDepartmentId,
              selectedUserId: _selectedUserId,
              onFilterChanged: (projId, deptId, userId) {
                setState(() {
                  _selectedProjectId = projId;
                  _selectedDepartmentId = deptId;
                  _selectedUserId = userId;
                });
                _loadDashboard();
              },
            )
          : StaffDashboardView(
              user: widget.user,
              data: _dashboardData ?? {},
              onRefresh: _loadDashboard,
            ),
    );
  }
}
