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
      final data = await _dashboardService.getDashboard();
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppTheme.pitchBlack, width: 2.0),
        ),
        title: Text(
          'LOGOUT CONFIRMATION',
          style: AppTheme.heading(fontSize: 16, color: AppTheme.pitchBlack),
        ),
        content: Text(
          'Are you sure you want to sign out from Projecta?',
          style: AppTheme.body(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: AppTheme.mono(color: AppTheme.pitchBlack),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.violentRed,
            ),
            child: const Text('LOGOUT'),
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
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.fullName.toUpperCase(),
              style: AppTheme.heading(fontSize: 16),
            ),
            Text(
              user.designation ??
                  (user.isAdmin ? 'ADMINISTRATOR' : 'STAFF WORKER'),
              style: AppTheme.mono(
                fontSize: 11,
                color: const Color(0xFFAAAAAA),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Notifications Bell with Unread Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
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
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.violentRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications > 9
                          ? '9+'
                          : _unreadNotifications.toString(),
                      style: AppTheme.mono(
                        fontSize: 9,
                        color: AppTheme.pureWhite,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _loadDashboard();
              _loadNotificationCount();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          // Tab 0: Core Dashboard
          _buildDashboardTab(),
          // Tab 1: Tasks & Kanban
          const TasksScreen(),
          // Tab 2: Projects Directory
          const ProjectsListScreen(),
          // Tab 3: Daily Reports
          ReportsListScreen(user: user),
        ],
      ),
      // Role-Aware Violent Red Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: AppTheme.violentRed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppTheme.pureWhite, width: 2),
        ),
        elevation: 6,
        tooltip: user.isAdmin ? 'Assign New Task' : 'Submit Daily Report',
        child: Icon(
          user.isAdmin ? Icons.add_task : Icons.post_add,
          color: AppTheme.pureWhite,
          size: 28,
        ),
      ),
      // Persistent Neo-Brutalist Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF2E2E2E), width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedTabIndex,
          onTap: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
            if (index == 0) _loadDashboard();
          },
          backgroundColor: AppTheme.pitchBlack,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.violentRed,
          unselectedItemColor: const Color(0xFF888888),
          selectedLabelStyle: AppTheme.mono(
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: AppTheme.mono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'OVERVIEW',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_box_outlined),
              activeIcon: Icon(Icons.check_box),
              label: 'TASKS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder),
              label: 'PROJECTS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'REPORTS',
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
            strokeWidth: 3,
            color: AppTheme.violentRed,
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
              color: const Color(0xFF1E1414),
              border: Border.all(color: AppTheme.violentRed, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONNECTION NOTICE',
                  style: AppTheme.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.violentRed,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _errorMessage!,
                  style: AppTheme.body(fontSize: 13, color: AppTheme.pureWhite),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadDashboard,
                  child: const Text('RETRY'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppTheme.violentRed,
      child: widget.user.isAdmin
          ? AdminDashboardView(
              user: widget.user,
              data: _dashboardData ?? {},
              onRefresh: _loadDashboard,
            )
          : StaffDashboardView(
              user: widget.user,
              data: _dashboardData ?? {},
              onRefresh: _loadDashboard,
            ),
    );
  }
}
