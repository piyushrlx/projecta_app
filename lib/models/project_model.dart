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
  final int overdueTasks;
  final double completionPercent;
  final bool isWeighted;
  final bool canManage;

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
    this.overdueTasks = 0,
    this.completionPercent = 0.0,
    this.isWeighted = false,
    this.canManage = false,
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isAtRisk => overdueTasks > 0 || status == 'on_hold';

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      projectCode: json['project_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      clientName: json['client_name']?.toString(),
      startDate: json['start_date']?.toString(),
      deadline: json['deadline']?.toString(),
      completedAt: json['completed_at']?.toString(),
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'planned',
      budget: (json['budget'] as num?)?.toDouble(),
      departmentId: (json['department_id'] as num?)?.toInt(),
      departmentName: json['department_name']?.toString(),
      managerId: (json['manager_id'] as num?)?.toInt(),
      managerName: json['manager_name']?.toString(),
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      doneTasks: (json['done_tasks'] as num?)?.toInt() ?? 0,
      overdueTasks: (json['overdue_tasks'] as num?)?.toInt() ?? 0,
      completionPercent: (json['completion_percent'] as num?)?.toDouble() ?? 0.0,
      isWeighted: json['is_weighted'] == true || json['is_weighted'] == 1,
      canManage: json['can_manage'] == true || json['can_manage'] == 1,
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
  });

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    return ProjectMemberModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      memberRole: json['member_role']?.toString() ?? 'member',
      addedAt: json['added_at']?.toString(),
      fullName: json['full_name']?.toString() ?? '',
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      designation: json['designation']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
    );
  }
}

class ProjectMilestoneModel {
  final int id;
  final String title;
  final String? description;
  final String? deliverables;
  final String? dueDate;
  final String status;
  final String? completedAt;
  final int sortOrder;

  const ProjectMilestoneModel({
    required this.id,
    required this.title,
    this.description,
    this.deliverables,
    this.dueDate,
    required this.status,
    this.completedAt,
    this.sortOrder = 0,
  });

  bool get isCompleted => status == 'completed';

  factory ProjectMilestoneModel.fromJson(Map<String, dynamic> json) {
    return ProjectMilestoneModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      deliverables: json['deliverables']?.toString(),
      dueDate: json['due_date']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      completedAt: json['completed_at']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
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
      total: (json['total'] as num?)?.toInt() ?? 0,
      notStarted: (json['not_started'] as num?)?.toInt() ?? 0,
      inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
      blocked: (json['blocked'] as num?)?.toInt() ?? 0,
      pendingReview: (json['pending_review'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
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
      id: (json['id'] as num?)?.toInt() ?? 0,
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

