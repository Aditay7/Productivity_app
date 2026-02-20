import '../../core/constants/stat_types.dart';
import '../../core/constants/difficulty.dart';

enum TimerState {
  notStarted,
  running,
  paused,
  completed;

  String toJson() {
    switch (this) {
      case TimerState.notStarted:
        return 'not_started';
      case TimerState.running:
        return 'running';
      case TimerState.paused:
        return 'paused';
      case TimerState.completed:
        return 'completed';
    }
  }

  static TimerState fromString(String value) {
    switch (value) {
      case 'not_started':
        return TimerState.notStarted;
      case 'running':
        return TimerState.running;
      case 'paused':
        return TimerState.paused;
      case 'completed':
        return TimerState.completed;
      default:
        return TimerState.notStarted;
    }
  }
}

/// Quest model representing a real-life activity
class Quest {
  final String? id;
  final String title;
  final String? description;
  final StatType statType;
  final Difficulty difficulty;

  // Time Tracking
  final int timeEstimatedMinutes; // Renamed from timeMinutes
  final int? timeActualMinutes;
  final int?
  timeActualSeconds; // precise seconds (avoids sub-minute rounding to 0)
  final DateTime? timeStarted;
  final DateTime? timePaused;
  final int? pausedDuration; // in milliseconds
  final TimerState timerState;

  // Deadline Management
  final DateTime? deadline;
  final bool? isOverdue;

  // Productivity Metrics
  final double? accuracyScore; // 0-100
  final double? productivityScore; // 0-100
  final int? focusRating; // 1-5
  final int? distractionCount;

  final int xpReward;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? templateId; // Link to quest template
  final bool isTemplateInstance; // Generated from template
  final bool isCompleted;
  final int streakAtCompletion;

  Quest({
    this.id,
    required this.title,
    this.description,
    required this.statType,
    required this.difficulty,
    required this.timeEstimatedMinutes,
    this.timeActualMinutes,
    this.timeActualSeconds,
    this.timeStarted,
    this.timePaused,
    this.pausedDuration,
    this.timerState = TimerState.notStarted,
    this.deadline,
    this.isOverdue,
    this.accuracyScore,
    this.productivityScore,
    this.focusRating,
    this.distractionCount,
    required this.xpReward,
    required this.createdAt,
    this.completedAt,
    this.templateId,
    this.isTemplateInstance = false,
    this.isCompleted = false,
    this.streakAtCompletion = 0,
  });

