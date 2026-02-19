import 'package:flutter/material.dart';

/// Difficulty levels for quests
enum Difficulty {
  E(1, 'E-Rank', 1.0, 0xFF4CAF50),  // Green
  D(2, 'D-Rank', 1.5, 0xFF2196F3),  // Blue
  C(3, 'C-Rank', 2.0, 0xFFFFEB3B),  // Yellow
  B(4, 'B-Rank', 2.5, 0xFFFF9800),  // Orange
  A(5, 'A-Rank', 3.0, 0xFFFF5722),  // Deep Orange
  S(6, 'S-Rank', 4.0, 0xFFE91E63);  // Pink

  final int value;
  final String displayName;
  final double multiplier;
  final int colorValue;

  const Difficulty(this.value, this.displayName, this.multiplier, this.colorValue);

  /// Get Color object
  Color get color => Color(colorValue);

  /// Convert to JSON string
  String toJson() => toString().split('.').last;

  /// Convert from value (int or string)
  static Difficulty fromValue(dynamic value) {
    if (value is int) {
      return Difficulty.values.firstWhere(
        (e) => e.value == value,
        orElse: () => Difficulty.E,
      );
    }
    if (value is String) {
      return Difficulty.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == value.toLowerCase(),
        orElse: () => Difficulty.E,
      );
    }
    return Difficulty.E;
  }

  /// Convert from string
  static Difficulty fromString(String value) {
    return Difficulty.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == value.toLowerCase(),
      orElse: () => Difficulty.E,
    );
  }
}
