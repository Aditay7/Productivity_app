import '../../core/constants/stat_types.dart';
import '../../core/constants/recurrence_type.dart';
import '../../core/constants/difficulty.dart';

/// Quest template for recurring quests
class QuestTemplate {
  final String? id;
  final String title;
  final String description;
  final int timeMinutes;
  final Difficulty difficulty;
  final StatType statType;
  final RecurrenceType recurrenceType;
  final List<int>? weekdays; // 1=Mon, 7=Sun
  final int? customDays; // Every X days
  final DateTime createdAt;
  final bool isActive;
  final DateTime? lastGeneratedDate;
  final bool isHabit;
  final int habitStreak;
  final DateTime? habitLastCompletedDate;
  final List<String> habitCompletionHistory; // ISO date strings

  const QuestTemplate({
    this.id,
    required this.title,
    required this.description,
    required this.timeMinutes,
    required this.difficulty,
    required this.statType,
    required this.recurrenceType,
    this.weekdays,
    this.customDays,
    required this.createdAt,
    this.isActive = true,
    this.lastGeneratedDate,
    this.isHabit = false,
    this.habitStreak = 0,
    this.habitLastCompletedDate,
    this.habitCompletionHistory = const [],
  });

  /// Create initial template
  factory QuestTemplate.initial() {
    return QuestTemplate(
      title: '',
      description: '',
      timeMinutes: 30,
      difficulty: Difficulty.C,
      statType: StatType.strength,
      recurrenceType: RecurrenceType.daily,
      createdAt: DateTime.now(),
      isActive: true,
      isHabit: false,
    );
  }

  /// Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'timeMinutes': timeMinutes,
      'difficulty': difficulty.toJson(),
      'statType': statType.toJson(),
      'recurrenceType': recurrenceType.toJson(),
      'weekdays': weekdays,
      'customDays': customDays,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
      'isHabit': isHabit,
      'habitStreak': habitStreak,
      'habitLastCompletedDate': habitLastCompletedDate?.toIso8601String(),
      'habitCompletionHistory': habitCompletionHistory,
    };
  }

  /// Create from database map
  factory QuestTemplate.fromMap(Map<String, dynamic> map) {
    return QuestTemplate(
      id: map['id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      timeMinutes: (map['timeMinutes'] ?? map['time_minutes']) as int,
      difficulty: Difficulty.fromValue(map['difficulty']),
      statType: StatType.fromString(
        (map['statType'] ?? map['stat_type']) as String,
      ),
      recurrenceType: RecurrenceType.fromJson(
        (map['recurrenceType'] ?? map['recurrence_type']) as String,
      ),
      weekdays: map['weekdays'] != null
          ? List<int>.from(map['weekdays'] as List)
          : null,
      customDays: (map['customDays'] ?? map['custom_days']) as int?,
      createdAt: DateTime.parse(
        (map['createdAt'] ?? map['created_at']) as String,
      ),
      isActive: (map['isActive'] ?? map['is_active']) as bool? ?? true,
      lastGeneratedDate:
          (map['lastGeneratedDate'] ?? map['last_generated_date']) != null
          ? DateTime.parse(
              (map['lastGeneratedDate'] ?? map['last_generated_date'])
                  as String,
            )
          : null,
      isHabit: (map['isHabit'] ?? map['is_habit']) as bool? ?? false,
      habitStreak: (map['habitStreak'] ?? map['habit_streak']) as int? ?? 0,
      habitLastCompletedDate:
          (map['habitLastCompletedDate'] ?? map['habit_last_completed_date']) !=
              null
          ? DateTime.parse(
              (map['habitLastCompletedDate'] ??
                      map['habit_last_completed_date'])
                  as String,
            )
          : null,
      habitCompletionHistory:
          (map['habitCompletionHistory'] ?? map['habit_completion_history']) !=
              null
          ? List<String>.from(
              (map['habitCompletionHistory'] ?? map['habit_completion_history'])
                  as List,
            )
          : [],
    );
  }

  /// Create a copy with updated fields
  QuestTemplate copyWith({
    String? id,
    String? title,
    String? description,
    int? timeMinutes,
    Difficulty? difficulty,
    StatType? statType,
    RecurrenceType? recurrenceType,
    List<int>? weekdays,
    int? customDays,
    DateTime? createdAt,
    bool? isActive,
    DateTime? lastGeneratedDate,
  }) {
    return QuestTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      difficulty: difficulty ?? this.difficulty,
      statType: statType ?? this.statType,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      weekdays: weekdays ?? this.weekdays,
      customDays: customDays ?? this.customDays,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
    );
  }

  /// Get human-readable recurrence description
  String get recurrenceDescription {
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return 'Every day';
      case RecurrenceType.weekly:
        if (weekdays == null || weekdays!.isEmpty) return 'Weekly';
        final days = weekdays!.map(_weekdayName).join(', ');
        return days;
      case RecurrenceType.custom:
        if (customDays == null) return 'Custom';
        return 'Every $customDays ${customDays == 1 ? 'day' : 'days'}';
    }
  }

  String _weekdayName(int day) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[day - 1];
  }
}
