import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/cog.dart';
import '../models/ticket.dart';
import '../models/ticket_config.dart';

/// Custom exceptions for better error handling
class ApiTimeoutException implements Exception {
  final String message;
  ApiTimeoutException([this.message = 'Server not responding... 🦥']);
}

class ApiConnectionException implements Exception {
  final String message;
  ApiConnectionException([this.message = 'No connection to server... 🌴']);
}

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initializeVersionInfo();
    _generateSessionId();
  }

  // App version info for session tracking
  String _appVersion = 'Unknown';
  String _platform = 'Unknown';
  String _deviceInfo = 'Unknown';
  String _sessionId = 'Unknown';
  Completer<void>? _versionInitCompleter;

  // Public getter for session ID
  String get sessionId => _sessionId;

  Future<void> _initializeVersionInfo() async {
    if (_versionInitCompleter != null) {
      return _versionInitCompleter!.future;
    }

    _versionInitCompleter = Completer<void>();

    try {
      if (kDebugMode) {
        // In Debug mode: Use current date as version to avoid showing outdated CI build info
        final now = DateTime.now();
        final dateStr =
            '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _appVersion = '$dateStr-dev-$timeStr';
      } else {
        // In Release mode: Use actual build info from CI/CD
        final packageInfo = await PackageInfo.fromPlatform();
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      }

      // Get device info
      final deviceInfoPlugin = DeviceInfoPlugin();

      // Determine platform and device info
      if (kIsWeb) {
        _platform = 'Web';
        try {
          final webInfo = await deviceInfoPlugin.webBrowserInfo;
          _deviceInfo =
              '${webInfo.browserName.name} on ${webInfo.platform ?? 'Unknown OS'}';
        } catch (e) {
          _deviceInfo = 'Web Browser';
        }
      } else if (Platform.isAndroid) {
        _platform = kDebugMode ? 'Android (Debug)' : 'Android';
        try {
          final androidInfo = await deviceInfoPlugin.androidInfo;
          final manufacturer = androidInfo.manufacturer;
          final model = androidInfo.model;
          _deviceInfo = '$manufacturer $model';
          debugPrint('📱 Android Device: $_deviceInfo');
          debugPrint('   Manufacturer: $manufacturer');
          debugPrint('   Model: $model');
          debugPrint('   Brand: ${androidInfo.brand}');
          debugPrint('   Device: ${androidInfo.device}');
          debugPrint('   Product: ${androidInfo.product}');
        } catch (e) {
          debugPrint('❌ Failed to get Android device info: $e');
          _deviceInfo = 'Android Device';
        }
      } else if (Platform.isIOS) {
        _platform = kDebugMode ? 'iOS (Debug)' : 'iOS';
        try {
          final iosInfo = await deviceInfoPlugin.iosInfo;
          _deviceInfo = '${iosInfo.name} (${iosInfo.model})';
        } catch (e) {
          _deviceInfo = 'iOS Device';
        }
      } else if (Platform.isWindows) {
        _platform = 'Windows';
        try {
          final windowsInfo = await deviceInfoPlugin.windowsInfo;
          _deviceInfo = windowsInfo.computerName;
        } catch (e) {
          _deviceInfo = 'Windows PC';
        }
      } else if (Platform.isLinux) {
        _platform = 'Linux';
        try {
          final linuxInfo = await deviceInfoPlugin.linuxInfo;
          _deviceInfo = linuxInfo.prettyName;
        } catch (e) {
          _deviceInfo = 'Linux PC';
        }
      } else if (Platform.isMacOS) {
        _platform = 'macOS';
        try {
          final macInfo = await deviceInfoPlugin.macOsInfo;
          _deviceInfo = macInfo.computerName;
        } catch (e) {
          _deviceInfo = 'macOS';
        }
      } else {
        _platform = 'Unknown';
        _deviceInfo = 'Unknown Device';
      }

      debugPrint('📱 App Version: $_appVersion ($_platform)');
      debugPrint('📱 Device Info: $_deviceInfo');
      _versionInitCompleter!.complete();
    } catch (e) {
      debugPrint('❌ Failed to get package info: $e');
      _versionInitCompleter!.complete();
    }
  }

  /// Generate a unique session ID when the app starts
  /// This creates a new session for analytics tracking
  void _generateSessionId() {
    // Create unique session ID: timestamp + random component
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 31) % 1000000; // Simple random component
    _sessionId = '${timestamp}_$random';
    debugPrint('📊 Session ID: $_sessionId');
    
    // Debug: Show environment detection
    debugPrint('🔧 Environment Detection:');
    debugPrint('   Platform: ${kIsWeb ? 'WEB' : 'MOBILE'}');
    debugPrint('   Base URL: $_staticBaseUrl');
    if (kIsWeb) {
      debugPrint('   Origin: ${Uri.base.origin}');
      debugPrint('   ✅ Using nginx proxy (relative URLs)');
    }
  }

  // ============================================================================
  // ENVIRONMENT DETECTION: Web vs Mobile
  // ============================================================================
  // WEB: Uses relative URLs (nginx proxies to api.haze.pro)
  //      Example: admin.haze.pro/api/tickets → nginx → api.haze.pro/api/tickets
  // MOBILE: Uses direct URLs to api.haze.pro
  //      Example: https://api.haze.pro/api/tickets
  // ============================================================================

  static String? _cachedBaseUrl; // Cache to prevent log spam
  static bool _baseUrlLogged = false; // Track if we've logged the platform detection

  static String get _staticBaseUrl {
    if (_cachedBaseUrl == null) {
      // Lazy initialization on first access
      if (kIsWeb) {
        // WEB: Relative URLs - nginx proxies transparently
        _cachedBaseUrl = '/api'; // Relative to current host (admin.haze.pro)
        if (!_baseUrlLogged) {
          debugPrint('🌐 Platform: WEB - Using relative URLs (nginx proxy)');
          _baseUrlLogged = true;
        }
      } else {
        // MOBILE: Direct connection to api.haze.pro
        _cachedBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5070/api';
        if (!_baseUrlLogged) {
          debugPrint('📱 Platform: MOBILE - Using direct URL: $_cachedBaseUrl');
          _baseUrlLogged = true;
        }
      }
    }
    return _cachedBaseUrl!;
  }

  String get baseUrl => _staticBaseUrl;

  String? _token;
  bool _isRefreshing = false;
  Completer<bool>?
      _refreshCompleter; // For parallel refresh requests - signals completion

  // Callback to update user info after token refresh (without extra API call)
  Function(Map<String, dynamic>)? onUserInfoUpdated;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  // REMOVED: No proactive token expiration check
  // Token is only refreshed when backend returns 401
  // This is simpler and more reliable

  /// Refresh the JWT token with a new expiry date
  /// Uses Completer to ensure only ONE refresh happens at a time, even with parallel requests
  Future<Map<String, dynamic>?> refreshToken() async {
    // If already refreshing, wait for that refresh to complete
    if (_isRefreshing && _refreshCompleter != null) {
      try {
        await _refreshCompleter!.future;
        return {
          'token': _token,
          'success': true,
        };
      } catch (e) {
        return null;
      }
    }

    if (_token == null || _token!.isEmpty) {
      return null;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>(); // Changed to bool for success signal

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Token refresh timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];

        if (newToken != null && newToken.isNotEmpty) {
          // Validate JWT structure
          if (newToken.split('.').length != 3) {
            _refreshCompleter!.complete(false);
            return null;
          }

          // CRITICAL: Save token in memory FIRST (synchronous)
          setToken(newToken);

          // Save to SharedPreferences (async, but complete before signaling)
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', newToken);
          } catch (e) {
            debugPrint('⚠️ Failed to save token to SharedPreferences: $e');
          }

          // Update user info synchronously BEFORE completing (no race condition)
          if (onUserInfoUpdated != null && data.containsKey('user')) {
            debugPrint('🔔 Updating user info from refresh response (sync)');
            onUserInfoUpdated!(data); // Call directly, not via microtask
          }

          // NOW signal completion - token and user info are both updated
          _refreshCompleter!.complete(true);

          return data;
        } else {
          _refreshCompleter!.complete(false);
        }
      } else {
        _refreshCompleter!.complete(false);
      }
    } catch (e) {
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(false);
      }
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }

    return null;
  }

  /// Make HTTP request with automatic token refresh on 401
  /// SIMPLE VERSION: Only refresh when backend says 401, no proactive checks
  /// CRITICAL: Request builder is called FRESH each time to get latest token!
  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() requestBuilder, {
    int maxRetries = 1,
  }) async {
    // Execute request - call builder to get fresh headers with current token
    http.Response response = await requestBuilder();

    // If 401: refresh token and retry ONCE
    if (response.statusCode == 401 && maxRetries > 0) {
      debugPrint('⚠️ Got 401, attempting token refresh and retry...');

      // If another request is already refreshing, wait for it
      if (_isRefreshing && _refreshCompleter != null) {
        debugPrint('⏳ Another request is refreshing, waiting...');
        await _refreshCompleter!.future;
        // CRITICAL: Small delay to ensure token is fully propagated in all closures
        await Future.delayed(const Duration(milliseconds: 50));
        debugPrint(
            '✅ Refresh completed by other request, retrying with fresh token...');
      } else {
        // Refresh token
        await refreshToken();
        debugPrint('✅ Token refreshed, retrying request...');
      }

      // CRITICAL: Call requestBuilder AGAIN to get FRESH headers with NEW token!
      // This is why we pass a builder function instead of a Response directly
      final retryResponse =
          await _requestWithRetry(requestBuilder, maxRetries: maxRetries - 1);
      if (retryResponse.statusCode != 401) {
        debugPrint('✅ Retry successful (${retryResponse.statusCode})');
      }
      return retryResponse;
    }

    return response;
  }

  /// HTTP GET with automatic token refresh and timeout handling
  /// IMPORTANT: Headers are computed inside the lambda to get fresh token after refresh
  Future<http.Response> _get(String url,
      {Map<String, String>? headers, int timeoutSeconds = 15}) async {
    // CRITICAL: Return a builder function that reads _token FRESH each time it's called!
    // This ensures retry after refresh uses the NEW token, not the old one
    try {
      // Ensure version info is loaded before making requests
      await _initializeVersionInfo();

      return await _requestWithRetry(() async {
        // Read token FRESH from instance variable (not captured in closure)
        final String currentToken = _token ?? '';

        // Build headers with CURRENT token and User-Agent
        final Map<String, String> freshHeaders = {
          'Content-Type': 'application/json',
          'User-Agent': _userAgent,
          'X-App-Version': _appVersion,
          'X-Platform': _platform,
          'X-Device-Info': _deviceInfo,
          'X-Session-ID': _sessionId,
          if (currentToken.isNotEmpty) 'Authorization': 'Bearer $currentToken',
          ...?headers,
        };

        return await http.get(Uri.parse(url), headers: freshHeaders).timeout(
              Duration(seconds: timeoutSeconds),
              onTimeout: () => throw ApiTimeoutException(),
            );
      });
    } on SocketException {
      throw ApiConnectionException();
    } on TimeoutException {
      throw ApiTimeoutException();
    }
  }

  /// HTTP POST with automatic token refresh and timeout handling
  /// IMPORTANT: Headers are computed inside the lambda to get fresh token after refresh
  Future<http.Response> _post(String url,
      {Map<String, String>? headers, Object? body, int timeout = 15}) async {
    try {
      // Ensure version info is loaded before making requests
      await _initializeVersionInfo();

      final response = await _requestWithRetry(() async {
        // Read token FRESH from instance variable
        final String currentToken = _token ?? '';

        final Map<String, String> freshHeaders = {
          'Content-Type': 'application/json',
          'User-Agent': _userAgent,
          'X-App-Version': _appVersion,
          'X-Platform': _platform,
          'X-Device-Info': _deviceInfo,
          'X-Session-ID': _sessionId,
          if (currentToken.isNotEmpty) 'Authorization': 'Bearer $currentToken',
          ...?headers,
        };

        final httpResponse = await http
            .post(Uri.parse(url), headers: freshHeaders, body: body)
            .timeout(
              Duration(seconds: timeout),
              onTimeout: () {
                throw ApiTimeoutException();
              },
            );
        return httpResponse;
      });
      
      return response;
    } on SocketException {
      throw ApiConnectionException();
    } on TimeoutException {
      throw ApiTimeoutException();
    } catch (e) {
      rethrow;
    }
  }

  /// HTTP PUT with automatic token refresh and timeout handling
  /// IMPORTANT: Headers are computed inside the lambda to get fresh token after refresh
  Future<http.Response> _put(String url,
      {Map<String, String>? headers, Object? body}) async {
    try {
      // Ensure version info is loaded before making requests
      await _initializeVersionInfo();

      return await _requestWithRetry(() async {
        // Read token FRESH from instance variable
        final String currentToken = _token ?? '';

        final Map<String, String> freshHeaders = {
          'Content-Type': 'application/json',
          'User-Agent': _userAgent,
          'X-App-Version': _appVersion,
          'X-Platform': _platform,
          'X-Device-Info': _deviceInfo,
          'X-Session-ID': _sessionId,
          if (currentToken.isNotEmpty) 'Authorization': 'Bearer $currentToken',
          ...?headers,
        };

        return await http
            .put(Uri.parse(url), headers: freshHeaders, body: body)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw ApiTimeoutException(),
            );
      });
    } on SocketException {
      throw ApiConnectionException();
    } on TimeoutException {
      throw ApiTimeoutException();
    }
  }

  /// HTTP DELETE with automatic token refresh and timeout handling
  /// IMPORTANT: Headers are computed inside the lambda to get fresh token after refresh
  Future<http.Response> _delete(String url,
      {Map<String, String>? headers}) async {
    try {
      // Ensure version info is loaded before making requests
      await _initializeVersionInfo();

      return await _requestWithRetry(() async {
        // Read token FRESH from instance variable
        final String currentToken = _token ?? '';

        final Map<String, String> freshHeaders = {
          'Content-Type': 'application/json',
          'User-Agent': _userAgent,
          'X-App-Version': _appVersion,
          'X-Platform': _platform,
          'X-Device-Info': _deviceInfo,
          'X-Session-ID': _sessionId,
          if (currentToken.isNotEmpty) 'Authorization': 'Bearer $currentToken',
          ...?headers,
        };

        return await http.delete(Uri.parse(url), headers: freshHeaders).timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw ApiTimeoutException(),
            );
      });
    } on SocketException {
      throw ApiConnectionException();
    } on TimeoutException {
      throw ApiTimeoutException();
    }
  }

  String get _userAgent {
    // Detect platform and create appropriate user agent
    // Use environment-based app name (Chillventory for prod, Testventory for dev)
    final appName = dotenv.env['PROD_MODE']?.toLowerCase() == 'true'
        ? 'Chillventory'
        : 'Testventory';

    if (kIsWeb) {
      return '$appName/1.0 (Web; Flutter)';
    } else {
      try {
        if (Platform.isAndroid) {
          return '$appName/1.0 (Android; Flutter)';
        } else if (Platform.isIOS) {
          return '$appName/1.0 (iOS; Flutter)';
        } else if (Platform.isWindows) {
          return '$appName/1.0 (Windows; Flutter)';
        } else if (Platform.isMacOS) {
          return '$appName/1.0 (macOS; Flutter)';
        } else if (Platform.isLinux) {
          return '$appName/1.0 (Linux; Flutter)';
        }
      } catch (e) {
        // Fallback if Platform is not available
      }
    }
    return '$appName/1.0 (Unknown; Flutter)';
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'User-Agent': _userAgent,
    };

    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // Headers for unauthenticated requests (no token, but includes User-Agent)
  Map<String, String> get _publicHeaders {
    return {
      'Content-Type': 'application/json',
      'User-Agent': _userAgent,
    };
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _publicHeaders,
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  // Discord OAuth2 Methods
  Future<Map<String, dynamic>> getDiscordAuthUrl() async {
    final response = await http.get(
      Uri.parse('$baseUrl/discord/auth'),
      headers: _publicHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get Discord auth URL: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> exchangeDiscordCode(String code) async {
    final response = await http.get(
      Uri.parse('$baseUrl/discord/callback?code=$code'),
      headers: _publicHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to exchange Discord code: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );

    if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get current user: ${response.body}');
    }
  }

  Future<void> logout() async {
    try {
      await _post('$baseUrl/auth/logout');
    } catch (e) {
      // Ignore errors - session will expire naturally
      debugPrint('Logout endpoint error: $e');
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getConfig() async {
    try {
      final response = await _get('$baseUrl/config');

      debugPrint('getConfig response status: ${response.statusCode}');

      if (response.statusCode == 401) {
        // Token expired or invalid (should be handled by auto-refresh now)
        throw TokenExpiredException('Token has expired or is invalid');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to load configuration. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception in getConfig: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGeneralConfig() async {
    final response = await _get('$baseUrl/config/general');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load general configuration');
    }
  }

  Future<void> updateGeneralConfig(Map<String, dynamic> config) async {
    final response = await _put(
      '$baseUrl/config/general',
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update general configuration');
    }
  }

  Future<void> resetGeneralConfig() async {
    final response = await _post('$baseUrl/config/general/reset');

    if (response.statusCode != 200) {
      throw Exception('Failed to reset general configuration');
    }
  }

  Future<Map<String, dynamic>> getChannelsConfig() async {
    final response = await _get('$baseUrl/config/channels');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load channels configuration');
    }
  }

  Future<void> updateChannelsConfig(Map<String, dynamic> config) async {
    final response = await _put(
      '$baseUrl/config/channels',
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update channels configuration');
    }
  }

  Future<Map<String, dynamic>> getRolesConfig() async {
    final response = await _get('$baseUrl/config/roles');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load roles configuration');
    }
  }

  Future<void> updateRolesConfig(Map<String, dynamic> config) async {
    final response = await _put(
      '$baseUrl/config/roles',
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update roles configuration');
    }
  }

  Future<Map<String, dynamic>> getMemeConfig() async {
    final response = await _get('$baseUrl/config/meme');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load meme configuration');
    }
  }

  Future<void> updateMemeConfig(Map<String, dynamic> config) async {
    final response = await _put(
      '$baseUrl/config/meme',
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update meme configuration');
    }
  }

  // Daily Meme Configuration
  Future<Map<String, dynamic>> getDailyMemeConfig() async {
    final response = await _get('$baseUrl/daily-meme/config');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load daily meme configuration');
    }
  }

  Future<void> updateDailyMemeConfig(Map<String, dynamic> config) async {
    debugPrint('Sending daily meme config: ${jsonEncode(config)}');
    final response = await _post(
      '$baseUrl/daily-meme/config',
      body: jsonEncode(config),
    );

    debugPrint('Daily meme config response status: ${response.statusCode}');
    debugPrint('Daily meme config response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update daily meme configuration: ${response.body}');
    }
  }

  Future<void> resetDailyMemeConfig() async {
    final response = await _post('$baseUrl/daily-meme/config/reset');

    if (response.statusCode != 200) {
      throw Exception('Failed to reset daily meme configuration');
    }
  }

  Future<Map<String, dynamic>> getRocketLeagueConfig() async {
    final response = await _get('$baseUrl/config/rocket_league');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load Rocket League configuration');
    }
  }

  Future<void> updateRocketLeagueConfig(Map<String, dynamic> config) async {
    final response = await _put(
      '$baseUrl/config/rocket_league',
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update Rocket League configuration');
    }
  }

  Future<void> resetRocketLeagueConfig() async {
    final response = await _post('$baseUrl/config/rocket_league/reset');

    if (response.statusCode != 200) {
      throw Exception('Failed to reset Rocket League configuration');
    }
  }

  // Rocket League Account Management
  Future<List<Map<String, dynamic>>> getRocketLeagueAccounts() async {
    final response = await _get('$baseUrl/rocket-league/accounts');

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load Rocket League accounts');
    }
  }

  Future<void> deleteRocketLeagueAccount(String userId) async {
    final response = await _delete('$baseUrl/rocket-league/accounts/$userId');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete Rocket League account');
    }
  }

  Future<Map<String, dynamic>> triggerRankCheck() async {
    final response = await _post('$baseUrl/rocket-league/check-ranks');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to trigger rank check: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getRocketLeagueStats(
      String platform, String username) async {
    // Rocket League API can take 30+ seconds on first fetch (no cache)
    final response = await _get(
        '$baseUrl/rocket-league/stats/$platform/$username',
        timeoutSeconds: 45);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get Rocket League stats: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUserRLAccount() async {
    final response = await _get('$baseUrl/user/rocket-league/account');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user RL account: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getRLStats(
      String platform, String username) async {
    // Rocket League API can take 30+ seconds on first fetch (no cache)
    final response = await _get(
        '$baseUrl/rocket-league/stats/$platform/$username',
        timeoutSeconds: 45);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to fetch RL stats');
    }
  }

  Future<Map<String, dynamic>> linkUserRLAccount(
      String platform, String username) async {
    final response = await _post(
      '$baseUrl/user/rocket-league/link',
      body: jsonEncode({'platform': platform, 'username': username}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to link RL account');
    }
  }

  Future<Map<String, dynamic>> unlinkUserRLAccount() async {
    final response = await _delete('$baseUrl/user/rocket-league/unlink');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to unlink RL account: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> postUserRLStats() async {
    final response = await _post(
      '$baseUrl/user/rocket-league/post-stats',
      body: jsonEncode({}), // No body needed, user is from token
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to post stats');
    }
  }

  Future<Map<String, dynamic>> updateUserPreferences(
      Map<String, dynamic> preferences) async {
    final response = await _put(
      '$baseUrl/user/preferences',
      body: jsonEncode(preferences),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update preferences');
    }
  }

  // Gaming Hub Methods
  Future<Map<String, dynamic>> getGamingMembers() async {
    final response = await _get('$baseUrl/gaming/members');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to load gaming members');
    }
  }

  Future<Map<String, dynamic>> postGameRequest(
    String targetUserId,
    String gameName,
    String message,
  ) async {
    final response = await _post(
      '$baseUrl/gaming/request',
      body: jsonEncode({
        'target_user_id': targetUserId,
        'game_name': gameName,
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to post game request');
    }
  }

  Future<Map<String, dynamic>> getWelcomeConfig() async {
    final response = await _get('$baseUrl/config/welcome');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load welcome configuration');
    }
  }

  Future<void> updateWelcomeConfig(Map<String, dynamic> config) async {
    final response = await _put(
      '$baseUrl/config/welcome',
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update welcome configuration');
    }
  }

  Future<Map<String, dynamic>> resetWelcomeConfig() async {
    final response = await _post('$baseUrl/config/welcome/reset');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to reset welcome configuration');
    }
  }

  Future<Map<String, dynamic>> getWelcomeTextsConfig() async {
    final response = await _get('$baseUrl/config/welcome_texts');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load welcome texts configuration');
    }
  }

  Future<void> updateWelcomeTextsConfig(Map<String, dynamic> config) async {
    final response = await _put(
      '$baseUrl/config/welcome_texts',
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update welcome texts configuration');
    }
  }

  Future<Map<String, dynamic>> resetWelcomeTextsConfig() async {
    final response = await _post('$baseUrl/config/welcome_texts/reset');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to reset welcome texts configuration');
    }
  }

  Future<Map<String, dynamic>> getRocketLeagueTextsConfig() async {
    final response = await _get('$baseUrl/config/rocket_league_texts');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load Rocket League texts configuration');
    }
  }

  Future<void> updateRocketLeagueTextsConfig(
      Map<String, dynamic> config) async {
    final response = await _put(
      '$baseUrl/config/rocket_league_texts',
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update Rocket League texts configuration');
    }
  }

  Future<Map<String, dynamic>> resetRocketLeagueTextsConfig() async {
    final response = await _post('$baseUrl/config/rocket_league_texts/reset');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to reset Rocket League texts configuration');
    }
  }

  Future<Map<String, dynamic>> getServerGuideConfig() async {
    final response = await _get('$baseUrl/config/server_guide');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load server guide configuration');
    }
  }

  Future<void> updateServerGuideConfig(Map<String, dynamic> config) async {
    final response = await _put(
      '$baseUrl/config/server_guide',
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update server guide configuration');
    }
  }

  // Test functions
  Future<Map<String, dynamic>> getMemeSources() async {
    final response = await _get('$baseUrl/meme-sources');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get meme sources: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getMemeFromSource(String source) async {
    final response = await _get(
        '$baseUrl/test/meme-from-source?source=${Uri.encodeComponent(source)}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get meme from source: ${response.body}');
    }
  }

  // ===== MEME GENERATOR ENDPOINTS =====

  Future<Map<String, dynamic>> getMemeTemplates() async {
    final response = await _get('$baseUrl/meme-generator/templates');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get meme templates: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> refreshMemeTemplates() async {
    final response = await _post('$baseUrl/meme-generator/templates/refresh');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to refresh meme templates: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> generateMeme(
      String templateId, List<String> texts) async {
    final response = await _post(
      '$baseUrl/meme-generator/generate',
      body: jsonEncode({
        'template_id': templateId,
        'texts': texts,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate meme: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> postGeneratedMemeToDiscord(
      String memeUrl, String templateName, List<String> texts) async {
    final response = await _post(
      '$baseUrl/meme-generator/post-to-discord',
      body: jsonEncode({
        'meme_url': memeUrl,
        'template_name': templateName,
        'texts': texts,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to post meme to Discord: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getRandomMeme() async {
    final response = await _get('$baseUrl/test/random-meme');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get random meme: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> testDailyMeme() async {
    final response = await _post('$baseUrl/test/daily-meme');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to test daily meme: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> sendMemeToDiscord(
      Map<String, dynamic> meme) async {
    final response = await _post(
      '$baseUrl/test/send-meme',
      body: jsonEncode({'meme': meme}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send meme to Discord: ${response.body}');
    }
  }

  // Guild Info
  Future<List<Map<String, dynamic>>> getGuildChannels() async {
    final response = await _get('$baseUrl/guild/channels');

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load guild channels');
    }
  }

  Future<List<Map<String, dynamic>>> getGuildRoles() async {
    final response = await _get('$baseUrl/guild/roles');

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load guild roles');
    }
  }

  Future<void> resetChannelsConfig() async {
    final response = await _post('$baseUrl/config/channels/reset');

    if (response.statusCode != 200) {
      throw Exception('Failed to reset channels configuration');
    }
  }

  Future<void> resetRolesConfig() async {
    final response = await _post('$baseUrl/config/roles/reset');

    if (response.statusCode != 200) {
      throw Exception('Failed to reset roles configuration');
    }
  }

  // ===== LOGS ENDPOINTS =====

  Future<Map<String, dynamic>> getLogs({
    String? cog,
    String? level,
    int limit = 500,
    String? search,
  }) async {
    // Build query parameters
    final params = <String, String>{
      'limit': limit.toString(),
    };
    if (cog != null) params['cog'] = cog;
    if (level != null) params['level'] = level;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('$baseUrl/logs?$queryString');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      // Log file not found
      return {
        'total': 0,
        'logs': [],
        'error': 'Log file not found',
      };
    } else {
      throw Exception('Failed to load logs');
    }
  }

  Future<List<String>> getAvailableCogs() async {
    final response = await _get('$baseUrl/logs/cogs');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['cogs'] ?? []);
    } else {
      throw Exception('Failed to load available cogs');
    }
  }

  // Get active API sessions (Admin/Mod only)
  Future<Map<String, dynamic>> getActiveSessions() async {
    final response = await _get('$baseUrl/admin/active-sessions');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid or expired token');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: Insufficient permissions');
    } else {
      throw Exception(
          'Failed to fetch active sessions: ${response.statusCode}');
    }
  }

  // Ping endpoint to track session (no special permissions required)
  Future<Map<String, dynamic>> ping() async {
    final response = await _get('$baseUrl/ping');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Ping failed: ${response.statusCode}');
    }
  }

  // Get current user's profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _get('$baseUrl/user/profile');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to get user profile: ${response.statusCode}');
    }
  }

  // ===== HAZEHUB ENDPOINTS =====

  Future<Map<String, dynamic>> getLatestMemes({int limit = 10}) async {
    final response = await _get('$baseUrl/hazehub/latest-memes?limit=$limit');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to get latest memes: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getLatestRankups({int limit = 10}) async {
    final response = await _get('$baseUrl/hazehub/latest-rankups?limit=$limit');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to get latest rank-ups: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getLatestLevelups({int limit = 10}) async {
    final response = await _get('$baseUrl/hazehub/latest-levelups?limit=$limit');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to get latest level-ups: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getLeaderboard({int limit = 50}) async {
    final response = await _get('$baseUrl/levels/leaderboard?limit=$limit');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to get leaderboard: ${response.statusCode}');
    }
  }

  // ===== MEME REACTIONS ENDPOINTS =====

  Future<Map<String, dynamic>> upvoteMeme(String messageId) async {
    final response = await _post('$baseUrl/memes/$messageId/upvote');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to upvote meme: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getMemeReactions(String messageId) async {
    final response = await _get('$baseUrl/memes/$messageId/reactions');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to get meme reactions: ${response.statusCode}');
    }
  }

  // ===== COG MANAGEMENT ENDPOINTS =====

  Future<List<Cog>> getCogs() async {
    final response = await _get('$baseUrl/cogs');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final cogs = (data['cogs'] as List<dynamic>?)
              ?.map((cog) => Cog.fromJson(cog as Map<String, dynamic>))
              .toList() ??
          [];
      return cogs;
    } else {
      throw Exception('Failed to load cogs: ${response.body}');
    }
  }

  Future<void> loadCog(String cogName) async {
    final response = await _post('$baseUrl/cogs/$cogName/load');

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to load cog');
    }
  }

  Future<void> unloadCog(String cogName) async {
    final response = await _post('$baseUrl/cogs/$cogName/unload');

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to unload cog');
    }
  }

  Future<void> reloadCog(String cogName) async {
    // Longer timeout for reload operations (especially APIServer which takes ~27s)
    final response = await _post('$baseUrl/cogs/$cogName/reload', timeout: 45);

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to reload cog');
    }
  }

  Future<List<CogLog>> getCogLogs(String cogName, {int limit = 100}) async {
    final response = await _get('$baseUrl/cogs/$cogName/logs?limit=$limit');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final logs = (data['logs'] as List<dynamic>?)
              ?.map((log) => CogLog.fromJson(log))
              .toList() ??
          [];
      return logs;
    } else {
      throw Exception('Failed to load cog logs: ${response.body}');
    }
  }

  // ===== TICKET SYSTEM ENDPOINTS =====

  Future<List<Ticket>> getTickets({String? status}) async {
    String url = '$baseUrl/tickets';
    if (status != null && status.isNotEmpty) {
      url += '?status=$status';
    }

    final response = await _get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final tickets = (data['tickets'] as List<dynamic>?)
              ?.map((ticket) => Ticket.fromJson(ticket as Map<String, dynamic>))
              .toList() ??
          [];
      return tickets;
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to load tickets: ${response.body}');
    }
  }

  /// Get current user's tickets
  Future<List<Ticket>> getMyTickets({String? status}) async {
    String url = '$baseUrl/tickets/my';
    if (status != null && status.isNotEmpty) {
      url += '?status=$status';
    }

    final response = await _get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final tickets = (data['tickets'] as List<dynamic>?)
              ?.map((ticket) => Ticket.fromJson(ticket as Map<String, dynamic>))
              .toList() ??
          [];
      return tickets;
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to load your tickets: ${response.body}');
    }
  }

  /// Create a new ticket (for regular users)
  Future<Map<String, dynamic>> createTicket({
    required String type,
    required String subject,
    required String description,
  }) async {
    final response = await _post(
      '$baseUrl/tickets',
      body: jsonEncode({
        'type': type,
        'subject': subject,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else if (response.statusCode == 429) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Rate limit exceeded');
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Invalid ticket data');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create ticket');
    }
  }

  Future<Ticket> getTicket(String ticketId) async {
    final response = await _get('$baseUrl/tickets/$ticketId');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Ticket.fromJson(data);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else if (response.statusCode == 404) {
      throw Exception('Ticket not found');
    } else {
      throw Exception('Failed to load ticket: ${response.body}');
    }
  }

  Future<void> updateTicket(
      String ticketId, Map<String, dynamic> updates) async {
    final response = await _put(
      '$baseUrl/tickets/$ticketId',
      body: jsonEncode(updates),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update ticket');
    }
  }

  Future<void> deleteTicket(String ticketId) async {
    final response = await _delete('$baseUrl/tickets/$ticketId');

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to delete ticket');
    }
  }

  Future<TicketConfig> getTicketConfig() async {
    final response = await _get('$baseUrl/config/tickets');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TicketConfig.fromJson(data);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to load ticket config: ${response.body}');
    }
  }

  Future<void> updateTicketConfig(TicketConfig config) async {
    final response = await _put(
      '$baseUrl/config/tickets',
      body: jsonEncode(config.toJson()),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update ticket config');
    }
  }

  Future<void> resetTicketConfig() async {
    final response = await _post('$baseUrl/config/tickets/reset');

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to reset ticket config');
    }
  }

  // === Ticket Actions ===

  Future<void> claimTicket(String ticketId, String userId) async {
    final response = await _post(
      '$baseUrl/tickets/$ticketId/claim',
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to claim ticket');
    }
  }

  Future<void> assignTicket(String ticketId, String assignedTo) async {
    final response = await _post(
      '$baseUrl/tickets/$ticketId/assign',
      body: jsonEncode({'assigned_to': assignedTo}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to assign ticket');
    }
  }

  Future<void> closeTicket(String ticketId, {String? closeMessage}) async {
    final response = await _post(
      '$baseUrl/tickets/$ticketId/close',
      body: jsonEncode({'close_message': closeMessage ?? ''}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to close ticket');
    }
  }

  Future<void> reopenTicket(String ticketId) async {
    final response = await _post('$baseUrl/tickets/$ticketId/reopen');

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to reopen ticket');
    }
  }

  // === Ticket Messages ===

  Future<List<dynamic>> getTicketMessages(String ticketId) async {
    final response = await _get('$baseUrl/tickets/$ticketId/messages');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['messages'] as List<dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to fetch messages');
    }
  }

  Future<Map<String, dynamic>> sendTicketMessage(
      String ticketId, String content) async {
    final response = await _post(
      '$baseUrl/tickets/$ticketId/messages',
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['data'] ?? {};
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to send message');
    }
  }

  // === Notification API Methods ===

  Future<bool> registerFCMToken(String fcmToken, String deviceInfo) async {
    try {
      final response = await _post(
        '$baseUrl/notifications/register',
        body: jsonEncode({
          'fcm_token': fcmToken,
          'device_info': deviceInfo,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error registering FCM token: $e');
      return false;
    }
  }

  Future<bool> unregisterFCMToken(String fcmToken) async {
    try {
      final response = await _post(
        '$baseUrl/notifications/unregister',
        body: jsonEncode({
          'fcm_token': fcmToken,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error unregistering FCM token: $e');
      return false;
    }
  }

  Future<Map<String, bool>?> getNotificationSettings() async {
    try {
      final response = await _get('$baseUrl/notifications/settings');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(key, value as bool));
      } else {
        debugPrint(
            '⚠️ Failed to load notification settings: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error loading notification settings: $e');
      return null;
    }
  }

  Future<bool> updateNotificationSettings(Map<String, bool> settings) async {
    try {
      final response = await _put(
        '$baseUrl/notifications/settings',
        body: jsonEncode(settings),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error updating notification settings: $e');
      return false;
    }
  }
}

// Custom exception for token expiration
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);

  @override
  String toString() => message;
}

// Helper function to proxy external images through backend to bypass CORS
// Only applies proxy on Web platform - Mobile can load images directly
String getProxiedImageUrl(String imageUrl) {
  // If URL is already proxied, return as-is
  if (imageUrl.contains('/api/proxy/image')) {
    return imageUrl;
  }

  // Mobile: Return original URL (no CORS restrictions)
  if (!kIsWeb) {
    return imageUrl;
  }

  // Web: Proxy through backend to bypass CORS
  final apiBaseUrl = ApiService._staticBaseUrl.replaceFirst('/api', '');
  final encodedUrl = Uri.encodeComponent(imageUrl);
  return '$apiBaseUrl/api/proxy/image?url=$encodedUrl';
}
