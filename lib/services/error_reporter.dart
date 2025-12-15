import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Error reporter service for user-consented error reporting
/// 
/// Features:
/// - Local log buffering (no automatic sending)
/// - User consent dialog before sending
/// - Privacy-first design
/// - Includes device info, stack traces, and action history
class ErrorReporter {
  static final ErrorReporter _instance = ErrorReporter._internal();
  factory ErrorReporter() => _instance;
  ErrorReporter._internal();

  final List<Map<String, dynamic>> _logBuffer = [];
  static const int _maxBufferSize = 100; // Keep last 100 logs
  
  String? _appVersion;
  String? _platform;
  String? _platformVersion;

  /// Initialize device and app info
  Future<void> initialize() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      
      if (kIsWeb) {
        _platform = 'Web';
        _platformVersion = 'Unknown';
      } else if (Platform.isAndroid) {
        _platform = 'Android';
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        _platformVersion = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        _platform = 'iOS';
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        _platformVersion = 'iOS ${iosInfo.systemVersion}';
      }
      
      debugPrint('[ERROR REPORTER] Initialized: $_platform $_platformVersion | App: $_appVersion');
    } catch (e) {
      debugPrint('[ERROR REPORTER] Failed to initialize: $e');
    }
  }

  /// Add a log entry to buffer (local only, not sent automatically)
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? context,
  }) {
    final logEntry = {
      'level': level.name,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      if (context != null) 'context': context,
    };

    _logBuffer.add(logEntry);

    // Keep buffer size limited
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0); // Remove oldest
    }

    // Also print locally (only in debug mode)
    if (kDebugMode) {
      debugPrint('[${level.name.toUpperCase()}] $message');
    }
  }

  /// Convenience methods for different log levels
  void debug(String message, {Map<String, dynamic>? context}) {
    log(message, level: LogLevel.debug, context: context);
  }

  void info(String message, {Map<String, dynamic>? context}) {
    log(message, level: LogLevel.info, context: context);
  }

  void warning(String message, {Map<String, dynamic>? context}) {
    log(message, level: LogLevel.warning, context: context);
  }

  void error(String message, {Map<String, dynamic>? context}) {
    log(message, level: LogLevel.error, context: context);
  }

  /// Clear log buffer
  void clear() {
    _logBuffer.clear();
  }

  /// Show error dialog and ask user for consent to send report
  Future<void> reportError(
    BuildContext context,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalContext,
  }) async {
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Colors.orange),
            SizedBox(width: 8),
            Text('Error Occurred'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'An error occurred while processing your request.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${error.toString()}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you like to send an error report to help us fix this issue?',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'The report will include:\n'
              '• Error details and stack trace\n'
              '• Recent actions leading to the error\n'
              '• Device and app version info',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, thanks'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send Report'),
          ),
        ],
      ),
    );

    if (shouldSend != true) {
      debugPrint('[ERROR REPORTER] User declined to send error report');
      clear(); // Clear buffer since user declined
      return;
    }

    // User consented, send report
    try {
      await _sendErrorReport(
        error,
        stackTrace: stackTrace,
        additionalContext: additionalContext,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Error report sent. Thank you!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ERROR REPORTER] Failed to send report: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send error report'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Send error report silently (no dialog)
  /// Only call this if user has opted-in to automatic reporting
  Future<void> sendErrorSilently(
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      await _sendErrorReport(
        error,
        stackTrace: stackTrace,
        additionalContext: additionalContext,
      );
      debugPrint('[ERROR REPORTER] Silent report sent successfully');
    } catch (e) {
      debugPrint('[ERROR REPORTER] Failed to send silent report: $e');
      // Don't throw - silent failures are OK
    }
  }

  /// Check if auto-reporting is enabled
  Future<bool> isAutoReportingEnabled() async {
    try {
      // Import SharedPreferences only when needed
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('auto_send_error_reports') ?? false;
    } catch (e) {
      debugPrint('[ERROR REPORTER] Failed to check auto-reporting setting: $e');
      return false;
    }
  }

  /// Send error report to backend
  Future<void> _sendErrorReport(
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalContext,
  }) async {
    final apiService = ApiService();
    
    // Get current user info if available
    String? userId;
    String? username;
    try {
      final userData = await apiService.getCurrentUser();
      userId = userData['discord_id']?.toString();
      username = userData['username']?.toString() ?? userData['global_name']?.toString();
    } catch (e) {
      debugPrint('[ERROR REPORTER] Could not fetch user info: $e');
      // Continue without user info - better to send error without user than not send at all
    }
    
    final report = {
      'user_consented': true,
      'error': {
        'message': error.toString(),
        'type': error.runtimeType.toString(),
        'stackTrace': stackTrace?.toString() ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      },
      'context': {
        ...?additionalContext,
        if (userId != null) 'user_id': userId,
        if (username != null) 'username': username,
      },
      'logs': _logBuffer,
      'device': {
        'platform': _platform ?? 'Unknown',
        'version': _platformVersion ?? 'Unknown',
        'app_version': _appVersion ?? 'Unknown',
      },
    };

    debugPrint('[ERROR REPORTER] Sending report to ${apiService.baseUrl}/debug/error-report');
    
    final response = await http.post(
      Uri.parse('${apiService.baseUrl}/debug/error-report'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(report),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      debugPrint('[ERROR REPORTER] Report sent successfully');
      clear(); // Clear buffer after successful send
    } else {
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    }
  }
}
