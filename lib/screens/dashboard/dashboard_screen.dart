import 'package:flutter/material.dart';
import '../../core/theme.dart';
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
import '../team/team_list_screen.dart';
import 'admin_dashboard_view.dart';
import 'staff_dashboard_view.dart';
import '../../core/widgets/app_side_drawer.dart';
import '../../core/widgets/server_config_dialog.dart';
import 'widgets/compliance_card.dart';
import 'widgets/dashboard_filter_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();
  final NotificationService _notificationService = NotificationService();

  int _selectedTabIndex = 0;
  final Set<int> _loadedTabs = {0};
  String _tasksInitialFilter = 'All';
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

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.scaffoldBg,
      drawer: AppSideDrawer(
        user: user,
        currentTabIndex: _selectedTabIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
            _loadedTabs.add(index);
            if (index != 1) {
              _tasksInitialFilter = 'All';
            }
          });
        },
        onLogout: () => _handleLogout(),
        onComplianceTap: () => _showComplianceSheet(),
        onFilterTap: () => _showManagementFilterSheet(),
        onTeamListTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TeamListScreen(initialTab: 0),
            ),
          );
        },
        onTeamSubTabTap: (initialTab) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamListScreen(initialTab: initialTab),
            ),
          );
        },
        onOverdueTap: () {
          setState(() {
            _tasksInitialFilter = 'OVERDUE';
            _selectedTabIndex = 1;
            _loadedTabs.add(1);
          });
        },
        onNotificationsTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
          _loadNotificationCount();
        },
        onApprovalsTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportsListScreen(
                user: user,
                initialFilter: 'pending_review',
              ),
            ),
          );
        },
      ),
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
                  // Hamburger Menu Button (Matching Reference Step 2 & 3)
                  InkWell(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.menu_rounded,
                          color: AppTheme.deepSlate,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title: user.fullName ("Aman Admin" / "Admin Executive")
                  Expanded(
                    child: Text(
                      user.fullName,
                      style: AppTheme.heading(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Refresh Action (Compact to prevent header overflow)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(
                      Icons.refresh,
                      color: AppTheme.mutedSlate,
                      size: 20,
                    ),
                    tooltip: 'Refresh',
                    onPressed: () {
                      _loadDashboard();
                      _loadNotificationCount();
                    },
                  ),
                  // Notification Bell with Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppTheme.deepSlate,
                          size: 22,
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
                          top: 0,
                          right: 0,
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
                  // Logout Action (Compact)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(
                      Icons.logout,
                      color: AppTheme.mutedSlate,
                      size: 20,
                    ),
                    tooltip: 'Sign Out',
                    onPressed: _handleLogout,
                  ),
                  const SizedBox(width: 4),
                  // User Avatar Circle
                  GestureDetector(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF64748B),
                      child: Text(
                        _getInitials(user.fullName),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                    ),
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
          // Tab 1: Tasks & Kanban (lazy-loaded on demand)
          _loadedTabs.contains(1)
              ? TasksScreen(
                  key: ValueKey('tasks_tab_$_tasksInitialFilter'),
                  initialFilter: _tasksInitialFilter,
                )
              : const SizedBox.shrink(),
          // Tab 2: Projects Directory (lazy-loaded on demand)
          _loadedTabs.contains(2)
              ? const ProjectsListScreen()
              : const SizedBox.shrink(),
          // Tab 3: Daily Reports (lazy-loaded on demand)
          _loadedTabs.contains(3)
              ? ReportsListScreen(user: user)
              : const SizedBox.shrink(),
        ],
      ),
      // Clean Royal Blue Circular FAB (Suppressed on Pulse Dashboard to prevent card obstruction)
      floatingActionButton: _selectedTabIndex == 0
          ? null
          : FloatingActionButton(
              onPressed: _onFabPressed,
              backgroundColor: AppTheme.royalBlue,
              elevation: 4,
              shape: const CircleBorder(),
              child: Icon(
                user.isAdmin ? Icons.add : Icons.add_comment_outlined,
                color: AppTheme.pureWhite,
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
            _buildNavTab(3, 'Reports', Icons.bar_chart_rounded),
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
            _loadedTabs.add(index);
            if (index != 1) {
              _tasksInitialFilter = 'All';
            }
          });
          if (index == 0) _loadDashboard();
        },
        child: Column(
          children: [
            // 4px top indicator bar in royal blue on active tab
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 4,
              color: isSelected ? AppTheme.royalBlue : Colors.transparent,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: color),
                  const SizedBox(height: 3),
                  Text(
                    label.toUpperCase(),
                    style: AppTheme.heading(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
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
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loadDashboard,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry Connection'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        showServerConfigDialog(
                          context: context,
                          onSaved: () {
                            _loadDashboard();
                            _loadNotificationCount();
                          },
                        );
                      },
                      icon: const Icon(Icons.settings_ethernet, size: 18),
                      label: const Text('Change Server / IP'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.navyBlue,
                        side: const BorderSide(color: AppTheme.navyBlue),
                      ),
                    ),
                  ],
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

  void _showComplianceSheet() {
    final badgeData = _dashboardData?['compliance'] as Map<String, dynamic>?;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
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
                'Reporting Compliance',
                style: AppTheme.heading(fontSize: 17),
              ),
              const SizedBox(height: 16),
              ComplianceCard(
                badgeData: badgeData,
                onSubmitReport: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedTabIndex = 3;
                    _loadedTabs.add(3);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManagementFilterSheet() {
    final filterOptions =
        (_dashboardData?['filter_options'] as Map<String, dynamic>?) ?? {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DashboardFilterSheet(
        filterOptions: filterOptions,
        selectedProjectId: _selectedProjectId,
        selectedDepartmentId: _selectedDepartmentId,
        selectedUserId: _selectedUserId,
        onApply: (projId, deptId, userId) {
          setState(() {
            _selectedProjectId = projId;
            _selectedDepartmentId = deptId;
            _selectedUserId = userId;
          });
          _loadDashboard();
        },
      ),
    );
  }
}
