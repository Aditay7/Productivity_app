class TimerSession {
  final String? id;
  final int durationMinutes;
  final String status; // active, completed, failed
  final String rank; // E, C, A, S
  final int xpEarned;
  final DateTime startedAt;
  final DateTime? endedAt;

  TimerSession({
    this.id,
    required this.durationMinutes,
    required this.status,
    required this.rank,
    this.xpEarned = 0,
    required this.startedAt,
    this.endedAt,
  });

  factory TimerSession.fromMap(Map<String, dynamic> map) {
    return TimerSession(
      id: map['id'] as String?,
      durationMinutes: map['durationMinutes'] as int,
      status: map['status'] as String,
      rank: map['rank'] as String,
      xpEarned: map['xpEarned'] as int? ?? 0,
      startedAt: DateTime.parse(map['startedAt'] as String).toLocal(),
      endedAt: map['endedAt'] != null
          ? DateTime.parse(map['endedAt'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'durationMinutes': durationMinutes,
      'status': status,
      'rank': rank,
      'xpEarned': xpEarned,
      'startedAt': startedAt.toUtc().toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt!.toUtc().toIso8601String(),
    };
  }
}
