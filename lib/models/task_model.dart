import '../core/app_date_utils.dart';

int _asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? fallback;
  return fallback;
}

int? _asNullableInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt();
  return null;
}

double? _asNullableDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class TaskAssigneeModel {
  final int userId;
  final String fullName;
  final String responsibility; // 'owner' or 'contributor'
  final String? profilePhotoUrl;
  final String? email;
  final String? designation;

  const TaskAssigneeModel({
    required this.userId,
    required this.fullName,
    this.responsibility = 'owner',
    this.profilePhotoUrl,
    this.email,
    this.designation,
  });

  bool get isOwner => responsibility == 'owner';

  factory TaskAssigneeModel.fromJson(Map<String, dynamic> json) {
    return TaskAssigneeModel(
      userId: _asInt(json['user_id']),
      fullName: json['full_name']?.toString() ?? '',
      responsibility: json['responsibility']?.toString() ?? 'owner',
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      email: json['email']?.toString(),
      designation: json['designation']?.toString(),
    );
  }
}

class TaskModel {
  final int id;
  final String taskCode;
  final int projectId;
  final String? projectName;
  final String? projectCode;
  final int? milestoneId;
  final String? milestoneTitle;
  final int? parentTaskId;
  final String title;
  final String? startDate;
  final String? deadline;
  final String? originalDeadline;
  final String priority;
  final String status;
  final double? estimatedHours;
  final int actualMinutes;
  final int progress;
  final String? completedAt;
  final String? lastUpdateAt;
  final int openDependenciesCount;
  final int subtaskCount;
  final bool isOverdue;
  final int overdueDays;
  final List<TaskAssigneeModel> assignees;
  final List<String> allowedStatuses;

  const TaskModel({
    required this.id,
    required this.taskCode,
    required this.projectId,
    this.projectName,
    this.projectCode,
    this.milestoneId,
    this.milestoneTitle,
    this.parentTaskId,
    required this.title,
    this.startDate,
    this.deadline,
    this.originalDeadline,
    required this.priority,
    required this.status,
    this.estimatedHours,
    this.actualMinutes = 0,
    this.progress = 0,
    this.completedAt,
    this.lastUpdateAt,
    this.openDependenciesCount = 0,
    this.subtaskCount = 0,
    this.isOverdue = false,
    this.overdueDays = 0,
    this.assignees = const [],
    this.allowedStatuses = const [],
  });

  bool get isLocked => openDependenciesCount > 0;
  bool get isCompleted => status == 'completed';
  bool get isBlocked => status == 'blocked';
  bool get isInProgress => status == 'in_progress';
  bool get isPendingReview => status == 'pending_review';
  bool isStatusAllowed(String target) => allowedStatuses.contains(target);
  String get formattedDeadline => AppDateUtils.fmtDate(deadline, fallback: 'No date');

  List<String> nextAllowedStatusesFor(String targetStatus) {
    final isManager = allowedStatuses.contains('completed');
    if (isManager) {
      return const [
        'not_started',
        'in_progress',
        'blocked',
        'pending_review',
        'completed',
      ];
    }
    switch (targetStatus) {
      case 'not_started':
        final list = <String>['not_started', 'blocked'];
        if (!isLocked) list.add('in_progress');
        return list;
      case 'in_progress':
        return const [
          'not_started',
          'in_progress',
          'blocked',
          'pending_review',
        ];
      case 'blocked':
        final list = <String>['blocked', 'not_started'];
        if (!isLocked) list.add('in_progress');
        return list;
      case 'pending_review':
        return const ['in_progress', 'pending_review'];
      case 'completed':
        return const ['completed'];
      default:
        return allowedStatuses;
    }
  }

