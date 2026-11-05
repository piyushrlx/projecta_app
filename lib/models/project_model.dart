int _asInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? fallback;
}

int? _asNullableInt(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString());
}

double? _asNullableDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString());
}

double _asDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? fallback;
}

class ProjectModel {
  final int id;
  final String projectCode;
  final String name;
  final String? clientName;
  final String? startDate;
  final String? deadline;
  final String? completedAt;
  final String priority;
  final String status;
  final double? budget;
  final int? departmentId;
  final String? departmentName;
  final int? managerId;
  final String? managerName;
  final int memberCount;
  final int totalTasks;
  final int doneTasks;
  final int pendingTasks;
  final int overdueTasks;
  final double completionPercent;
  final bool isWeighted;
  final bool canManage;
  final String? archivedAt;
  final List<Map<String, dynamic>> teamMembers;

  const ProjectModel({
    required this.id,
    required this.projectCode,
    required this.name,
    this.clientName,
    this.startDate,
    this.deadline,
    this.completedAt,
    required this.priority,
    required this.status,
    this.budget,
    this.departmentId,
    this.departmentName,
    this.managerId,
    this.managerName,
    this.memberCount = 0,
    this.totalTasks = 0,
    this.doneTasks = 0,
    this.pendingTasks = 0,
    this.overdueTasks = 0,
    this.completionPercent = 0.0,
    this.isWeighted = false,
    this.canManage = false,
    this.archivedAt,
    this.teamMembers = const [],
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isAtRisk => overdueTasks > 0 || status == 'on_hold' || isOverdue;
  bool get isArchived => archivedAt != null && archivedAt!.isNotEmpty;

  /// True if deadline is past and status is not completed/cancelled (matching web projects.php line 158)
  bool get isOverdue {
    if (deadline == null || deadline!.isEmpty) return false;
    if (status == 'completed' || status == 'cancelled') return false;
    try {
      final d = DateTime.parse(deadline!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dead = DateTime(d.year, d.month, d.day);
      return dead.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  /// Days late if overdue (matching web days_between(deadline, today))
  int get daysOverdue {
    if (!isOverdue) return 0;
    try {
      final d = DateTime.parse(deadline!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dead = DateTime(d.year, d.month, d.day);
      return today.difference(dead).inDays;
    } catch (_) {
      return 0;
    }
  }

  /// Formatted days label matching web project-details.php (e.g. '30 days remaining', 'Due today', '2 days overdue')
  String? get deadlineDaysLabel {
    if (deadline == null || deadline!.isEmpty) return null;
    if (status == 'completed' || status == 'cancelled') return null;
    try {
      final d = DateTime.parse(deadline!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dead = DateTime(d.year, d.month, d.day);
      final diff = dead.difference(today).inDays;
      if (diff < 0) {
        final absDiff = diff.abs();
        return '$absDiff day${absDiff == 1 ? '' : 's'} overdue';
      } else if (diff == 0) {
        return 'Due today';
      } else {
        return '$diff day${diff == 1 ? '' : 's'} remaining';
      }
    } catch (_) {
      return null;
    }
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final teamList = (json['team_members'] as List<dynamic>?) ?? [];
    return ProjectModel(
      id: _asInt(json['id']),
      projectCode: json['project_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      clientName: json['client_name']?.toString(),
      startDate: json['start_date']?.toString(),
      deadline: json['deadline']?.toString(),
      completedAt: json['completed_at']?.toString(),
      archivedAt: json['archived_at']?.toString(),
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'planned',
      budget: _asNullableDouble(json['budget']),
      departmentId: _asNullableInt(json['department_id']),
      departmentName: json['department_name']?.toString(),
      managerId: _asNullableInt(json['manager_id']),
      managerName: json['manager_name']?.toString(),
      memberCount: _asInt(json['member_count']),
      totalTasks: _asInt(json['total_tasks']),
      doneTasks: _asInt(json['done_tasks']),
      pendingTasks: _asInt(json['pending_tasks']),
      overdueTasks: _asInt(json['overdue_tasks']),
      completionPercent: _asDouble(json['completion_percent']),
      isWeighted: json['is_weighted'] == true ||
          json['is_weighted'] == 1 ||
          json['progress_method'] == 'weighted',
      canManage: json['can_manage'] == true || json['can_manage'] == 1,
      teamMembers: teamList.map((t) => Map<String, dynamic>.from(t as Map)).toList(),
    );
  }
}

class ProjectMemberModel {
  final int id;
  final int userId;
  final String memberRole;
  final String? addedAt;
  final String fullName;
  final String? username;
  final String? email;
  final String? designation;
  final String? profilePhotoUrl;
  final int openTasks;

  const ProjectMemberModel({
    required this.id,
    required this.userId,
    required this.memberRole,
    this.addedAt,
    required this.fullName,
    this.username,
    this.email,
    this.designation,
    this.profilePhotoUrl,
    this.openTasks = 0,
  });

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    return ProjectMemberModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      memberRole: json['member_role']?.toString() ?? 'member',
      addedAt: json['added_at']?.toString(),
      fullName: json['full_name']?.toString() ?? '',
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      designation: json['designation']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      openTasks: _asInt(json['open_tasks']),
    );
  }
}

class ProjectMilestoneModel {
  final int id;
  final int projectId;
  final String title;
  final String? description;
  final String? deliverables;
  final String? dueDate;
  final String status;
  final String? completedAt;
  final int sortOrder;
  final int taskCount;

  const ProjectMilestoneModel({
    required this.id,
    this.projectId = 0,
    required this.title,
    this.description,
    this.deliverables,
    this.dueDate,
    required this.status,
    this.completedAt,
    this.sortOrder = 0,
    this.taskCount = 0,
  });

  bool get isCompleted => status == 'completed';

  bool get isOverdue {
    if (isCompleted || dueDate == null || dueDate!.isEmpty) return false;
    try {
      final parsed = DateTime.parse(dueDate!);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      return parsed.isBefore(todayDate);
    } catch (_) {
      return false;
    }
  }

  ProjectMilestoneModel copyWith({
    int? id,
    int? projectId,
    String? title,
    String? description,
    String? deliverables,
    String? dueDate,
    String? status,
    String? completedAt,
    int? sortOrder,
    int? taskCount,
  }) {
    return ProjectMilestoneModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      deliverables: deliverables ?? this.deliverables,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      taskCount: taskCount ?? this.taskCount,
    );
  }

  factory ProjectMilestoneModel.fromJson(Map<String, dynamic> json) {
    return ProjectMilestoneModel(
      id: _asInt(json['id']),
      projectId: _asInt(json['project_id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      deliverables: json['deliverables']?.toString(),
      dueDate: json['due_date']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      completedAt: json['completed_at']?.toString(),
      sortOrder: _asInt(json['sort_order']),
      taskCount: _asInt(json['task_count']),
    );
  }
}

class ProjectTaskCountsModel {
  final int total;
  final int notStarted;
  final int inProgress;
  final int blocked;
  final int pendingReview;
  final int completed;
  final int cancelled;

  const ProjectTaskCountsModel({
    this.total = 0,
    this.notStarted = 0,
    this.inProgress = 0,
    this.blocked = 0,
    this.pendingReview = 0,
    this.completed = 0,
    this.cancelled = 0,
  });

  factory ProjectTaskCountsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProjectTaskCountsModel();
    return ProjectTaskCountsModel(
      total: _asInt(json['total']),
      notStarted: _asInt(json['not_started']),
      inProgress: _asInt(json['in_progress']),
      blocked: _asInt(json['blocked']),
      pendingReview: _asInt(json['pending_review']),
      completed: _asInt(json['completed']),
      cancelled: _asInt(json['cancelled']),
    );
  }
}

class ProjectActivityModel {
  final int id;
  final String activityType;
  final String description;
  final String createdAt;
  final String? userName;

  const ProjectActivityModel({
    required this.id,
    required this.activityType,
    required this.description,
    required this.createdAt,
    this.userName,
  });

  factory ProjectActivityModel.fromJson(Map<String, dynamic> json) {
    return ProjectActivityModel(
      id: _asInt(json['id']),
      activityType: json['activity_type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      userName: json['user_name']?.toString(),
    );
  }
}

class ProjectDetailModel {
  final ProjectModel project;
  final String? description;
  final String? objectives;
  final String? scopeOfWork;
  final String? deliverables;
  final String? acceptanceCriteria;
  final String? internalNotes;
  final String? managerEmail;
  final List<ProjectMemberModel> members;
  final List<ProjectMilestoneModel> milestones;
  final ProjectTaskCountsModel taskCounts;
  final List<ProjectActivityModel> recentActivity;

  const ProjectDetailModel({
    required this.project,
    this.description,
    this.objectives,
    this.scopeOfWork,
    this.deliverables,
    this.acceptanceCriteria,
    this.internalNotes,
    this.managerEmail,
    this.members = const [],
    this.milestones = const [],
    this.taskCounts = const ProjectTaskCountsModel(),
    this.recentActivity = const [],
  });

  factory ProjectDetailModel.fromJson(Map<String, dynamic> json) {
    final projJson = (json['project'] as Map<String, dynamic>?) ?? {};
    final membersJson = (json['members'] as List<dynamic>?) ?? [];
    final milestonesJson = (json['milestones'] as List<dynamic>?) ?? [];
    final countsJson = (json['task_counts'] as Map<String, dynamic>?);
    final activityJson = (json['recent_activity'] as List<dynamic>?) ?? [];

    return ProjectDetailModel(
      project: ProjectModel.fromJson(projJson),
      description: projJson['description']?.toString(),
      objectives: projJson['objectives']?.toString(),
      scopeOfWork: projJson['scope_of_work']?.toString(),
      deliverables: projJson['deliverables']?.toString(),
      acceptanceCriteria: projJson['acceptance_criteria']?.toString(),
      internalNotes: projJson['internal_notes']?.toString(),
      managerEmail: projJson['manager_email']?.toString(),
      members: membersJson
          .map((m) => ProjectMemberModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      milestones: milestonesJson
          .map((m) => ProjectMilestoneModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      taskCounts: ProjectTaskCountsModel.fromJson(countsJson),
      recentActivity: activityJson
          .map((a) => ProjectActivityModel.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

