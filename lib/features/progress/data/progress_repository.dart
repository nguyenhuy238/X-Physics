import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/x_models.dart';

class ProgressRepository {
  const ProgressRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<ProgressDashboard> dashboard() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      ApiEndpoints.progressDashboard,
    );
    final body = response.data;
    if (body == null || body['success'] != true) {
      throw StateError(body?['message'] as String? ?? 'API error');
    }
    return ProgressDashboard.fromJson(body['data'] as Map);
  }
}
