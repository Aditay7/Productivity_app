import 'package:flutter/material.dart';

/// Responsive utility class for adaptive sizing
class Responsive {
  final BuildContext context;

  Responsive(this.context);

  /// Get screen width
  double get width => MediaQuery.of(context).size.width;

  /// Get screen height
  double get height => MediaQuery.of(context).size.height;

  /// Check if screen is small (< 360px)
  bool get isSmall => width < 360;

  /// Check if screen is medium (360-414px)
  bool get isMedium => width >= 360 && width < 414;

  /// Check if screen is large (>= 414px)
  bool get isLarge => width >= 414;

  /// Get responsive padding
  double get padding => isSmall ? 12.0 : (isMedium ? 16.0 : 20.0);

  /// Get responsive spacing
  double get spacing => isSmall ? 8.0 : (isMedium ? 12.0 : 16.0);

  /// Get responsive font size multiplier
  double get fontScale => isSmall ? 0.9 : (isMedium ? 1.0 : 1.1);

  /// Get responsive value based on screen size
  T responsive<T>({
    required T small,
    required T medium,
    required T large,
  }) {
    if (isSmall) return small;
    if (isMedium) return medium;
    return large;
  }

  /// Get percentage of screen width
  double widthPercent(double percent) => width * (percent / 100);

  /// Get percentage of screen height
  double heightPercent(double percent) => height * (percent / 100);
}

/// Extension to easily access Responsive from BuildContext
extension ResponsiveContext on BuildContext {
  Responsive get responsive => Responsive(this);
}
