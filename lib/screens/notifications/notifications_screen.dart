import 'package:flutter/material.dart';
import '../../core/theme.dart';
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
          _notifications = (res['notifications'] as List<NotificationModel>?) ?? [];
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
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(
        title: Text(
          'NOTIFICATIONS',
          style: AppTheme.heading(fontSize: 16),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _handleMarkAllRead,
              child: Text(
                'MARK ALL READ',
                style: AppTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.violentRed, strokeWidth: 3),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _notifications.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: AppTheme.violentRed,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) => _buildNotificationCard(_notifications[idx]),
                      ),
                    ),
    );
  }

  Widget _buildNotificationCard(NotificationModel n) {
    return GestureDetector(
      onTap: () => _handleMarkSingleRead(n),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead ? const Color(0xFF141414) : AppTheme.pureWhite,
          border: Border.all(
            color: n.isRead ? const Color(0xFF333333) : AppTheme.pitchBlack,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: n.isRead ? Colors.transparent : AppTheme.violentRed,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              color: n.isRead ? const Color(0xFF222222) : AppTheme.pitchBlack,
              child: Icon(
                _getIconForType(n.type),
                size: 16,
                color: n.isRead ? const Color(0xFF888888) : AppTheme.pureWhite,
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
                            color: n.isRead ? AppTheme.pureWhite : AppTheme.pitchBlack,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          color: AppTheme.violentRed,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: AppTheme.body(
                      fontSize: 12,
                      color: n.isRead ? const Color(0xFFAAAAAA) : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n.createdAt,
                    style: AppTheme.mono(
                      fontSize: 10,
                      color: n.isRead ? const Color(0xFF666666) : const Color(0xFF888888),
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

  IconData _getIconForType(String type) {
    if (type.contains('task')) return Icons.task_alt;
    if (type.contains('report')) return Icons.assignment;
    if (type.contains('extension')) return Icons.access_time;
    if (type.contains('deadline')) return Icons.warning_amber;
    return Icons.notifications;
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, size: 48, color: AppTheme.pureWhite),
          const SizedBox(height: 12),
          Text('NO NOTIFICATIONS', style: AppTheme.heading(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            'You are all caught up!',
            style: AppTheme.body(fontSize: 13, color: const Color(0xFFAAAAAA)),
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
            color: const Color(0xFF1E1414),
            border: Border.all(color: AppTheme.violentRed, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FAILED TO LOAD NOTIFICATIONS', style: AppTheme.mono(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.violentRed)),
              const SizedBox(height: 8),
              Text(_errorMessage ?? 'Unknown error occurred.', style: AppTheme.body(color: AppTheme.pureWhite, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadNotifications,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.violentRed),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

