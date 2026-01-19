import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/api/api_client.dart';
import 'package:mobile/src/features/health/data/models/stats_models.dart';
import 'package:mobile/src/features/mind/data/mind_repository.dart';
import 'package:mobile/src/features/mind/data/models/mind_models.dart';

final mindRepositoryProvider = Provider<MindRepository>((ref) {
  return MindRepository(ApiClient());
});

final taskTypesProvider = FutureProvider<List<MindTaskType>>((ref) async {
  final repository = ref.watch(mindRepositoryProvider);
  return repository.getTaskTypes();
});

final mindLogsProvider = FutureProvider<List<MindLog>>((ref) async {
  final repository = ref.watch(mindRepositoryProvider);
  return repository.getMindLogs();
});

final detailedMindStatsProvider = FutureProvider<MindDetailedStats>((
  ref,
) async {
  final repository = ref.watch(mindRepositoryProvider);
  final logs = await repository.getMindLogs();

  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(days: 30));

  final validLogs = logs.where((l) {
    final dt = DateTime.tryParse(l.date);
    return dt != null && dt.isAfter(cutoff);
  }).toList();

  final completedLogs = validLogs.where((l) => l.isCompleted).toList();

  double avgTasksPerDay = completedLogs.length / 30.0;

  double completionRate = validLogs.isEmpty
      ? 0
      : (completedLogs.length / validLogs.length) * 100;

  final typeCounts = <String, int>{};
  for (var log in completedLogs) {
    if (log.taskType != null) {
      final name = log.taskType!.title;
      typeCounts[name] = (typeCounts[name] ?? 0) + 1;
    }
  }

  return MindDetailedStats(
    avgTasksPerDay: avgTasksPerDay,
    totalTasks30Days: completedLogs.length,
    completionRate: completionRate,
    typeCounts: typeCounts,
  );
});
