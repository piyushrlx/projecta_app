import '../core/api_client.dart';
import '../models/task_model.dart';

class TaskService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getTasks({
    int? projectId,
    String? status,
    String? priority,
    bool? overdue,
    bool? assignedToMe,
    String? search,
    int page = 1,
    int limit = 30,
  }) async {
    final query = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (projectId != null) {
      query['project_id'] = projectId.toString();
    }
    if (status != null && status.isNotEmpty && status != 'ALL') {
      query['status'] = status.toLowerCase();
    }
    if (priority != null && priority.isNotEmpty && priority != 'ALL') {
      query['priority'] = priority.toLowerCase();
    }
    if (overdue == true) {
      query['overdue'] = '1';
    }
    if (assignedToMe == true) {
      query['assigned_to_me'] = '1';
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await _client.get('/tasks', queryParameters: query);
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic>) {
      final list = (data['tasks'] as List<dynamic>?) ?? [];
      final tasks = list
          .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return {
        'tasks': tasks,
        'total': (data['total'] as num?)?.toInt() ?? 0,
        'page': (data['page'] as num?)?.toInt() ?? page,
        'pages': (data['pages'] as num?)?.toInt() ?? 1,
      };
    }

    return {
      'tasks': <TaskModel>[],
      'total': 0,
      'page': page,
      'pages': 1,
    };
  }

  Future<Map<String, List<TaskModel>>> getKanban({int? projectId}) async {
    final query = <String, dynamic>{};
    if (projectId != null) {
      query['project_id'] = projectId.toString();
    }

    final response = await _client.get('/kanban', queryParameters: query);
    final dynamic data = _client.decodeJson(response);

    final result = <String, List<TaskModel>>{
      'not_started': [],
      'in_progress': [],
      'blocked': [],
      'pending_review': [],
      'completed': [],
    };

    if (data is Map<String, dynamic> && data['columns'] is Map<String, dynamic>) {
      final cols = data['columns'] as Map<String, dynamic>;
      for (final key in result.keys) {
        if (cols[key] is List) {
          result[key] = (cols[key] as List)
              .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    }

    return result;
  }

  Future<TaskDetailModel> getTaskDetails(int id) async {
    final response = await _client.get('/tasks/$id');
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic>) {
      return TaskDetailModel.fromJson(data);
    }
    throw ApiException(
      statusCode: 500,
      message: 'Invalid task details response format.',
    );
  }

  Future<void> updateStatus(
    int id, {
    required String status,
    int? progress,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'status': status,
    };
    if (progress != null) {
      body['progress'] = progress;
    }
    if (note != null && note.trim().isNotEmpty) {
      body['note'] = note.trim();
      body['completion_notes'] = note.trim();
    }

    await _client.post('/tasks/$id/status', body: body);
  }

  Future<void> updateProgress(int id, int progress) async {
    await _client.post(
      '/tasks/$id/progress',
      body: {'progress': progress},
    );
  }

  Future<void> requestExtension(
    int id, {
    required String requestedDeadline,
    required String reason,
  }) async {
    await _client.post(
      '/tasks/$id/extension-request',
      body: {
        'requested_deadline': requestedDeadline,
        'reason': reason,
      },
    );
  }

  Future<void> decideExtension(
    int taskId, {
    int? requestId,
    required String decision, // 'approve' or 'reject'
    String? note,
  }) async {
    final body = <String, dynamic>{
      'decision': decision,
    };
    if (requestId != null) {
      body['request_id'] = requestId;
    }
    if (note != null && note.trim().isNotEmpty) {
      body['decision_note'] = note.trim();
      body['note'] = note.trim();
    }

    await _client.post('/tasks/$taskId/extension-decide', body: body);
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> payload) async {
    final response = await _client.post('/tasks', body: payload);
    final dynamic data = _client.decodeJson(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getActiveEmployees() async {
    final response = await _client.get('/employees');
    final dynamic data = _client.decodeJson(response);
    if (data is Map<String, dynamic> && data['employees'] is List) {
      return (data['employees'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getActiveProjects() async {
    final response = await _client.get('/projects', queryParameters: {'limit': '100', 'status': 'active'});
    final dynamic data = _client.decodeJson(response);
    if (data is Map<String, dynamic> && data['projects'] is List) {
      return (data['projects'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}

