import '../core/api_client.dart';
import '../models/department_model.dart';
import '../models/employee_detail_model.dart';

class DirectoryService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getEmployees({
    String? search,
    String? status,
    int? departmentId,
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
    if (status != null && status.isNotEmpty) {
      query['status'] = status.toLowerCase();
    }
    if (departmentId != null && departmentId > 0) {
      query['department_id'] = departmentId.toString();
    }

    final response = await _client.get('/employees', queryParameters: query);
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic> && data['employees'] is List) {
      return (data['employees'] as List).cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getDepartments({
    String status = 'active',
  }) async {
    final response = await _client.get(
      '/departments',
      queryParameters: {'status': status},
    );
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic> && data['departments'] is List) {
      return (data['departments'] as List).cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<DepartmentModel>> getDepartmentModels({
    String status = 'all',
  }) async {
    final list = await getDepartments(status: status);
    return list.map((m) => DepartmentModel.fromJson(m)).toList();
  }

  Future<EmployeeDetailModel> getEmployeeDetail(int id) async {
    final response = await _client.get(
      '/employees/detail',
      queryParameters: {'id': id.toString()},
    );
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic> &&
        data['employee'] is Map<String, dynamic>) {
      return EmployeeDetailModel.fromJson(
        data['employee'] as Map<String, dynamic>,
      );
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Failed to load employee details',
    );
  }

  Future<Map<String, dynamic>> saveEmployee(Map<String, dynamic> data) async {
    final response = await _client.post('/employees/save', body: data);
    final dynamic res = _client.decodeJson(response);
    if (res is Map<String, dynamic>) {
      return res;
    }
    return <String, dynamic>{'success': true};
  }

  Future<Map<String, dynamic>> toggleEmployeeStatus(int id) async {
    final response = await _client.post(
      '/employees/toggle-status',
      body: {'id': id},
    );
    final dynamic res = _client.decodeJson(response);
    if (res is Map<String, dynamic>) {
      return res;
    }
    return <String, dynamic>{'success': true};
  }

  Future<Map<String, dynamic>> resetEmployeePassword(int id) async {
    final response = await _client.post(
      '/employees/reset-password',
      body: {'id': id},
    );
    final dynamic res = _client.decodeJson(response);
    if (res is Map<String, dynamic>) {
      return res;
    }
    return <String, dynamic>{'success': true};
  }

  Future<Map<String, dynamic>> updateEmployeeRole(
    int id,
    String role, {
    String adminScope = 'assigned',
  }) async {
    final response = await _client.post(
      '/employees/role',
      body: {'id': id, 'role': role, 'admin_scope': adminScope},
    );
    final dynamic res = _client.decodeJson(response);
    if (res is Map<String, dynamic>) {
      return res;
    }
    return <String, dynamic>{'success': true};
  }

  Future<Map<String, dynamic>> saveDepartment(Map<String, dynamic> data) async {
    final response = await _client.post('/departments/save', body: data);
    final dynamic res = _client.decodeJson(response);
    if (res is Map<String, dynamic>) {
      return res;
    }
    return <String, dynamic>{'success': true};
  }

  Future<Map<String, dynamic>> deleteDepartment(int id) async {
    final response = await _client.post(
      '/departments/delete',
      body: {'id': id},
    );
    final dynamic res = _client.decodeJson(response);
    if (res is Map<String, dynamic>) {
      return res;
    }
    return <String, dynamic>{'success': true};
  }
}
