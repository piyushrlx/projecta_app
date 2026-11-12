import 'package:flutter/material.dart';
import '../../core/notification_router.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../core/widgets/module_app_bar.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final UserModel? user;
  final NotificationService? notificationService;

  const NotificationsScreen({super.key, this.user, this.notificationService});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _notificationService =
      widget.notificationService ?? NotificationService();

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  String _selectedFilter =
      'ALL'; // 'ALL', 'UNREAD', 'TASKS', 'PROJECTS', 'REPORTS'

  static const List<String> _filters = [
    'ALL',
    'UNREAD',
    'TASKS',
    'PROJECTS',
    'REPORTS',
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    if (_currentUser == null) {
      _loadCurrentUser();
    }
    _loadNotifications();
  }

  Future<void> _loadCurrentUser() async {
    final user =
        AuthService().currentUser ?? await AuthService().getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _loadNotifications({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final res = await _notificationService.getNotifications(limit: 50);
      if (mounted) {
        setState(() {
          _notifications =
              (res['notifications'] as List<NotificationModel>?) ?? [];
          _unreadCount = (res['unread_count'] as num?)?.toInt() ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!isBackground) {
            _errorMessage = e.toString().replaceAll('ApiException', '').trim();
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleMarkAllRead() async {
    if (_unreadCount == 0) return;

    // Optimistic UI update
    setState(() {
      _unreadCount = 0;
      _notifications = _notifications
          .map((item) => item.copyWith(isRead: true))
          .toList();
    });

    try {
      await _notificationService.markAllRead();
    } catch (_) {
      // Re-fetch in background if failed
      if (mounted) {
        _loadNotifications(isBackground: true);
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel n) async {
    // Optimistic mark-as-read
    if (!n.isRead) {
      setState(() {
        _unreadCount = (_unreadCount - 1).clamp(0, 99999);
        final index = _notifications.indexWhere((item) => item.id == n.id);
        if (index != -1) {
          _notifications[index] = n.copyWith(isRead: true);
        }
      });
      _notificationService.markRead(n.id).catchError((_) {});
    }

    // Execute deep-linking navigation
    final navigated = await NotificationRouter.navigate(
      context,
      n,
      user: _currentUser,
    );

    if (navigated && mounted) {
      // Refresh notifications feed on return silently without full-screen flicker
      _loadNotifications(isBackground: true);
    } else if (!navigated && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification marked as read.',
            style: AppTheme.body(color: AppTheme.pureWhite, fontSize: 13),
          ),
          backgroundColor: AppTheme.pitchBlack,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleMarkSingleRead(NotificationModel n) async {
    if (n.isRead) return;

    setState(() {
      _unreadCount = (_unreadCount - 1).clamp(0, 99999);
      final index = _notifications.indexWhere((item) => item.id == n.id);
      if (index != -1) {
        _notifications[index] = n.copyWith(isRead: true);
      }
    });

    try {
      await _notificationService.markRead(n.id);
    } catch (_) {
      if (mounted) {
        _loadNotifications(isBackground: true);
      }
    }
  }

  List<NotificationModel> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'UNREAD':
        return _notifications.where((n) => !n.isRead).toList();
      case 'TASKS':
        return _notifications.where((n) => n.category == 'task').toList();
      case 'PROJECTS':
        return _notifications.where((n) => n.category == 'project').toList();
      case 'REPORTS':
        return _notifications.where((n) => n.category == 'report').toList();
      case 'ALL':
      default:
        return _notifications;
    }
  }

  int _getCountForFilter(String filter) {
    switch (filter) {
      case 'UNREAD':
        return _notifications.where((n) => !n.isRead).length;
      case 'TASKS':
        return _notifications.where((n) => n.category == 'task').length;
      case 'PROJECTS':
        return _notifications.where((n) => n.category == 'project').length;
      case 'REPORTS':
        return _notifications.where((n) => n.category == 'report').length;
      case 'ALL':
      default:
        return _notifications.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredNotifications;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: ModuleAppBar(
        title: 'Notifications',
        subtitle: _unreadCount > 0
            ? '$_unreadCount unread · ${_notifications.length} total'
            : '${_notifications.length} notification${_notifications.length == 1 ? '' : 's'}',
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _handleMarkAllRead,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Mark all read',
                style: AppTheme.heading(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.royalBlue,
                ),
              ),
            ),
          IconButton(
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.refresh, color: AppTheme.deepSlate),
            tooltip: 'Refresh',
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          _buildFilterBar(),

          // Main Feed
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
                : filteredList.isEmpty
                ? _buildEmptyView()
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    color: AppTheme.royalBlue,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) =>
                          _buildNotificationCard(filteredList[idx]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      color: AppTheme.pureWhite,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            final count = _getCountForFilter(filter);

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: BrutalistPressable(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                backgroundColor: isSelected
                    ? AppTheme.pitchBlack
                    : AppTheme.pureWhite,
                borderColor: isSelected
                    ? AppTheme.pitchBlack
                    : AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter,
                      style: AppTheme.heading(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? AppTheme.pureWhite
                            : AppTheme.mutedSlate,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (filter == 'UNREAD' && count > 0
                                    ? AppTheme.dangerText
                                    : AppTheme.pureWhite.withValues(
                                        alpha: 0.25,
                                      ))
                              : (filter == 'UNREAD' && count > 0
                                    ? AppTheme.dangerText
                                    : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: AppTheme.mono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppTheme.pureWhite
                                : (filter == 'UNREAD' && count > 0
                                      ? AppTheme.pureWhite
                                      : AppTheme.deepSlate),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel n) {
    final routeInfo = NotificationRouter.parse(n);
    final isNavigable = routeInfo.target != NotificationRouteTarget.none;
    final isUrgent = n.isUrgent;

    // Background and border styling
    Color bgColor;
    Color borderColor;

    if (!n.isRead) {
      if (isUrgent) {
        bgColor = const Color(0xFFFFF5F5);
        borderColor = const Color(0xFFFECACA);
      } else {
        bgColor = const Color(0xFFF0F7FF);
        borderColor = const Color(0xFFBFDBFE);
      }
    } else {
      bgColor = AppTheme.pureWhite;
      borderColor = AppTheme.borderSubtle;
    }

    return BrutalistPressable(
      onTap: () => _handleNotificationTap(n),
      backgroundColor: bgColor,
      borderColor: borderColor,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leading Type Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: !n.isRead
                  ? (isUrgent ? AppTheme.dangerBg : AppTheme.infoBg)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForType(n.type),
              size: 18,
              color: !n.isRead
                  ? (isUrgent ? AppTheme.dangerText : AppTheme.infoText)
                  : AppTheme.mutedSlate,
            ),
          ),
          const SizedBox(width: 12),

          // Notification Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: AppTheme.heading(
                          fontSize: 14,
                          fontWeight: n.isRead
                              ? FontWeight.w600
                              : FontWeight.w700,
                          color: isUrgent && !n.isRead
                              ? AppTheme.dangerText
                              : AppTheme.deepSlate,
                        ),
                      ),
                    ),
                    if (!n.isRead) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? AppTheme.dangerText
                              : AppTheme.royalBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isUrgent ? 'URGENT' : 'NEW',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  n.message,
                  style: AppTheme.body(
                    fontSize: 13,
                    color: n.isRead ? AppTheme.mutedSlate : AppTheme.deepSlate,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        n.createdAt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(
                          fontSize: 11,
                          color: AppTheme.lightSlate,
                        ),
                      ),
                    ),
                    if (!n.isRead)
                      InkWell(
                        onTap: () => _handleMarkSingleRead(n),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            'Mark read',
                            style: AppTheme.heading(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.royalBlue,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Trailing Deep Link Chevron Indicator
          if (isNavigable) ...[
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppTheme.lightSlate,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'task_assigned':
      case 'task_status_changed':
        return Icons.task_alt_outlined;
      case 'deadline_reminder':
      case 'overdue':
        return Icons.timer_outlined;
      case 'stale_task':
        return Icons.update_outlined;
      case 'extension_requested':
      case 'extension_decided':
        return Icons.more_time_outlined;
      case 'report_submitted':
      case 'report_reviewed':
        return Icons.assignment_outlined;
      case 'report_missing':
      case 'compliance_alert':
        return Icons.warning_amber_rounded;
      case 'project_assigned':
      case 'project_update':
        return Icons.folder_open_outlined;
      case 'comment':
      case 'mention':
        return Icons.chat_bubble_outline;
      case 'registration':
      case 'account_activated':
        return Icons.person_add_outlined;
      case 'password_reset':
        return Icons.lock_reset_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Widget _buildEmptyView() {
    String title = 'All Caught Up';
    String subtitle = 'You have no notifications in this category.';

    if (_selectedFilter == 'UNREAD') {
      title = 'No Unread Alerts';
      subtitle = 'You have read all your notifications.';
    } else if (_selectedFilter == 'TASKS') {
      title = 'No Task Alerts';
      subtitle = 'No task updates or deadline alerts found.';
    } else if (_selectedFilter == 'PROJECTS') {
      title = 'No Project Alerts';
      subtitle = 'No project assignment or status updates.';
    } else if (_selectedFilter == 'REPORTS') {
      title = 'No Report Alerts';
      subtitle = 'No pending work report or review notifications.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none_outlined,
            size: 48,
            color: AppTheme.mutedSlate,
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTheme.heading(fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTheme.body(color: AppTheme.mutedSlate)),
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
                'Failed to load notifications',
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
                onPressed: _loadNotifications,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
