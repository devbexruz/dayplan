import 'package:mobile/src/core/api/api_client.dart';
import 'package:mobile/src/features/dashboard/data/models/work_status.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<WorkStatus> getWorkStatus() async {
    try {
      final response = await _apiClient.dio.get('/work/today');
      return WorkStatus.fromJson(response.data);
    } catch (e) {
      // If 404 or error, assume empty
      return WorkStatus(active: false, passive: false, isSaved: false);
    }
  }

  Future<WorkStatus> updateWorkStatus(WorkStatus status) async {
    try {
      final response = await _apiClient.dio.put(
        '/work/today',
        data: status.toJson(),
      );
      return WorkStatus.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update work status: $e');
    }
  }
}
