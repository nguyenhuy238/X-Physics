import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<({
    List<NotificationModel> items,
    int total,
    int unreadCount,
  })> getNotifications({int page = 1, int limit = 20}) async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      ApiEndpoints.notifications,
      queryParameters: {'page': page, 'limit': limit},
    );

    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Invalid response format');
    }

    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return (
      items: items,
      total: data['total'] as int? ?? 0,
      unreadCount: data['unreadCount'] as int? ?? 0,
    );
  }

  Future<void> markAsRead(String id) async {
    await apiClient.dio.patch<dynamic>(ApiEndpoints.notificationRead(id));
  }

  Future<void> markAllAsRead() async {
    await apiClient.dio.patch<dynamic>(ApiEndpoints.notificationsReadAll);
  }
}
