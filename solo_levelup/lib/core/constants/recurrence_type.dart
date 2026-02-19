/// Recurrence types for quest templates
enum RecurrenceType {
  daily,
  weekly,
  custom;

  String get displayName {
    switch (this) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case RecurrenceType.daily:
        return 'Repeats every day';
      case RecurrenceType.weekly:
        return 'Repeats on specific days';
      case RecurrenceType.custom:
        return 'Repeats every X days';
    }
  }

  String get emoji {
    switch (this) {
      case RecurrenceType.daily:
        return '📅';
      case RecurrenceType.weekly:
        return '📆';
      case RecurrenceType.custom:
        return '🔄';
    }
  }

  /// Convert to string for database storage
  String toJson() => toString().split('.').last;

  /// Convert from string
  static RecurrenceType fromJson(String json) {
    return RecurrenceType.values.firstWhere(
      (type) => type.toString().split('.').last == json,
      orElse: () => RecurrenceType.daily,
    );
  }
}
