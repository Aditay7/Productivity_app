/// Quest session model for tracking work sessions
class QuestSession {
  final String? id;
  final String questId;
  final DateTime sessionStart;
  final DateTime? sessionEnd;
  final int durationMinutes;
  final int pauseCount;
  final int? focusRating; // 1-5
  final String? notes;
  final DateTime createdAt;

  QuestSession({
    this.id,
    required this.questId,
    required this.sessionStart,
    this.sessionEnd,
    this.durationMinutes = 0,
    this.pauseCount = 0,
    this.focusRating,
    this.notes,
    required this.createdAt,
  });

  /// Create from database map
  factory QuestSession.fromMap(Map<String, dynamic> map) {
    String? sessionId;
    if (map['id'] != null) {
      sessionId = map['id'] as String;
    } else if (map['_id'] != null) {
      sessionId = map['_id'] as String;
    }

    return QuestSession(
      id: sessionId,
      questId: map['questId'] as String,
      sessionStart: DateTime.parse(map['sessionStart'] as String),
      sessionEnd: map['sessionEnd'] != null
          ? DateTime.parse(map['sessionEnd'] as String)
          : null,
      durationMinutes: (map['durationMinutes'] ?? 0) as int,
      pauseCount: (map['pauseCount'] ?? 0) as int,
      focusRating: map['focusRating'] as int?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(
        (map['createdAt'] ??
                map['created_at'] ??
                DateTime.now().toIso8601String())
            as String,
      ),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'questId': questId,
      'sessionStart': sessionStart.toIso8601String(),
      if (sessionEnd != null) 'sessionEnd': sessionEnd!.toIso8601String(),
      'durationMinutes': durationMinutes,
      'pauseCount': pauseCount,
      if (focusRating != null) 'focusRating': focusRating,
      if (notes != null) 'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  QuestSession copyWith({
    String? id,
    String? questId,
    DateTime? sessionStart,
    DateTime? sessionEnd,
    int? durationMinutes,
    int? pauseCount,
    int? focusRating,
    String? notes,
    DateTime? createdAt,
  }) {
    return QuestSession(
      id: id ?? this.id,
      questId: questId ?? this.questId,
      sessionStart: sessionStart ?? this.sessionStart,
      sessionEnd: sessionEnd ?? this.sessionEnd,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      pauseCount: pauseCount ?? this.pauseCount,
      focusRating: focusRating ?? this.focusRating,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
