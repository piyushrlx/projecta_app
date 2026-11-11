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

    final response = await _client.getWithCache(path);
    final dynamic decoded = _client.decodeJson(response);
    if (decoded is Map<String, dynamic>) {
      decoded['is_cached'] = ApiClient.isCachedResponse(response);
      return decoded;
    }
    return <String, dynamic>{};
  }

  /// Global Omnibar search across projects, tasks, and employees
  Future<Map<String, dynamic>> searchGlobal(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) {
      return {'projects': [], 'tasks': [], 'employees': []};
    }

    final encoded = Uri.encodeComponent(cleanQuery);
    final response = await _client.get('/search?q=$encoded');
    final dynamic decoded = _client.decodeJson(response);

    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map<String, dynamic>) {
        return decoded['data'] as Map<String, dynamic>;
      }
      return decoded;
    }
    return {'projects': [], 'tasks': [], 'employees': []};
  }

  /// Fetches calendar tasks, milestones, holidays, and upcoming deadlines
  Future<Map<String, dynamic>> getCalendarData({
    DateTime? date,
    String view = 'month',
    int? projectId,
    int? userId,
  }) async {
    final queryParams = <String, String>{
      'view': view,
    };
    if (date != null) {
      queryParams['date'] =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    if (projectId != null) {
      queryParams['project_id'] = projectId.toString();
    }
    if (userId != null) {
      queryParams['user_id'] = userId.toString();
    }

    final uri = Uri(path: '/calendar', queryParameters: queryParams);
    final response = await _client.get('${uri.path}?${uri.query}');
    final dynamic decoded = _client.decodeJson(response);

    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map<String, dynamic>) {
        return decoded['data'] as Map<String, dynamic>;
      }
      return decoded;
    }
    return <String, dynamic>{
      'tasks': [],
      'milestones': [],
      'holidays': [],
      'upcoming': [],
    };
  }

  /// System Settings & Holidays (Super Admin)
  Future<Map<String, dynamic>> getFullSettings() async {
    final response = await _client.get('/settings/full');
    final dynamic decoded = _client.decodeJson(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {'settings': {}, 'holidays': []};
  }

  Future<void> saveSettings(Map<String, dynamic> data) async {
    await _client.post('/settings/save', body: data);
  }

  Future<int> addHoliday(String date, String name) async {
    final response = await _client.post('/settings/holidays', body: {
      'holiday_date': date,
      'name': name,
    });
    final dynamic decoded = _client.decodeJson(response);
    if (decoded is Map<String, dynamic> && decoded['id'] != null) {
      return (decoded['id'] as num).toInt();
    }
    return 0;
  }

  Future<void> deleteHoliday(int id) async {
    await _client.delete('/settings/holidays/$id');
  }

  /// Audit Log Viewer (Super Admin)
  Future<List<dynamic>> getAuditLogs({
    int? userId,
    String? action,
    String? entityType,
    String? from,
    String? to,
  }) async {
    final queryParams = <String, String>{};
    if (userId != null) queryParams['user_id'] = userId.toString();
    if (action != null && action.isNotEmpty) queryParams['action'] = action;
    if (entityType != null && entityType.isNotEmpty) queryParams['entity_type'] = entityType;
    if (from != null && from.isNotEmpty) queryParams['from'] = from;
    if (to != null && to.isNotEmpty) queryParams['to'] = to;

    final uri = Uri(path: '/audit-logs', queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await _client.get(uri.query.isNotEmpty ? '${uri.path}?${uri.query}' : uri.path);
    final dynamic decoded = _client.decodeJson(response);
    if (decoded is Map<String, dynamic> && decoded['logs'] is List) {
      return decoded['logs'] as List<dynamic>;
    }
    return [];
  }

  /// Contact Messages Inquiry Inbox (Super Admin)
  Future<Map<String, dynamic>> getContactMessages({bool unreadOnly = false}) async {
    final path = unreadOnly ? '/contact-messages?unread=1' : '/contact-messages';
    final response = await _client.get(path);
    final dynamic decoded = _client.decodeJson(response);
    if (decoded is Map<String, dynamic>) {
      return {
        'messages': decoded['messages'] ?? [],
        'unread_count': decoded['unread_count'] ?? 0,
      };
    }
    return {'messages': [], 'unread_count': 0};
  }

  Future<void> markContactMessageRead(int id) async {
    await _client.post('/contact-messages/$id/read');
  }

  Future<void> deleteContactMessage(int id) async {
    await _client.delete('/contact-messages/$id');
  }
}
