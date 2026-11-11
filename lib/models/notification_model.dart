class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final String? link;
  final bool isRead;
  final String? readAt;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.link,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'info',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      link: json['link']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      readAt: json['read_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  NotificationModel copyWith({
    int? id,
    String? type,
    String? title,
    String? message,
    String? link,
    bool? isRead,
    String? readAt,
    String? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      link: link ?? this.link,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Extracts target numerical ID from link (e.g. `task-details.php?id=42` -> 42)
  int? get targetEntityId {
    final rawLink = link;
    if (rawLink == null || rawLink.isEmpty) return null;
    final idMatch = RegExp(r'[?&]id=(\d+)').firstMatch(rawLink);
    if (idMatch != null) {
      return int.tryParse(idMatch.group(1)!);
    }
    // Also support path format like /tasks/42 or /projects/42
    final pathMatch = RegExp(r'/(\d+)(?:[/?#]|$)').firstMatch(rawLink);
    if (pathMatch != null) {
      return int.tryParse(pathMatch.group(1)!);
    }
    return null;
  }

  /// Categorizes notification into functional domains: task, project, report, team, or system
  String get category {
    final t = type.toLowerCase();
    final l = (link ?? '').toLowerCase();
    final txt = '$title $message'.toLowerCase();

    if (t.contains('task') ||
        t.contains('extension') ||
        t == 'deadline_reminder' ||
        t == 'overdue' ||
        t == 'stale_task' ||
        l.contains('task')) {
      return 'task';
    }
    if (t.contains('project') || l.contains('project')) {
      return 'project';
    }
    if (t.contains('report') ||
        t == 'compliance_alert' ||
        l.contains('report') ||
        l.contains('compliance')) {
      return 'report';
    }
    if (t == 'registration' ||
        t == 'account_activated' ||
        t == 'password_reset' ||
        t == 'exemption_added' ||
        l.contains('employee') ||
        l.contains('department')) {
      return 'team';
    }
    if (t == 'comment' || t == 'mention') {
      if (txt.contains('task')) return 'task';
      if (txt.contains('report')) return 'report';
      return 'project';
    }
    return 'system';
  }

  /// Returns true for critical or urgent notifications
  bool get isUrgent {
    final t = type.toLowerCase();
    return t == 'overdue' ||
        t == 'report_missing' ||
        t == 'compliance_alert' ||
        t == 'stale_task' ||
        title.toLowerCase().contains('overdue') ||
        title.toLowerCase().contains('urgent');
  }
}
