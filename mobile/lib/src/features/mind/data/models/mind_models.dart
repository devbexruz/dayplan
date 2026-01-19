class MindTaskType {
  final int id;
  final String title;
  final String? description;
  final bool isActive;

  MindTaskType({
    required this.id,
    required this.title,
    this.description,
    this.isActive = true,
  });

  factory MindTaskType.fromJson(Map<String, dynamic> json) {
    return MindTaskType(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class MindLog {
  final int id;
  final int taskTypeId;
  final MindTaskType? taskType;
  final bool isCompleted;
  final String date;

  MindLog({
    required this.id,
    required this.taskTypeId,
    this.taskType,
    required this.isCompleted,
    required this.date,
  });

  factory MindLog.fromJson(Map<String, dynamic> json) {
    return MindLog(
      id: json['id'],
      taskTypeId: json['task_type_id'],
      taskType: json['task_type'] != null
          ? MindTaskType.fromJson(json['task_type'])
          : null,
      isCompleted: json['is_completed'],
      date: json['date'],
    );
  }
}
