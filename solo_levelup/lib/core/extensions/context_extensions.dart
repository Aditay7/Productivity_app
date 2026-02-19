import 'package:flutter/material.dart';

/// Extension methods for BuildContext
extension ContextExtensions on BuildContext {
  /// Get theme data
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => theme.textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Get media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get screen size
  Size get screenSize => mediaQuery.size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Show snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Navigate to a new screen
  Future<T?> push<T>(Widget screen) {
    return Navigator.of(
      this,
    ).push<T>(MaterialPageRoute(builder: (_) => screen));
  }

  /// Navigate and replace current screen
  Future<T?> pushReplacement<T extends Object?>(Widget screen) {
    return Navigator.of(
      this,
    ).pushReplacement<T, dynamic>(MaterialPageRoute(builder: (_) => screen));
  }

  /// Pop current screen
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }
}
