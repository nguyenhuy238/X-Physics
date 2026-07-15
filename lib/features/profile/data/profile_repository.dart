import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/x_models.dart';

class ProfileRepository {
  const ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<ProfileSummary> me() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      ApiEndpoints.profileMe,
    );
    final body = response.data;
    if (body == null || body['success'] != true) {
      throw StateError(body?['message'] as String? ?? 'API error');
    }
    return ProfileSummary.fromJson(body['data'] as Map);
  }

  Future<XUser> updateName(String name) async {
    final response = await _apiClient.dio.put<Map<String, dynamic>>(
      ApiEndpoints.me,
      data: {'name': name},
    );
    final body = response.data;
    if (body == null || body['success'] != true) {
      throw StateError(body?['message'] as String? ?? 'API error');
    }
    return XUser.fromJson(body['data'] as Map);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final response = await _apiClient.dio.put<Map<String, dynamic>>(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
    final body = response.data;
    if (body == null || body['success'] != true) {
      throw StateError(body?['message'] as String? ?? 'API error');
    }
  }
}
