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

    final response = await _client.get('/projects', queryParameters: query);
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
      };
    }

    return {
      'projects': <ProjectModel>[],
      'total': 0,
      'page': page,
      'pages': 1,
    };
  }

  Future<ProjectDetailModel> getProjectDetails(int id) async {
    final response = await _client.get('/projects/$id');
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic>) {
      return ProjectDetailModel.fromJson(data);
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

    final path = id != null && id > 0 ? '/milestones/$id' : '/projects/$projectId/milestones';
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
  Future<Map<String, dynamic>> changeProjectStatus(int projectId, String status) async {
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
  Future<Map<String, dynamic>> saveProject(Map<String, dynamic> data, {int? id}) async {
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
      body: {
        'user_id': userId,
        'member_role': role,
      },
    );
  }

  /// Removes a member from a project
  Future<void> removeProjectMember(int projectId, int userId) async {
    await _client.delete('/projects/$projectId/members/$userId');
  }

  /// Archives or unarchives a project
  Future<Map<String, dynamic>> archiveProject(int projectId, {required bool unarchive}) async {
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
}

