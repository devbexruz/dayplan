import 'package:mobile/src/core/api/api_client.dart';
import 'package:mobile/src/features/mind/data/models/mind_models.dart';

class MindRepository {
  final ApiClient _apiClient;

  MindRepository(this._apiClient);

  Future<List<MindTaskType>> getTaskTypes() async {
    try {
      final response = await _apiClient.dio.get('/mind/task-types/');
      return (response.data as List)
          .map((e) => MindTaskType.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load task types: $e');
    }
  }

  Future<MindTaskType> createTaskType(String title) async {
    try {
      final response = await _apiClient.dio.post(
        '/mind/task-types/',
        data: {'title': title},
      );
      return MindTaskType.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create task type: $e');
    }
  }

  Future<MindTaskType> updateTaskType(
    int id, {
    required String title,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/mind/task-types/$id',
        data: {
          'title': title,
          'description': description,
          'is_active': isActive,
        },
      );
      return MindTaskType.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update task type: $e');
    }
  }

  Future<List<MindLog>> getMindLogs() async {
    try {
      final response = await _apiClient.dio.get('/mind/logs/');
      return (response.data as List).map((e) => MindLog.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load mind logs: $e');
    }
  }

  Future<MindLog> createMindLog(int taskTypeId) async {
    try {
      final response = await _apiClient.dio.post(
        '/mind/logs/',
        data: {'task_type_id': taskTypeId},
      );
      return MindLog.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create mind log: $e');
    }
  }

  Future<MindLog> updateMindLog(int id, int taskTypeId) async {
    try {
      final response = await _apiClient.dio.put(
        '/mind/logs/$id',
        data: {'task_type_id': taskTypeId},
      );
      return MindLog.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update mind log: $e');
    }
  }

  Future<void> updateMindLogStatus(int id, bool isCompleted) async {
    try {
      await _apiClient.dio.put(
        '/mind/logs/$id/status',
        queryParameters: {'is_completed': isCompleted},
      );
    } catch (e) {
      throw Exception('Failed to update mind log status: $e');
    }
  }
}
