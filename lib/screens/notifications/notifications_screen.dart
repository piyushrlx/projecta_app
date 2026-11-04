import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _notificationService.getNotifications();
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
          _errorMessage = e.toString().replaceAll('ApiException', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleMarkAllRead() async {
    try {
      await _notificationService.markAllRead();
      _loadNotifications();
    } catch (_) {}
  }

  Future<void> _handleMarkSingleRead(NotificationModel n) async {
    if (n.isRead) return;
    try {
      await _notificationService.markRead(n.id);
      _loadNotifications();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text('Notifications', style: AppTheme.heading(fontSize: 18)),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _handleMarkAllRead,
              child: Text(
                'Mark all read',
                style: AppTheme.heading(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.royalBlue,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.deepSlate),
            tooltip: 'Refresh',
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.royalBlue,
                strokeWidth: 2.5,
              ),
            )
          : _errorMessage != null
          ? _buildErrorView()
          : _notifications.isEmpty
          ? _buildEmptyView()
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: AppTheme.royalBlue,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) =>
                    _buildNotificationCard(_notifications[idx]),
              ),
            ),
    );
  }

  Widget _buildNotificationCard(NotificationModel n) {
    return BrutalistPressable(
      onTap: () => _handleMarkSingleRead(n),
      backgroundColor: n.isRead ? AppTheme.pureWhite : const Color(0xFFF0F7FF),
      borderColor: n.isRead ? AppTheme.borderSubtle : const Color(0xFFBFDBFE),
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: n.isRead ? const Color(0xFFF1F5F9) : AppTheme.infoBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForType(n.type),
              size: 18,
              color: n.isRead ? AppTheme.mutedSlate : AppTheme.infoText,
            ),
          ),
          const SizedBox(width: 12),
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
                          color: AppTheme.deepSlate,
                        ),
                      ),
                    ),
                    if (!n.isRead)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.royalBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'New',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                      ),
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
                const SizedBox(height: 6),
                Text(
                  n.createdAt,
                  style: AppTheme.body(
                    fontSize: 11,
                    color: AppTheme.lightSlate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'task_assigned':
      case 'task_status_changed':
        return Icons.task_alt_outlined;
      case 'extension_requested':
      case 'extension_decided':
        return Icons.more_time_outlined;
      case 'report_submitted':
      case 'report_reviewed':
        return Icons.assignment_outlined;
      case 'compliance_alert':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Widget _buildEmptyView() {
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
          Text('All Caught Up', style: AppTheme.heading(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'You have no new alerts or notifications.',
            style: AppTheme.body(color: AppTheme.mutedSlate),
          ),
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