  TaskModel copyWith({
    int? id,
    String? taskCode,
    int? projectId,
    String? projectName,
    String? projectCode,
    int? milestoneId,
    String? milestoneTitle,
    int? parentTaskId,
    String? title,
    String? startDate,
    String? deadline,
    String? originalDeadline,
    String? priority,
    String? status,
    double? estimatedHours,
    int? actualMinutes,
    int? progress,
    String? completedAt,
    String? lastUpdateAt,
    int? openDependenciesCount,
    int? subtaskCount,
    bool? isOverdue,
    int? overdueDays,
    List<TaskAssigneeModel>? assignees,
    List<String>? allowedStatuses,
  }) {
    return TaskModel(
      id: id ?? this.id,
      taskCode: taskCode ?? this.taskCode,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      projectCode: projectCode ?? this.projectCode,
      milestoneId: milestoneId ?? this.milestoneId,
      milestoneTitle: milestoneTitle ?? this.milestoneTitle,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      originalDeadline: originalDeadline ?? this.originalDeadline,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      progress: progress ?? this.progress,
      completedAt: completedAt ?? this.completedAt,
      lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
      openDependenciesCount:
          openDependenciesCount ?? this.openDependenciesCount,
      subtaskCount: subtaskCount ?? this.subtaskCount,
      isOverdue: isOverdue ?? this.isOverdue,
      overdueDays: overdueDays ?? this.overdueDays,
      assignees: assignees ?? this.assignees,
      allowedStatuses: allowedStatuses ?? this.allowedStatuses,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawAssignees = (json['assignees'] as List<dynamic>?) ?? [];
    return TaskModel(
      id: _asInt(json['id']),
      taskCode: json['task_code']?.toString() ?? '',
      projectId: _asInt(json['project_id']),
      projectName: json['project_name']?.toString(),
      projectCode: json['project_code']?.toString(),
      milestoneId: _asNullableInt(json['milestone_id']),
      milestoneTitle: json['milestone_title']?.toString(),
      parentTaskId: _asNullableInt(json['parent_task_id']),
      title: json['title']?.toString() ?? '',
      startDate: json['start_date']?.toString(),
      deadline: json['deadline']?.toString(),
      originalDeadline: json['original_deadline']?.toString(),
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'not_started',
      estimatedHours: _asNullableDouble(json['estimated_hours']),
      actualMinutes: _asInt(json['actual_minutes']),
      progress: _asInt(json['progress']),
      completedAt: json['completed_at']?.toString(),
      lastUpdateAt: json['last_update_at']?.toString(),
      openDependenciesCount: _asInt(json['open_dependencies_count']),
      subtaskCount: _asInt(json['subtask_count']),
      isOverdue: json['is_overdue'] == true || json['is_overdue'] == 1,
      overdueDays: _asInt(json['overdue_days']),
      assignees: rawAssignees
          .map((a) => TaskAssigneeModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      allowedStatuses: (json['allowed_statuses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class TaskDependencyModel {
  final int id;
  final String taskCode;
  final String title;
  final String status;
  final int progress;

  const TaskDependencyModel({
    required this.id,
    required this.taskCode,
    required this.title,
    required this.status,
    this.progress = 0,
  });

  bool get isFinished => status == 'completed' || status == 'cancelled';

  factory TaskDependencyModel.fromJson(Map<String, dynamic> json) {
    return TaskDependencyModel(
      id: _asInt(json['id']),
      taskCode: json['task_code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'not_started',
      progress: _asInt(json['progress']),
    );
  }
}

class SubtaskModel {
  final int id;
  final String taskCode;
  final String title;
  final String? deadline;
  final String priority;
  final String status;
  final int progress;

  const SubtaskModel({
    required this.id,
    required this.taskCode,
    required this.title,
    this.deadline,
    required this.priority,
    required this.status,
    this.progress = 0,
  });

  bool get isCompleted => status == 'completed';

  factory SubtaskModel.fromJson(Map<String, dynamic> json) {
    return SubtaskModel(
      id: _asInt(json['id']),
      taskCode: json['task_code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      deadline: json['deadline']?.toString(),
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'not_started',
      progress: _asInt(json['progress']),
    );
  }
}

class TaskExtensionRequestModel {
  final int id;
  final int taskId;
  final int requestedBy;
  final String requesterName;
  final String? currentDeadline;
  final String requestedDeadline;
  final String reason;
  final String status; // pending, approved, rejected
  final int? decidedBy;
  final String? deciderName;
  final String? decisionNote;
  final String? decidedAt;
  final String createdAt;

  const TaskExtensionRequestModel({
    required this.id,
    required this.taskId,
    required this.requestedBy,
    required this.requesterName,
    this.currentDeadline,
    required this.requestedDeadline,
    required this.reason,
    required this.status,
    this.decidedBy,
    this.deciderName,
    this.decisionNote,
    this.decidedAt,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory TaskExtensionRequestModel.fromJson(Map<String, dynamic> json) {
    return TaskExtensionRequestModel(
      id: _asInt(json['id']),
      taskId: _asInt(json['task_id']),
      requestedBy: _asInt(json['requested_by']),
      requesterName: json['requester_name']?.toString() ?? '',
      currentDeadline: json['current_deadline']?.toString(),
      requestedDeadline: json['requested_deadline']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      decidedBy: _asNullableInt(json['decided_by']),
      deciderName: json['decider_name']?.toString(),
      decisionNote: json['decision_note']?.toString(),
      decidedAt: json['decided_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class TaskStatusHistoryModel {
  final int id;
  final String? oldStatus;
  final String newStatus;
  final int? oldProgress;
  final int? newProgress;
  final String? changedByName;
  final String? note;
  final String createdAt;

  const TaskStatusHistoryModel({
    required this.id,
    this.oldStatus,
    required this.newStatus,
    this.oldProgress,
    this.newProgress,
    this.changedByName,
    this.note,
    required this.createdAt,
  });

  factory TaskStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return TaskStatusHistoryModel(
      id: _asInt(json['id']),
      oldStatus: json['old_status']?.toString(),
      newStatus: json['new_status']?.toString() ?? '',
      oldProgress: _asNullableInt(json['old_progress']),
      newProgress: _asNullableInt(json['new_progress']),
      changedByName: json['changed_by_name']?.toString(),
      note: json['note']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class TaskDetailModel {
  final TaskModel task;
  final String? description;
  final String? instructions;
  final String? completionNotes;
  final bool canManage;
  final bool canWork;
  final List<String> allowedStatuses;
  final List<TaskAssigneeModel> assignees;
  final List<SubtaskModel> subtasks;
  final List<TaskDependencyModel> dependsOn;
  final List<TaskDependencyModel> dependentTasks;
  final List<TaskExtensionRequestModel> extensionRequests;
  final List<TaskStatusHistoryModel> statusHistory;
  final int commentsCount;

  const TaskDetailModel({
    required this.task,
    this.description,
    this.instructions,
    this.completionNotes,
    this.canManage = false,
    this.canWork = false,
    this.allowedStatuses = const [],
    this.assignees = const [],
    this.subtasks = const [],
    this.dependsOn = const [],
    this.dependentTasks = const [],
    this.extensionRequests = const [],
    this.statusHistory = const [],
    this.commentsCount = 0,
  });

  factory TaskDetailModel.fromJson(Map<String, dynamic> json) {
    final tJson = (json['task'] as Map<String, dynamic>?) ?? {};
    final assigneesJson = (json['assignees'] as List<dynamic>?) ?? [];
    final subtasksJson = (json['subtasks'] as List<dynamic>?) ?? [];
    final dependsOnJson = (json['depends_on'] as List<dynamic>?) ?? [];
    final dependentJson = (json['dependent_tasks'] as List<dynamic>?) ?? [];
    final extJson = (json['extension_requests'] as List<dynamic>?) ?? [];
    final historyJson = (json['status_history'] as List<dynamic>?) ?? [];
    final rawStatuses = (tJson['allowed_statuses'] as List<dynamic>?) ?? [];

    return TaskDetailModel(
      task: TaskModel.fromJson(tJson),
      description: tJson['description']?.toString(),
      instructions: tJson['instructions']?.toString(),
      completionNotes: tJson['completion_notes']?.toString(),
      canManage: tJson['can_manage'] == true || tJson['can_manage'] == 1,
      canWork: tJson['can_work'] == true || tJson['can_work'] == 1,
      allowedStatuses: rawStatuses.map((s) => s.toString()).toList(),
      assignees: assigneesJson
          .map((a) => TaskAssigneeModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      subtasks: subtasksJson
          .map((s) => SubtaskModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      dependsOn: dependsOnJson
          .map((d) => TaskDependencyModel.fromJson(d as Map<String, dynamic>))
          .toList(),
      dependentTasks: dependentJson
          .map((d) => TaskDependencyModel.fromJson(d as Map<String, dynamic>))
          .toList(),
      extensionRequests: extJson
          .map((e) => TaskExtensionRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusHistory: historyJson
          .map((h) => TaskStatusHistoryModel.fromJson(h as Map<String, dynamic>))
          .toList(),
      commentsCount: _asInt(json['comments_count']),
    );
  }

  TaskDetailModel copyWith({
    TaskModel? task,
    String? description,
    String? instructions,
    String? completionNotes,
    bool? canManage,
    bool? canWork,
    List<String>? allowedStatuses,
    List<TaskAssigneeModel>? assignees,
    List<SubtaskModel>? subtasks,
    List<TaskDependencyModel>? dependsOn,
    List<TaskDependencyModel>? dependentTasks,
    List<TaskExtensionRequestModel>? extensionRequests,
    List<TaskStatusHistoryModel>? statusHistory,
    int? commentsCount,
  }) {
    return TaskDetailModel(
      task: task ?? this.task,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      completionNotes: completionNotes ?? this.completionNotes,
      canManage: canManage ?? this.canManage,
      canWork: canWork ?? this.canWork,
      allowedStatuses: allowedStatuses ?? this.allowedStatuses,
      assignees: assignees ?? this.assignees,
      subtasks: subtasks ?? this.subtasks,
      dependsOn: dependsOn ?? this.dependsOn,
      dependentTasks: dependentTasks ?? this.dependentTasks,
      extensionRequests: extensionRequests ?? this.extensionRequests,
      statusHistory: statusHistory ?? this.statusHistory,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}

