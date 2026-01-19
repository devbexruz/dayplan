import 'package:mobile/src/core/api/api_client.dart';
import 'package:mobile/src/features/health/data/models/health_models.dart';

class HealthRepository {
  final ApiClient _apiClient;

  HealthRepository(this._apiClient);

  Future<List<ExerciseType>> getExerciseTypes() async {
    try {
      final response = await _apiClient.dio.get('/health/exercise-types/');
      return (response.data as List)
          .map((e) => ExerciseType.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load exercise types: $e');
    }
  }

  Future<ExerciseType> createExerciseType({
    required String name,
    int sets = 0,
    int reps = 0,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/health/exercise-types/',
        data: {'name': name, 'sets': sets, 'reps': reps},
      );
      return ExerciseType.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create exercise type: $e');
    }
  }

  Future<ExerciseType> updateExerciseType({
    required int id,
    required String name,
    required int sets,
    required int reps,
    bool isActive = true,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/health/exercise-types/$id',
        data: {'name': name, 'sets': sets, 'reps': reps, 'is_active': isActive},
      );
      return ExerciseType.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update exercise type: $e');
    }
  }

  Future<List<SportLog>> getSportLogs() async {
    try {
      final response = await _apiClient.dio.get('/health/sport-logs/');
      return (response.data as List).map((e) => SportLog.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load sport logs: $e');
    }
  }

  Future<SportLog> createSportLog({required int exerciseTypeId}) async {
    try {
      final response = await _apiClient.dio.post(
        '/health/sport-logs/',
        data: {'exercise_type_id': exerciseTypeId},
      );
      return SportLog.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create sport log: $e');
    }
  }

  // No longer needed to update sets/reps on log, but might need to update type association
  // For now removing updateSportLog as edits go to ExerciseType

  Future<void> updateSportLogStatus(int id, bool isCompleted) async {
    try {
      await _apiClient.dio.put(
        '/health/sport-logs/$id/status',
        queryParameters: {'is_completed': isCompleted},
      );
    } catch (e) {
      throw Exception('Failed to update sport log status: $e');
    }
  }

  Future<SleepLog?> getSleepLog() async {
    try {
      final response = await _apiClient.dio.get('/health/sleep/today');
      if (response.data == null) return null;
      return SleepLog.fromJson(response.data);
    } catch (e) {
      if (e.toString().contains('404')) return null;
      return null;
    }
  }

  Future<DailyHabit?> getDailyHabit() async {
    try {
      final response = await _apiClient.dio.get('/health/habits/today');
      return DailyHabit.fromJson(response.data);
    } catch (e) {
      if (e.toString().contains('404')) return null;
      return null;
    }
  }

  Future<SleepLog?> wakeUp() async {
    try {
      final response = await _apiClient.dio.post('/health/sleep/wake-up');
      if (response.data == null) return null;
      return SleepLog.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to wake up: $e');
    }
  }

  Future<SleepLog> sleep() async {
    try {
      final response = await _apiClient.dio.post('/health/sleep/sleep');
      return SleepLog.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to sleep: $e');
    }
  }

  Future<DailyHabit> updateDailyHabit({
    int mealCount = 0,
    bool morningHygieneDone = false,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/health/habits/',
        data: {
          'meal_count': mealCount,
          'morning_hygiene_done': morningHygieneDone,
        },
      );
      return DailyHabit.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update habits: $e');
    }
  }

  Future<List<DailyHabit>> getDailyHabitHistory({int limit = 30}) async {
    try {
      final response = await _apiClient.dio.get(
        '/health/daily-habits-history',
        queryParameters: {'limit': limit},
      );
      return (response.data as List)
          .map((e) => DailyHabit.fromJson(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<SleepLog>> getSleepLogHistory({int limit = 30}) async {
    try {
      final response = await _apiClient.dio.get(
        '/health/sleep-logs-history',
        queryParameters: {'limit': limit},
      );
      return (response.data as List).map((e) => SleepLog.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<SportLog>> getSportLogHistory({int limit = 100}) async {
    try {
      final response = await _apiClient.dio.get(
        '/health/sport-logs-history',
        queryParameters: {'limit': limit},
      );
      return (response.data as List).map((e) => SportLog.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
