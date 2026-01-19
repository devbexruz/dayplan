import 'package:mobile/src/core/api/api_client.dart';
import 'package:mobile/src/features/dashboard/data/models/analytics_models.dart';

class AnalyticsRepository {
  final ApiClient _apiClient;

  AnalyticsRepository(this._apiClient);

  Future<WorkStats> getWorkStats() async {
    final response = await _apiClient.dio.get('/analytics/stats/work');
    return WorkStats.fromJson(response.data);
  }

  Future<HealthStats> getHealthStats() async {
    final response = await _apiClient.dio.get('/analytics/stats/health');
    return HealthStats.fromJson(response.data);
  }

  Future<MindStats> getMindStats() async {
    final response = await _apiClient.dio.get('/analytics/stats/mind');
    return MindStats.fromJson(response.data);
  }

  Future<DetailedStats> getDetailedHistory(String module) async {
    final response = await _apiClient.dio.get('/analytics/history/$module');
    return DetailedStats.fromJson(response.data);
  }
}
