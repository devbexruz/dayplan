class WorkStats {
  final int streakDays;
  final double completionRateWeekly;
  final int totalCompleted;
  final String motivationMessage;

  WorkStats({
    required this.streakDays,
    required this.completionRateWeekly,
    required this.totalCompleted,
    required this.motivationMessage,
  });

  factory WorkStats.fromJson(Map<String, dynamic> json) {
    return WorkStats(
      streakDays: json['streak_days'],
      completionRateWeekly: json['completion_rate_weekly'],
      totalCompleted: json['total_completed'],
      motivationMessage: json['motivation_message'],
    );
  }
}

class HealthStats {
  final double avgSleepHours;
  final int sportDaysWeekly;
  final double habitConsistency;
  final String motivationMessage;

  HealthStats({
    required this.avgSleepHours,
    required this.sportDaysWeekly,
    required this.habitConsistency,
    required this.motivationMessage,
  });

  factory HealthStats.fromJson(Map<String, dynamic> json) {
    return HealthStats(
      avgSleepHours: json['avg_sleep_hours'],
      sportDaysWeekly: json['sport_days_weekly'],
      habitConsistency: json['habit_consistency'],
      motivationMessage: json['motivation_message'],
    );
  }
}

class MindStats {
  final int tasksWeekly;
  final String? topFocusArea;
  final String motivationMessage;

  MindStats({
    required this.tasksWeekly,
    this.topFocusArea,
    required this.motivationMessage,
  });

  factory MindStats.fromJson(Map<String, dynamic> json) {
    return MindStats(
      tasksWeekly: json['tasks_weekly'],
      topFocusArea: json['top_focus_area'],
      motivationMessage: json['motivation_message'],
    );
  }
}

class HistoryPoint {
  final DateTime date;
  final double value;

  HistoryPoint({required this.date, required this.value});

  factory HistoryPoint.fromJson(Map<String, dynamic> json) {
    return HistoryPoint(
      date: DateTime.parse(json['date']),
      value: (json['value'] as num).toDouble(),
    );
  }
}

class DetailedStats {
  final List<HistoryPoint> history;
  final double growthPct;
  final double averageValue;
  final double totalValue;
  final String comparisonText;

  DetailedStats({
    required this.history,
    required this.growthPct,
    required this.averageValue,
    required this.totalValue,
    required this.comparisonText,
  });

  factory DetailedStats.fromJson(Map<String, dynamic> json) {
    return DetailedStats(
      history: (json['history'] as List)
          .map((e) => HistoryPoint.fromJson(e))
          .toList(),
      growthPct: (json['growth_pct'] as num).toDouble(),
      averageValue: (json['average_value'] as num).toDouble(),
      totalValue: (json['total_value'] as num).toDouble(),
      comparisonText: json['comparison_text'],
    );
  }
}
