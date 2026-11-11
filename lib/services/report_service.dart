import '../core/api_client.dart';
import '../models/report_model.dart';

class ReportService {
  final ApiClient _client = ApiClient();

  Future<TodayReportContextModel> getTodayContext() async {
    final response = await _client.get('/reports/today-context');
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic>) {
      return TodayReportContextModel.fromJson(data);
    }
    throw ApiException(
      statusCode: 500,
      message: 'Invalid today context response format.',
    );
  }

  Future<Map<String, dynamic>> submitReport(Map<String, dynamic> payload) async {
    final response = await _client.post('/reports', body: payload);
    final dynamic data = _client.decodeJson(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getReports({
    String? status,
    String? date,
    int? projectId,
    int? userId,
    int page = 1,
    int limit = 30,
  }) async {
    final query = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty && status != 'ALL') {
      query['status'] = status.toLowerCase();
    }
    if (date != null && date.isNotEmpty) {
      query['date'] = date;
    }
    if (projectId != null) {
      query['project_id'] = projectId.toString();
    }
    if (userId != null) {
      query['user_id'] = userId.toString();
    }

    final response = await _client.get('/reports', queryParameters: query);
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic>) {
      final list = (data['reports'] as List<dynamic>?) ?? [];
      final reports = list
          .map((item) => ReportModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return {
        'reports': reports,
        'total': (data['total'] as num?)?.toInt() ?? 0,
        'page': (data['page'] as num?)?.toInt() ?? page,
      };
    }

    return {
      'reports': <ReportModel>[],
      'total': 0,
      'page': page,
    };
  }

  Future<ReportModel> getReportDetails(int id) async {
    final response = await _client.get('/reports/$id');
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic> && data['report'] is Map<String, dynamic>) {
      return ReportModel.fromJson(data['report'] as Map<String, dynamic>);
    }
    throw ApiException(
      statusCode: 500,
      message: 'Invalid report details response format.',
    );
  }

  Future<void> reviewReport(
    int id, {
    required String decision, // 'approve', 'reject', 'clarify'
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'decision': decision,
    };
    if (comment != null && comment.trim().isNotEmpty) {
      body['review_comment'] = comment.trim();
      body['comment'] = comment.trim();
    }

    await _client.post('/reports/$id/review', body: body);
  }

  Future<ComplianceSummaryModel> getComplianceSummary(String date) async {
    final response = await _client.get(
      '/compliance/summary',
      queryParameters: {'date': date},
    );
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic>) {
      return ComplianceSummaryModel.fromJson(data);
    }
    throw ApiException(
      statusCode: 500,
      message: 'Invalid compliance summary response format.',
    );
  }

  Future<Map<String, dynamic>> remindDefaulter({
    required int userId,
    required String date,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'date': date,
    };
    final response = await _client.post('/reports/remind', body: body);
    final dynamic data = _client.decodeJson(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'sent': true, 'message': 'Reminder sent.'};
  }

  Future<Map<String, dynamic>> createExemption({
    required int userId,
    required String startDate,
    required String endDate,
    required String type, // 'leave' or 'exemption'
    String? reason,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'start_date': startDate,
      'end_date': endDate,
      'type': type,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    };
    final response = await _client.post('/reports/exemption', body: body);
    final dynamic data = _client.decodeJson(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'success': true, 'message': 'Exemption granted.'};
  }

  /// Fetches Reports & Analytics Hub dimensional data
  Future<Map<String, dynamic>> getAnalyticsData({
    required String type,
    String? from,
    String? to,
    int? departmentId,
    int? userId,
    int? projectId,
  }) async {
    final queryParams = <String, String>{
      'type': type,
    };
    if (from != null && from.isNotEmpty) {
      queryParams['from'] = from;
    }
    if (to != null && to.isNotEmpty) {
      queryParams['to'] = to;
    }
    if (departmentId != null) {
      queryParams['department_id'] = departmentId.toString();
    }
    if (userId != null) {
      queryParams['user_id'] = userId.toString();
    }
    if (projectId != null) {
      queryParams['project_id'] = projectId.toString();
    }

    final uri = Uri(path: '/analytics', queryParameters: queryParams);
    final response = await _client.get('${uri.path}?${uri.query}');
    final dynamic decoded = _client.decodeJson(response);

    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map<String, dynamic>) {
        return decoded['data'] as Map<String, dynamic>;
      }
      return decoded;
    }
    return <String, dynamic>{
      'summary': <String, dynamic>{},
      'rows': <dynamic>[],
    };
  }
}

