class HealthDetailedStats {
  final double avgDailySleep; // hours/day
  final double avgSessionSleep; // hours/session
  final double monthlyAvgSleep; // hours/day (last 30 days)

  final double avgMealsPerDay; // Overall (of fetched)
  final double weeklyAvgMeals; // last 7 days
  final double monthlyAvgMeals; // last 30 days

  final double hygieneConsistency; // % (of fetched)
  final List<ExerciseStats> exerciseStats;

  HealthDetailedStats({
    required this.avgDailySleep,
    required this.avgSessionSleep,
    required this.monthlyAvgSleep,
    required this.avgMealsPerDay,
    required this.weeklyAvgMeals,
    required this.monthlyAvgMeals,
    required this.hygieneConsistency,
    this.exerciseStats = const [],
  });

  factory HealthDetailedStats.empty() {
    return HealthDetailedStats(
      avgDailySleep: 0,
      avgSessionSleep: 0,
      monthlyAvgSleep: 0,
      avgMealsPerDay: 0,
      weeklyAvgMeals: 0,
      monthlyAvgMeals: 0,
      hygieneConsistency: 0,
    );
  }
}

class ExerciseStats {
  final String exerciseName;
  final int count30Days;
  final List<int>
  last7DaysCounts; // Index 0 = Today, 1 = Yesterday ... or Today is last?
  // Let's decided: "Last 7 days" usually ends Today.
  // I will use: Index 0 = 6 days ago, Index 6 = Today.

  ExerciseStats({
    required this.exerciseName,
    required this.count30Days,
    required this.last7DaysCounts,
  });
}

class MindDetailedStats {
  final double avgTasksPerDay; // Last 30 days
  final int totalTasks30Days;
  final double
  completionRate; // % Completed/Active types? or Completed/Total Created?
  // User asked for "stats like exercise/health".
  // Completion rate of logs vs ...?
  // Maybe just  final double completionRate;
  final Map<String, int> typeCounts;

  MindDetailedStats({
    required this.avgTasksPerDay,
    required this.totalTasks30Days,
    required this.completionRate,
    this.typeCounts = const {},
  });
}
