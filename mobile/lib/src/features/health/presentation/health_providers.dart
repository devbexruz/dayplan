import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/api/api_client.dart';
import 'package:mobile/src/features/health/data/health_repository.dart';
import 'package:mobile/src/features/health/data/models/health_models.dart';
import 'package:mobile/src/features/health/data/models/stats_models.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(ApiClient());
});

final exerciseTypesProvider = FutureProvider<List<ExerciseType>>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  return repository.getExerciseTypes();
});

final sportLogsProvider = FutureProvider<List<SportLog>>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  return repository.getSportLogs();
});

final sleepLogProvider = FutureProvider<SleepLog?>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  return repository.getSleepLog();
});

final dailyHabitProvider = FutureProvider<DailyHabit?>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  return repository.getDailyHabit();
});

final detailedHealthStatsProvider = FutureProvider<HealthDetailedStats>((
  ref,
) async {
  final repository = ref.watch(healthRepositoryProvider);
  final habits = await repository.getDailyHabitHistory(limit: 30);
  final sleeps = await repository.getSleepLogHistory(limit: 30);
  final sportLogs = await repository.getSportLogHistory(limit: 300);

  // --- SLEEP ---
  final validSleeps = sleeps.where((s) => s.endTime != null).toList();
  double totalSleepHours = 0;
  final uniqueSleepDays = <String>{};

  for (var s in validSleeps) {
    if (s.endTime != null) {
      final start = DateTime.tryParse(s.startTime);
      final end = DateTime.tryParse(s.endTime!);
      if (start != null && end != null) {
        final duration = end.difference(start).inMinutes / 60.0;
        totalSleepHours += duration;
        uniqueSleepDays.add(start.toIso8601String().substring(0, 10));
      }
    }
  }

  double avgSessionSleep = validSleeps.isEmpty
      ? 0
      : totalSleepHours / validSleeps.length;
  double avgDailySleep = uniqueSleepDays.isEmpty
      ? 0
      : totalSleepHours / uniqueSleepDays.length;
  double monthlyAvgSleep = avgDailySleep;

  // --- FOOD ---
  double totalMeals = 0;
  for (var h in habits) totalMeals += h.mealCount;
  double monthlyAvgMeals = habits.isEmpty ? 0 : totalMeals / habits.length;

  final weeklyHabits = habits.take(7).toList();
  double weeklyTotalMeals = 0;
  for (var h in weeklyHabits) weeklyTotalMeals += h.mealCount;
  double weeklyAvgMeals = weeklyHabits.isEmpty
      ? 0
      : weeklyTotalMeals / weeklyHabits.length;

  // --- HYGIENE ---
  int hygieneCount = habits.where((h) => h.morningHygieneDone).length;
  double hygieneConsistency = habits.isEmpty
      ? 0
      : (hygieneCount / habits.length) * 100;

  // --- EXERCISE ---
  final exerciseStats = <ExerciseStats>[];
  final now = DateTime.now();
  final cutoff30 = now.subtract(const Duration(days: 30));

  final logsByName = <String, List<SportLog>>{};
  for (var log in sportLogs) {
    if (log.exerciseType != null) {
      logsByName.putIfAbsent(log.exerciseType!.name, () => []).add(log);
    }
  }

  logsByName.forEach((name, logs) {
    final logs30 = logs.where((l) {
      final dt = DateTime.tryParse(l.date);
      return dt != null && dt.isAfter(cutoff30);
    }).toList();

    final counts7 = List.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayStr = day.toIso8601String().substring(0, 10);
      counts7[i] = logs30
          .where((l) => l.date.substring(0, 10) == dayStr)
          .length;
    }

    if (logs30.isNotEmpty) {
      exerciseStats.add(
        ExerciseStats(
          exerciseName: name,
          count30Days: logs30.length,
          last7DaysCounts: counts7,
        ),
      );
    }
  });

  return HealthDetailedStats(
    avgDailySleep: avgDailySleep,
    avgSessionSleep: avgSessionSleep,
    monthlyAvgSleep: monthlyAvgSleep,
    avgMealsPerDay: monthlyAvgMeals,
    weeklyAvgMeals: weeklyAvgMeals,
    monthlyAvgMeals: monthlyAvgMeals,
    hygieneConsistency: hygieneConsistency,
    exerciseStats: exerciseStats,
  );
});
