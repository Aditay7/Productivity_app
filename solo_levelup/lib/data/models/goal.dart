class Goal {
  final String? id;
  final String title;
  final String description;
  final GoalType type;
  final String statType;
  final int targetValue;
  final int currentValue;
  final GoalUnit unit;
  final DateTime startDate;
  final DateTime endDate;
  final List<Milestone> milestones;
  final List<GoalAchievement> achievements;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  const Goal({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.statType,
    required this.targetValue,
    this.currentValue = 0,
    required this.unit,
    required this.startDate,
    required this.endDate,
    this.milestones = const [],
    this.achievements = const [],
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });

  int get progressPercentage {
    if (targetValue == 0) return 0;
    return ((currentValue / targetValue) * 100).clamp(0, 100).toInt();
  }

  bool get isActive {
    final now = DateTime.now();
    return !isCompleted && now.isAfter(startDate) && now.isBefore(endDate);
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      type: GoalType.fromString(map['type'] as String),
      statType: map['statType'] as String,
      targetValue: map['targetValue'] as int,
      currentValue: map['currentValue'] as int? ?? 0,
      unit: GoalUnit.fromString(map['unit'] as String),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      milestones: map['milestones'] != null
          ? (map['milestones'] as List)
              .map((m) => Milestone.fromMap(m as Map<String, dynamic>))
              .toList()
          : [],
      achievements: map['achievements'] != null
          ? (map['achievements'] as List)
              .map((a) => GoalAchievement.fromMap(a as Map<String, dynamic>))
              .toList()
          : [],
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'type': type.value,
      'statType': statType,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unit': unit.value,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    GoalType? type,
    String? statType,
    int? targetValue,
    int? currentValue,
    GoalUnit? unit,
    DateTime? startDate,
    DateTime? endDate,
    List<Milestone>? milestones,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      statType: statType ?? this.statType,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      milestones: milestones ?? this.milestones,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Milestone {
  final int value;
  final String label;
  final bool reached;
  final DateTime? reachedAt;

  const Milestone({
    required this.value,
    required this.label,
    this.reached = false,
    this.reachedAt,
  });

  factory Milestone.fromMap(Map<String, dynamic> map) {
    return Milestone(
      value: map['value'] as int,
      label: map['label'] as String,
      reached: map['reached'] as bool? ?? false,
      reachedAt: map['reachedAt'] != null
          ? DateTime.parse(map['reachedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'label': label,
      'reached': reached,
      'reachedAt': reachedAt?.toIso8601String(),
    };
  }
}

class GoalAchievement {
  final String title;
  final String description;
  final DateTime unlockedAt;
  final int? milestoneValue;

  const GoalAchievement({
    required this.title,
    required this.description,
    required this.unlockedAt,
    this.milestoneValue,
  });

  factory GoalAchievement.fromMap(Map<String, dynamic> map) {
    return GoalAchievement(
      title: map['title'] as String,
      description: map['description'] as String,
      unlockedAt: DateTime.parse(map['unlockedAt'] as String),
      milestoneValue: map['milestoneValue'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'unlockedAt': unlockedAt.toIso8601String(),
      if (milestoneValue != null) 'milestoneValue': milestoneValue,
    };
  }
}

enum GoalType {
  monthly,
  yearly,
  custom;

  String get value => toString().split('.').last;

  static GoalType fromString(String value) {
    return GoalType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GoalType.custom,
    );
  }

  String get displayName {
    switch (this) {
      case GoalType.monthly:
        return 'Monthly';
      case GoalType.yearly:
        return 'Yearly';
      case GoalType.custom:
        return 'Custom';
    }
  }
}

enum GoalUnit {
  xp,
  quests,
  streak;

  String get value => toString().split('.').last;

  static GoalUnit fromString(String value) {
    return GoalUnit.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GoalUnit.quests,
    );
  }

  String get displayName {
    switch (this) {
      case GoalUnit.xp:
        return 'XP';
      case GoalUnit.quests:
        return 'Quests';
      case GoalUnit.streak:
        return 'Day Streak';
    }
  }
}