  /// Create from database map
  factory Quest.fromMap(Map<String, dynamic> map) {
    String? questId;
    if (map['id'] != null) {
      questId = map['id'] as String;
    } else if (map['_id'] != null) {
      // MongoDB _id is a string ObjectId - use it as the quest ID
      questId = map['_id'] as String;
    }

    // Handle templateId - backend returns MongoDB ObjectId as string or null
    String? templateIdValue;
    final templateIdRaw = map['templateId'] ?? map['template_id'];
    if (templateIdRaw != null) {
      templateIdValue = templateIdRaw.toString();
    }

    // Safe timerState parsing
    final timerStateRaw = map['timerState'] ?? map['timer_state'];
    final timerState = timerStateRaw != null
        ? TimerState.fromString(timerStateRaw as String)
        : TimerState.notStarted;

    return Quest(
      id: questId,
      title: map['title'] as String,
      description: map['description'] != null
          ? (map['description'] as String?) ?? ''
          : '',
      statType: StatType.fromString(
        (map['statType'] ?? map['stat_type']) as String,
      ),
      difficulty: Difficulty.fromValue(map['difficulty']),
      timeEstimatedMinutes:
          (map['timeEstimatedMinutes'] ??
                  map['time_estimated_minutes'] ??
                  map['timeMinutes'] ??
                  map['time_minutes'])
              as int,
      timeActualMinutes:
          (map['timeActualMinutes'] ?? map['time_actual_minutes']) != null
          ? ((map['timeActualMinutes'] ?? map['time_actual_minutes']) as num)
                .toInt()
          : null,
      timeActualSeconds:
          (map['timeActualSeconds'] ?? map['time_actual_seconds']) != null
          ? ((map['timeActualSeconds'] ?? map['time_actual_seconds']) as num)
                .toInt()
          : null,
      timeStarted: (map['timeStarted'] ?? map['time_started']) != null
          ? DateTime.parse(
              (map['timeStarted'] ?? map['time_started']) as String,
            )
          : null,
      timePaused: (map['timePaused'] ?? map['time_paused']) != null
          ? DateTime.parse((map['timePaused'] ?? map['time_paused']) as String)
          : null,
      pausedDuration: (map['pausedDuration'] ?? map['paused_duration']) as int?,
      timerState: timerState,
      deadline: (map['deadline']) != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      isOverdue: (map['isOverdue'] ?? map['is_overdue']) as bool?,
      accuracyScore: (map['accuracyScore'] ?? map['accuracy_score']) as double?,
      productivityScore:
          (map['productivityScore'] ?? map['productivity_score']) as double?,
      focusRating: (map['focusRating'] ?? map['focus_rating']) as int?,
      distractionCount:
          (map['distractionCount'] ?? map['distraction_count']) as int?,
      xpReward: (map['xpReward'] ?? map['xp_reward']) as int,
      createdAt: DateTime.parse(
        (map['dateCreated'] ?? map['date_created'] ?? map['createdAt'])
            as String,
      ),
      completedAt:
          (map['dateCompleted'] ??
                  map['date_completed'] ??
                  map['completedAt']) !=
              null
          ? DateTime.parse(
              (map['dateCompleted'] ??
                      map['date_completed'] ??
                      map['completedAt'])
                  as String,
            )
          : null,
      isCompleted:
          (map['isCompleted'] ?? map['is_completed']) as bool? ?? false,
      streakAtCompletion:
          (map['streakAtCompletion'] ?? map['streak_at_completion']) as int? ??
          0,
      templateId: templateIdValue,
      isTemplateInstance:
          (map['isTemplateInstance'] ?? map['is_template_instance']) as bool? ??
          false,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'statType': statType.toJson(),
      'difficulty': difficulty.value, // Send numeric value for backend
      'timeEstimatedMinutes': timeEstimatedMinutes,
      if (timeActualMinutes != null) 'timeActualMinutes': timeActualMinutes,
      if (timeActualSeconds != null) 'timeActualSeconds': timeActualSeconds,
      if (timeStarted != null) 'timeStarted': timeStarted!.toIso8601String(),
      if (timePaused != null) 'timePaused': timePaused!.toIso8601String(),
      'pausedDuration': pausedDuration,
      'timerState': timerState.toJson(),
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      'isOverdue': isOverdue,
      if (accuracyScore != null) 'accuracyScore': accuracyScore,
      if (productivityScore != null) 'productivityScore': productivityScore,
      if (focusRating != null) 'focusRating': focusRating,
      'distractionCount': distractionCount,
      'xpReward': xpReward,
      'dateCreated': createdAt.toIso8601String(),
      'dateCompleted': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'streakAtCompletion': streakAtCompletion,
      'templateId': templateId,
      'isTemplateInstance': isTemplateInstance,
    };
  }

  /// Get stat rewards as a map (stat display name -> reward amount)
  /// Based on backend logic: stat reward equals XP reward
  Map<String, int> get statRewards {
    return {statType.displayName: xpReward};
  }

  /// Create a copy with updated fields
  Quest copyWith({
    String? id,
    String? title,
    String? description,
    StatType? statType,
    Difficulty? difficulty,
    int? timeEstimatedMinutes,
    int? timeActualMinutes,
    int? timeActualSeconds,
    DateTime? timeStarted,
    DateTime? timePaused,
    int? pausedDuration,
    TimerState? timerState,
    DateTime? deadline,
    bool? isOverdue,
    double? accuracyScore,
    double? productivityScore,
    int? focusRating,
    int? distractionCount,
    int? xpReward,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isCompleted,
    int? streakAtCompletion,
    String? templateId,
    bool? isTemplateInstance,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      statType: statType ?? this.statType,
      difficulty: difficulty ?? this.difficulty,
      timeEstimatedMinutes: timeEstimatedMinutes ?? this.timeEstimatedMinutes,
      timeActualMinutes: timeActualMinutes ?? this.timeActualMinutes,
      timeActualSeconds: timeActualSeconds ?? this.timeActualSeconds,
      timeStarted: timeStarted ?? this.timeStarted,
      timePaused: timePaused ?? this.timePaused,
      pausedDuration: pausedDuration ?? this.pausedDuration,
      timerState: timerState ?? this.timerState,
      deadline: deadline ?? this.deadline,
      isOverdue: isOverdue ?? this.isOverdue,
      accuracyScore: accuracyScore ?? this.accuracyScore,
      productivityScore: productivityScore ?? this.productivityScore,
      focusRating: focusRating ?? this.focusRating,
      distractionCount: distractionCount ?? this.distractionCount,
      xpReward: xpReward ?? this.xpReward,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      streakAtCompletion: streakAtCompletion ?? this.streakAtCompletion,
      templateId: templateId ?? this.templateId,
      isTemplateInstance: isTemplateInstance ?? this.isTemplateInstance,
    );
  }
}
