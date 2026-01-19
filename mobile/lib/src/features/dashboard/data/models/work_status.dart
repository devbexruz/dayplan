class WorkStatus {
  final bool active;
  final bool passive;
  final bool isSaved;

  WorkStatus({
    required this.active,
    required this.passive,
    required this.isSaved,
  });

  factory WorkStatus.fromJson(Map<String, dynamic> json) {
    return WorkStatus(
      active: json['active'] ?? false,
      passive: json['passive'] ?? false,
      isSaved: json['is_saved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'active': active, 'passive': passive, 'is_saved': isSaved};
  }
}
