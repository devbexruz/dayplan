class ExerciseType {
  final int id;
  final String name;
  final String? description;
  final int sets;
  final int reps;
  final bool isActive;

  ExerciseType({
    required this.id,
    required this.name,
    this.description,
    this.sets = 0,
    this.reps = 0,
    this.isActive = true,
  });

  factory ExerciseType.fromJson(Map<String, dynamic> json) {
    return ExerciseType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

class SportLog {
  final int id;
  final int exerciseTypeId;
  final ExerciseType? exerciseType;
  final bool isCompleted;
  final String date;

  SportLog({
    required this.id,
    required this.exerciseTypeId,
    this.exerciseType,
    required this.isCompleted,
    required this.date,
  });

  factory SportLog.fromJson(Map<String, dynamic> json) {
    return SportLog(
      id: json['id'],
      exerciseTypeId: json['exercise_type_id'],
      exerciseType: json['exercise_type'] != null
          ? ExerciseType.fromJson(json['exercise_type'])
          : null,
      isCompleted: json['is_completed'],
      date: json['date'],
    );
  }
}

class SleepLog {
  final int id;
  final String startTime;
  final String? endTime;

  SleepLog({required this.id, required this.startTime, this.endTime});

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    return SleepLog(
      id: json['id'],
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }
}

class DailyHabit {
  final int id;
  final int mealCount;
  final bool morningHygieneDone;

  DailyHabit({
    required this.id,
    required this.mealCount,
    required this.morningHygieneDone,
  });

  factory DailyHabit.fromJson(Map<String, dynamic> json) {
    return DailyHabit(
      id: json['id'],
      mealCount: json['meal_count'],
      morningHygieneDone: json['morning_hygiene_done'],
    );
  }
}
