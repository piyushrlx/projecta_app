import '../core/api_client.dart';

class DashboardService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _client.get('/dashboard.php');
    final dynamic decoded = _client.decodeJson(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }
}

