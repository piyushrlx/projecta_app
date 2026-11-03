import '../core/api_client.dart';
import '../models/project_model.dart';

class ProjectService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getProjects({
    String? status,
    String? priority,
    int? departmentId,
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
      return {
        'projects': projects,
        'total': (data['total'] as num?)?.toInt() ?? 0,
        'page': (data['page'] as num?)?.toInt() ?? page,
        'pages': (data['pages'] as num?)?.toInt() ?? 1,
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
}

