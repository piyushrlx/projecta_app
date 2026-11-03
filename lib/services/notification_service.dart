import '../core/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 30}) async {
    final response = await _client.get(
      '/notifications',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    final dynamic data = _client.decodeJson(response);

    if (data is Map<String, dynamic>) {
      final list = (data['notifications'] as List<dynamic>?) ?? [];
      final notifications = list
          .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return {
        'notifications': notifications,
        'unread_count': (data['unread_count'] as num?)?.toInt() ?? 0,
        'total': (data['total'] as num?)?.toInt() ?? 0,
      };
    }

    return {
      'notifications': <NotificationModel>[],
      'unread_count': 0,
      'total': 0,
    };
  }

  Future<void> markRead(int id) async {
    await _client.post('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _client.post('/notifications/read-all');
  }
}

