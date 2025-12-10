import 'package:flutter/material.dart';

/// Utility class for managing SnackBars across the application
/// Prevents multiple SnackBars from stacking when users click rapidly
class SnackBarUtils {
  // Track currently showing snackbar message to prevent duplicates
  static String? _currentSnackBarMessage;
  static bool _isShowing = false;

  /// Shows a SnackBar with automatic clearing of any existing SnackBars
  /// This prevents multiple SnackBars from stacking when users click rapidly
  ///
  /// Usage:
  /// ```dart
  /// SnackBarUtils.showSnackBar(
  ///   context,
  ///   'Feature coming soon!',
  ///   duration: Duration(seconds: 2),
  /// );
  /// ```
  static void showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
    SnackBarAction? action,
  }) {
    // If same message is already showing, don't show again
    if (_isShowing && _currentSnackBarMessage == message) {
      return;
    }

    // Clear any existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();

    // Mark as showing
    _isShowing = true;
    _currentSnackBarMessage = message;

    // Show the new snackbar
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text(message),
            duration: duration,
            backgroundColor: backgroundColor,
            action: action,
          ),
        )
        .closed
        .then((_) {
          // Reset when snackbar is closed
          _isShowing = false;
          _currentSnackBarMessage = null;
        });
  }

  /// Shows an error SnackBar with red background
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackBar(
      context,
      message,
      duration: duration,
      backgroundColor: Colors.red,
    );
  }

  /// Shows a success SnackBar with green background
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    showSnackBar(
      context,
      message,
      duration: duration,
      backgroundColor: Colors.green,
    );
  }

  /// Shows a warning SnackBar with orange background
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    showSnackBar(
      context,
      message,
      duration: duration,
      backgroundColor: Colors.orange,
    );
  }

  /// Shows a "Coming Soon" message for unimplemented features
  static void showComingSoon(
    BuildContext context,
    String featureName, {
    Duration duration = const Duration(seconds: 1),
  }) {
    showSnackBar(
      context,
      '$featureName feature coming soon!',
      duration: duration,
      backgroundColor: Colors.blue,
    );
  }
}
