// Stat types enum for the 5 core attributes
import 'package:flutter/material.dart';

enum StatType {
  strength,
  intelligence,
  discipline,
  wealth,
  charisma;

  // Display name for UI
  String get displayName {
    switch (this) {
      case StatType.strength:
        return 'Strength';
      case StatType.intelligence:
        return 'Intelligence';
      case StatType.discipline:
        return 'Discipline';
      case StatType.wealth:
        return 'Wealth';
      case StatType.charisma:
        return 'Charisma';
    }
  }

  // Description of what this stat represents
  String get description {
    switch (this) {
      case StatType.strength:
        return 'Physical fitness and health';
      case StatType.intelligence:
        return 'Mental growth and learning';
      case StatType.discipline:
        return 'Consistency and habits';
      case StatType.wealth:
        return 'Productivity and earning';
      case StatType.charisma:
        return 'Social skills and influence';
    }
  }

  // Icon emoji for this stat
  String get emoji {
    switch (this) {
      case StatType.strength:
        return '💪';
      case StatType.intelligence:
        return '🧠';
      case StatType.discipline:
        return '🎯';
      case StatType.wealth:
        return '💰';
      case StatType.charisma:
        return '✨';
    }
  }

  // Icon for this stat
  IconData get icon {
    switch (this) {
      case StatType.strength:
        return Icons.fitness_center;
      case StatType.intelligence:
        return Icons.psychology;
      case StatType.discipline:
        return Icons.track_changes;
      case StatType.wealth:
        return Icons.attach_money;
      case StatType.charisma:
        return Icons.people;
    }
  }

  // Color for this stat (hex value)
  int get colorValue {
    switch (this) {
      case StatType.strength:
        return 0xFFFF4D4D; // Premium Red
      case StatType.intelligence:
        return 0xFF4DA3FF; // Premium Blue
      case StatType.discipline:
        return 0xFFA855F7; // Premium Purple
      case StatType.wealth:
        return 0xFF22C55E; // Premium Green
      case StatType.charisma:
        return 0xFFF59E0B; // Premium Amber
    }
  }

  // Color object for this stat
  Color get color => Color(colorValue);

  // Convert to string (for database storage)
  String toJson() => toString().split('.').last;

  // Convert from string (for database storage)
  static StatType fromString(String value) {
    return StatType.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => StatType.strength,
    );
  }
}
