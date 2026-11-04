import '../core/api_client.dart';

class DashboardService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getDashboard({
    int? projectId,
    int? departmentId,
    int? userId,
  }) async {
    final queryParams = <String, String>{};
    if (projectId != null && projectId > 0) {
      queryParams['project_id'] = projectId.toString();
    }
    if (departmentId != null && departmentId > 0) {
      queryParams['department_id'] = departmentId.toString();
    }
    if (userId != null && userId > 0) {
      queryParams['user_id'] = userId.toString();
    }

    String path = '/dashboard.php';
    if (queryParams.isNotEmpty) {
      final uri = Uri(queryParameters: queryParams);
      path += '?${uri.query}';
    }

    final response = await _client.get(path);
    final dynamic decoded = _client.decodeJson(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }
}
