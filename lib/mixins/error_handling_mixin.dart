import 'package:flutter/material.dart';
import '../services/error_reporter.dart';

/// Mixin for standardized error handling across screens
///
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with ErrorHandlingMixin {
///   Future<void> _loadData() async {
///     try {
///       // ... your code ...
///     } catch (e, stackTrace) {
///       await handleError(e, stackTrace: stackTrace, screenName: 'MyScreen');
///     }
///   }
/// }
/// ```
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  final _errorReporter = ErrorReporter();

  /// Handle error with automatic reporting
  ///
  /// This method will:
  /// 1. Log the error locally
  /// 2. Check if auto-reporting is enabled
  /// 3. If yes: send error silently (no dialog)
  /// 4. If no: ask user for consent (dialog)
  /// 5. Show user-friendly error message
  Future<void> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? screenName,
    Map<String, dynamic>? context,
    bool showSnackBar = true,
  }) async {
    // Log locally
    _errorReporter.error(
      error.toString(),
      context: {
        'screen': screenName ?? runtimeType.toString(),
        'stackTrace': stackTrace?.toString() ?? '',
        ...?context,
      },
    );

    // Check if auto-reporting is enabled
    final autoSendEnabled = await _errorReporter.isAutoReportingEnabled();

    if (autoSendEnabled) {
      // Send silently (no dialog)
      await _errorReporter.sendErrorSilently(
        error,
        stackTrace: stackTrace,
        additionalContext: {
          'screen': screenName ?? runtimeType.toString(),
          ...?context,
        },
      );
    } else if (mounted) {
      // Ask user for consent (old behavior)
      await _errorReporter.reportError(
        this.context,
        error,
        stackTrace: stackTrace,
        additionalContext: {
          'screen': screenName ?? runtimeType.toString(),
          ...?context,
        },
      );
    }

    // Show user-friendly error message
    if (showSnackBar && mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              // Screens can override this by providing a callback
              // For now, just dismiss the snackbar
            },
          ),
        ),
      );
    }
  }

  /// Convenience method for API errors
  Future<void> handleApiError(
    dynamic error, {
    StackTrace? stackTrace,
    String? action,
    Map<String, dynamic>? additionalContext,
  }) async {
    await handleError(
      error,
      stackTrace: stackTrace,
      screenName: runtimeType.toString(),
      context: {
        'action': action ?? 'api_call',
        'error_type': 'api_error',
        ...?additionalContext,
      },
    );
  }
}
