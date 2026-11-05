import '../core/api_client.dart';

class DirectoryService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getEmployees({
    String? search,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (status != null && status != 'ALL' && status.isNotEmpty) {
      query['status'] = status.toLowerCase();
    }

    final response = await _client.get('/employees', queryParameters: query);
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic> && data['employees'] is List) {
      return (data['employees'] as List).cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getDepartments() async {
    final response = await _client.get('/departments');
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic> && data['departments'] is List) {
      return (data['departments'] as List).cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }
}

