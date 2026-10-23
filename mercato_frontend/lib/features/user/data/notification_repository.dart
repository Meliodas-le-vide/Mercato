import 'package:mercato_frontend/core/constants/api_endpoints.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/network/paginated_result.dart';
import 'package:mercato_frontend/features/user/domain/notification_model.dart';

class NotificationRepository {
  final DioClient _dioClient;

  NotificationRepository(this._dioClient);

  Future<PaginatedResult<NotificationModel>> getMyNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': page, 'limit': limit},
    );
    return PaginatedResult.fromJson(response.data, NotificationModel.fromJson);
  }

  Future<int> getUnreadCount() async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.notificationsUnreadCount,
    );
    return response.data['count'] as int;
  }

  Future<void> markAsRead(int id) async {
    await _dioClient.dio.patch(ApiEndpoints.notificationRead(id));
  }

  Future<void> markAllAsRead() async {
    await _dioClient.dio.patch(ApiEndpoints.notificationsReadAll);
  }
}
