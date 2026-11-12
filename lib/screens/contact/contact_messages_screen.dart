import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/module_app_bar.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../models/user_model.dart';
import '../../services/dashboard_service.dart';

class ContactMessagesScreen extends StatefulWidget {
  final UserModel? currentUser;
  final DashboardService? dashboardService;

  const ContactMessagesScreen({
    super.key,
    this.currentUser,
    this.dashboardService,
  });

  @override
  State<ContactMessagesScreen> createState() => _ContactMessagesScreenState();
}

class _ContactMessagesScreenState extends State<ContactMessagesScreen> {
  late final DashboardService _service =
      widget.dashboardService ?? DashboardService();

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _messages = [];
  int _unreadCount = 0;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _service.getContactMessages(unreadOnly: _unreadOnly);
      if (mounted) {
        setState(() {
          _messages = (res['messages'] as List<dynamic>?) ?? [];
          _unreadCount = (res['unread_count'] as num?)?.toInt() ?? 0;
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

  Future<void> _handleMarkRead(int id) async {
    try {
      await _service.markContactMessageRead(id);
      if (mounted) {
        setState(() {
          for (final m in _messages) {
            if (m is Map<String, dynamic> && m['id'] == id) {
              m['is_read'] = 1;
            }
          }
          if (_unreadCount > 0) _unreadCount--;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerText),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteContactMessage(id);
        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => m['id'] == id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message deleted.'),
              backgroundColor: AppTheme.successText,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete message: $e'),
              backgroundColor: AppTheme.dangerText,
            ),
          );
        }
      }
    }
  }

  void _showReaderDialog(Map<String, dynamic> msg) {
    final id = msg['id'] is int
        ? msg['id'] as int
        : int.tryParse(msg['id']?.toString() ?? '0') ?? 0;
    if (msg['is_read'] == 0 || msg['is_read'] == false) {
      _handleMarkRead(id);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(msg['subject']?.toString() ?? 'Inquiry'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'From: ${msg['name']} (${msg['email']})',
                style: AppTheme.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
              if (msg['phone'] != null && msg['phone'].toString().isNotEmpty)
                Text(
                  'Phone: ${msg['phone']}',
                  style: AppTheme.body(
                    fontSize: 12,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              const Divider(height: 16),
              Text(
                msg['message']?.toString() ?? '',
                style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleDelete(id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.dangerText),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: ModuleAppBar(
        title: 'Contact Messages',
        subtitle: '$_unreadCount unread · ${_messages.length} total',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.royalBlue),
            tooltip: 'Refresh',
            onPressed: _fetchMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter toggle row
          Container(
            color: AppTheme.pureWhite,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unread messages: ',
                      style: AppTheme.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _unreadCount > 0
                            ? AppTheme.royalBlue
                            : AppTheme.borderSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: AppTheme.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                    ),
                  ],
                ),
                FilterChip(
                  label: const Text('Unread only'),
                  selected: _unreadOnly,
                  onSelected: (val) {
                    setState(() => _unreadOnly = val);
                    _fetchMessages();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderSubtle),

          // Message list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.royalBlue),
                  )
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: AppTheme.body(
                        fontSize: 14,
                        color: AppTheme.dangerText,
                      ),
                    ),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          size: 48,
                          color: AppTheme.mutedSlate,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Inbox is empty.',
                          style: AppTheme.body(
                            fontSize: 14,
                            color: AppTheme.mutedSlate,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppTheme.royalBlue,
                    onRefresh: _fetchMessages,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, idx) {
                        final msg = _messages[idx] as Map<String, dynamic>;
                        final isRead =
                            msg['is_read'] == 1 || msg['is_read'] == true;

                        return BrutalistPressable(
                          onTap: () => _showReaderDialog(msg),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? AppTheme.pureWhite
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isRead
                                    ? AppTheme.borderSubtle
                                    : AppTheme.royalBlue.withValues(alpha: 0.4),
                                width: isRead ? 1.0 : 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        msg['name']?.toString() ?? 'Anonymous',
                                        style: AppTheme.body(
                                          fontSize: 13,
                                          fontWeight: isRead
                                              ? FontWeight.w600
                                              : FontWeight.w800,
                                          color: AppTheme.deepSlate,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      msg['created_at']
                                              ?.toString()
                                              .split(' ')
                                              .first ??
                                          '',
                                      style: AppTheme.mono(
                                        fontSize: 10,
                                        color: AppTheme.mutedSlate,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg['subject']?.toString() ?? 'No Subject',
                                  style: AppTheme.heading(
                                    fontSize: 14,
                                    fontWeight: isRead
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                    color: AppTheme.deepSlate,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg['message']?.toString() ?? '',
                                  style: AppTheme.body(
                                    fontSize: 12,
                                    color: AppTheme.mutedSlate,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
