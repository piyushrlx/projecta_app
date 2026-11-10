import '../core/api_client.dart';
import '../models/project_model.dart';

class ProjectService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getProjects({
    String? status,
    String? priority,
    int? departmentId,
    int? managerId,
    int? userId,
    String? deadlineFrom,
    String? deadlineTo,
    bool? overdue,
    bool? archived,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty && status != 'all') {
      query['status'] = status;
    }
    if (priority != null && priority.isNotEmpty && priority != 'all') {
      query['priority'] = priority;
    }
    if (departmentId != null) {
      query['department_id'] = departmentId.toString();
    }
    if (managerId != null) {
      query['manager_id'] = managerId.toString();
    }
    if (userId != null) {
      query['user_id'] = userId.toString();
    }
    if (deadlineFrom != null && deadlineFrom.isNotEmpty) {
      query['deadline_from'] = deadlineFrom;
    }
    if (deadlineTo != null && deadlineTo.isNotEmpty) {
      query['deadline_to'] = deadlineTo;
    }
    if (overdue == true) {
      query['overdue'] = '1';
    }
    if (archived == true) {
      query['archived'] = '1';
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await _client.getWithCache(
      '/projects',
      queryParameters: query,
    );
    final isCached = ApiClient.isCachedResponse(response);
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic>) {
      final list = (data['projects'] as List<dynamic>?) ?? [];
      final projects = list
          .map((item) => ProjectModel.fromJson(item as Map<String, dynamic>))
          .toList();
      final totalRaw = data['total'];
      final pageRaw = data['page'];
      final pagesRaw = data['pages'];
      final totalInt = totalRaw is num
          ? totalRaw.toInt()
          : (int.tryParse(totalRaw?.toString() ?? '') ?? 0);
      final pageInt = pageRaw is num
          ? pageRaw.toInt()
          : (int.tryParse(pageRaw?.toString() ?? '') ?? page);
      final pagesInt = pagesRaw is num
          ? pagesRaw.toInt()
          : (int.tryParse(pagesRaw?.toString() ?? '') ?? 1);

      return {
        'projects': projects,
        'total': totalInt,
        'page': pageInt,
        'pages': pagesInt,
        'is_cached': isCached,
      };
    }

    return {'projects': <ProjectModel>[], 'total': 0, 'page': page, 'pages': 1};
  }

  Future<ProjectDetailModel> getProjectDetails(int id) async {
    final response = await _client.getWithCache('/projects/$id');
    final isCached = ApiClient.isCachedResponse(response);
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic>) {
      return ProjectDetailModel.fromJson(data, isFromCache: isCached);
    }
    throw ApiException(
      statusCode: 500,
      message: 'Invalid project details response format.',
    );
  }

  /// Toggles milestone status between completed and pending
  Future<Map<String, dynamic>> toggleMilestone(int milestoneId) async {
    final response = await _client.post('/milestones/$milestoneId/toggle');
    final dynamic data = _client.decodeJson(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'ok': true};
  }

  /// Creates or updates a milestone
  Future<Map<String, dynamic>> saveMilestone({
    int? id,
    required int projectId,
    required String title,
    String? description,
    String? deliverables,
    String? dueDate,
    int sortOrder = 0,
  }) async {
    final body = <String, dynamic>{
      'project_id': projectId,
      'title': title.trim(),
      'description': description?.trim(),
      'deliverables': deliverables?.trim(),
      'due_date': dueDate,
      'sort_order': sortOrder,
    };

    final path = id != null && id > 0
        ? '/milestones/$id'
        : '/projects/$projectId/milestones';
    final response = await _client.post(path, body: body);
    final dynamic data = _client.decodeJson(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'ok': true};
  }

  /// Deletes a milestone if not linked to any tasks
  Future<void> deleteMilestone(int milestoneId) async {
    await _client.delete('/milestones/$milestoneId');
  }

  /// Changes project status (e.g. active, on_hold, completed, cancelled)
  Future<Map<String, dynamic>> changeProjectStatus(
    int projectId,
    String status,
  ) async {
    final response = await _client.post(
      '/projects/$projectId/status',
      body: {'status': status},
    );
    final dynamic data = _client.decodeJson(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'ok': true, 'status': status};
  }

  /// Creates or updates a project
  Future<Map<String, dynamic>> saveProject(
    Map<String, dynamic> data, {
    int? id,
  }) async {
    final path = id != null && id > 0 ? '/projects/$id' : '/projects';
    final response = await _client.post(path, body: data);
    final dynamic dataRes = _client.decodeJson(response);
    if (dataRes is Map<String, dynamic>) {
      return dataRes;
    }
    return {'ok': true};
  }

  /// Adds a team member or viewer to a project
  Future<void> addProjectMember(int projectId, int userId, String role) async {
    await _client.post(
      '/projects/$projectId/members',
      body: {'user_id': userId, 'member_role': role},
    );
  }

  /// Removes a member from a project
  Future<void> removeProjectMember(int projectId, int userId) async {
    await _client.delete('/projects/$projectId/members/$userId');
  }

  /// Archives or unarchives a project
  Future<Map<String, dynamic>> archiveProject(
    int projectId, {
    required bool unarchive,
  }) async {
    final response = await _client.post(
      '/projects/$projectId/archive',
      body: {'action': unarchive ? 'unarchive' : 'archive'},
    );
    final dynamic data = _client.decodeJson(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'ok': true};
  }

  /// Fetches comments for an entity (project, task, report)
  Future<List<CommentModel>> getComments(String entityType, int entityId) async {
    final response = await _client.get(
      '/comments',
      queryParameters: {
        'entity_type': entityType,
        'entity_id': entityId.toString(),
      },
    );
    final dynamic data = _client.decodeJson(response);
    if (data is Map<String, dynamic>) {
      final list = (data['comments'] as List<dynamic>?) ?? [];
      return list
          .map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Adds a new comment to an entity
  Future<CommentModel> addComment({
    required String entityType,
    required int entityId,
    required String body,
    int? parentId,
  }) async {
    final payload = <String, dynamic>{
      'entity_type': entityType,
      'entity_id': entityId,
      'body': body.trim(),
    };
    if (parentId != null) {
      payload['parent_id'] = parentId;
    }

    final response = await _client.post('/comments', body: payload);
    final dynamic data = _client.decodeJson(response);
    if (data is Map<String, dynamic> && data['comment'] != null) {
      return CommentModel.fromJson(data['comment'] as Map<String, dynamic>);
    }
    throw ApiException(
      statusCode: 500,
      message: 'Failed to create comment.',
    );
  }

  /// Uploads a file attachment to an entity (project, task, report)
  Future<AttachmentModel> uploadAttachment({
    required String entityType,
    required int entityId,
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
  }) async {
    final response = await _client.uploadMultipartFile(
      '/attachments/upload',
      fieldName: 'file',
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
      fields: {
        'entity_type': entityType,
        'entity_id': entityId.toString(),
      },
    );

    final dynamic data = _client.decodeJson(response);
    if (data is Map<String, dynamic> && data['attachment'] != null) {
      return AttachmentModel.fromJson(
        data['attachment'] as Map<String, dynamic>,
      );
    }
    throw ApiException(
      statusCode: 500,
      message: data is Map<String, dynamic> && data['message'] != null
          ? data['message'].toString()
          : 'Failed to upload attachment.',
    );
  }
}
