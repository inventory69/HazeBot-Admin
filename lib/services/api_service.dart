import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:5070/api';

  String? _token;

  void setToken(String token) {
    _token = token;
    debugPrint('DEBUG: ApiService token set: ${token.substring(0, 20)}...');
  }

  void clearToken() {
    _token = null;
    debugPrint('DEBUG: ApiService token cleared');
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

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
      debugPrint('DEBUG: ApiService adding Authorization header');
    } else {
      debugPrint('DEBUG: ApiService NO token available');
    }

    return headers;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
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
      final response = await http.get(
        Uri.parse('$baseUrl/config'),
        headers: _headers,
      );

      debugPrint('getConfig response status: ${response.statusCode}');

      if (response.statusCode == 401) {
        // Token expired or invalid
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
    final response = await http.get(
      Uri.parse('$baseUrl/config/general'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load general configuration');
    }
  }

  Future<void> updateGeneralConfig(Map<String, dynamic> config) async {
    final response = await http.put(
      Uri.parse('$baseUrl/config/general'),
      headers: _headers,
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update general configuration');
    }
  }

  Future<void> resetGeneralConfig() async {
    final response = await http.post(
      Uri.parse('$baseUrl/config/general/reset'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reset general configuration');
    }
  }

  Future<Map<String, dynamic>> getChannelsConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/config/channels'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load channels configuration');
    }
  }

  Future<void> updateChannelsConfig(Map<String, dynamic> config) async {
    final response = await http.put(
      Uri.parse('$baseUrl/config/channels'),
      headers: _headers,
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update channels configuration');
    }
  }

  Future<Map<String, dynamic>> getRolesConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/config/roles'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load roles configuration');
    }
  }

  Future<void> updateRolesConfig(Map<String, dynamic> config) async {
    final response = await http.put(
      Uri.parse('$baseUrl/config/roles'),
      headers: _headers,
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update roles configuration');
    }
  }

  Future<Map<String, dynamic>> getMemeConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/config/meme'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load meme configuration');
    }
  }

  Future<void> updateMemeConfig(Map<String, dynamic> config) async {
    final response = await http.put(
      Uri.parse('$baseUrl/config/meme'),
      headers: _headers,
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update meme configuration');
    }
  }

  // Daily Meme Configuration
  Future<Map<String, dynamic>> getDailyMemeConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/daily-meme/config'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load daily meme configuration');
    }
  }

  Future<void> updateDailyMemeConfig(Map<String, dynamic> config) async {
    debugPrint('Sending daily meme config: ${jsonEncode(config)}');
    final response = await http.post(
      Uri.parse('$baseUrl/daily-meme/config'),
      headers: _headers,
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
    final response = await http.post(
      Uri.parse('$baseUrl/daily-meme/config/reset'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reset daily meme configuration');
    }
  }

  Future<Map<String, dynamic>> getRocketLeagueConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/config/rocket_league'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load Rocket League configuration');
    }
  }

  Future<void> updateRocketLeagueConfig(Map<String, dynamic> config) async {
    final response = await http.put(
      Uri.parse('$baseUrl/config/rocket_league'),
      headers: _headers,
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update Rocket League configuration');
    }
  }

  Future<void> resetRocketLeagueConfig() async {
    final response = await http.post(
      Uri.parse('$baseUrl/config/rocket_league/reset'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reset Rocket League configuration');
    }
  }

  // Rocket League Account Management
  Future<List<Map<String, dynamic>>> getRocketLeagueAccounts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/rocket-league/accounts'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load Rocket League accounts');
    }
  }

  Future<void> deleteRocketLeagueAccount(String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/rocket-league/accounts/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete Rocket League account');
    }
  }

  Future<Map<String, dynamic>> triggerRankCheck() async {
    final response = await http.post(
      Uri.parse('$baseUrl/rocket-league/check-ranks'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to trigger rank check: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getRocketLeagueStats(
      String platform, String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rocket-league/stats/$platform/$username'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get Rocket League stats: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUserRLAccount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/rocket-league/account'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user RL account: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getRLStats(
      String platform, String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rocket-league/stats/$platform/$username'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to fetch RL stats');
    }
  }

  Future<Map<String, dynamic>> linkUserRLAccount(
      String platform, String username) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/rocket-league/link'),
      headers: _headers,
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
    final response = await http.delete(
      Uri.parse('$baseUrl/user/rocket-league/unlink'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to unlink RL account: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> postUserRLStats() async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/rocket-league/post-stats'),
      headers: _headers,
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
    final response = await http.put(
      Uri.parse('$baseUrl/user/preferences'),
      headers: _headers,
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
    final response = await http.get(
      Uri.parse('$baseUrl/gaming/members'),
      headers: _headers,
    );

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
    final response = await http.post(
      Uri.parse('$baseUrl/gaming/request'),
      headers: _headers,
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
    final response = await http.get(
      Uri.parse('$baseUrl/config/welcome'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load welcome configuration');
    }
  }

  Future<void> updateWelcomeConfig(Map<String, dynamic> config) async {
    final response = await http.put(
      Uri.parse('$baseUrl/config/welcome'),
      headers: _headers,
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update welcome configuration');
    }
  }

  Future<Map<String, dynamic>> resetWelcomeConfig() async {
    final response = await http.post(
      Uri.parse('$baseUrl/config/welcome/reset'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to reset welcome configuration');
    }
  }

  Future<Map<String, dynamic>> getWelcomeTextsConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/config/welcome_texts'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load welcome texts configuration');
    }
  }

  Future<void> updateWelcomeTextsConfig(Map<String, dynamic> config) async {
    final response = await http.put(
      Uri.parse('$baseUrl/config/welcome_texts'),
      headers: _headers,
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update welcome texts configuration');
    }
  }

  Future<Map<String, dynamic>> resetWelcomeTextsConfig() async {
    final response = await http.post(
      Uri.parse('$baseUrl/config/welcome_texts/reset'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to reset welcome texts configuration');
    }
  }

  Future<Map<String, dynamic>> getRocketLeagueTextsConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/config/rocket_league_texts'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load Rocket League texts configuration');
    }
  }

  Future<void> updateRocketLeagueTextsConfig(
      Map<String, dynamic> config) async {
    final response = await http.put(
      Uri.parse('$baseUrl/config/rocket_league_texts'),
      headers: _headers,
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update Rocket League texts configuration');
    }
  }

  Future<Map<String, dynamic>> resetRocketLeagueTextsConfig() async {
    final response = await http.post(
      Uri.parse('$baseUrl/config/rocket_league_texts/reset'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to reset Rocket League texts configuration');
    }
  }

  Future<Map<String, dynamic>> getServerGuideConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/config/server_guide'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load server guide configuration');
    }
  }

  Future<void> updateServerGuideConfig(Map<String, dynamic> config) async {
    final response = await http.put(
      Uri.parse('$baseUrl/config/server_guide'),
      headers: _headers,
      body: jsonEncode(config),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update server guide configuration');
    }
  }

  // Test functions
  Future<Map<String, dynamic>> getMemeSources() async {
    final response = await http.get(
      Uri.parse('$baseUrl/meme-sources'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get meme sources: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getMemeFromSource(String source) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/test/meme-from-source?source=${Uri.encodeComponent(source)}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get meme from source: ${response.body}');
    }
  }

  // ===== MEME GENERATOR ENDPOINTS =====

  Future<Map<String, dynamic>> getMemeTemplates() async {
    final response = await http.get(
      Uri.parse('$baseUrl/meme-generator/templates'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get meme templates: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> refreshMemeTemplates() async {
    final response = await http.post(
      Uri.parse('$baseUrl/meme-generator/templates/refresh'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to refresh meme templates: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> generateMeme(
      String templateId, List<String> texts) async {
    final response = await http.post(
      Uri.parse('$baseUrl/meme-generator/generate'),
      headers: _headers,
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
    final response = await http.post(
      Uri.parse('$baseUrl/meme-generator/post-to-discord'),
      headers: _headers,
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
    final response = await http.get(
      Uri.parse('$baseUrl/test/random-meme'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get random meme: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> testDailyMeme() async {
    final response = await http.post(
      Uri.parse('$baseUrl/test/daily-meme'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to test daily meme: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> sendMemeToDiscord(
      Map<String, dynamic> meme) async {
    final response = await http.post(
      Uri.parse('$baseUrl/test/send-meme'),
      headers: _headers,
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
    final response = await http.get(
      Uri.parse('$baseUrl/guild/channels'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load guild channels');
    }
  }

  Future<List<Map<String, dynamic>>> getGuildRoles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/guild/roles'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load guild roles');
    }
  }

  Future<void> resetChannelsConfig() async {
    final response = await http.post(
      Uri.parse('$baseUrl/config/channels/reset'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reset channels configuration');
    }
  }

  Future<void> resetRolesConfig() async {
    final response = await http.post(
      Uri.parse('$baseUrl/config/roles/reset'),
      headers: _headers,
    );

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

    final response = await http.get(
      Uri.parse('$baseUrl/logs?$queryString'),
      headers: _headers,
    );

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
    final response = await http.get(
      Uri.parse('$baseUrl/logs/cogs'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['cogs'] ?? []);
    } else {
      throw Exception('Failed to load available cogs');
    }
  }

  // Get active API sessions (Admin/Mod only)
  Future<Map<String, dynamic>> getActiveSessions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/active-sessions'),
      headers: _headers,
    );

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
    final response = await http.get(
      Uri.parse('$baseUrl/ping'),
      headers: _headers,
    );

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
    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: _headers,
    );

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
    final response = await http.get(
      Uri.parse('$baseUrl/hazehub/latest-memes?limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to get latest memes: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getLatestRankups({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/hazehub/latest-rankups?limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to get latest rank-ups: ${response.statusCode}');
    }
  }

  // ===== MEME REACTIONS ENDPOINTS =====

  Future<Map<String, dynamic>> upvoteMeme(String messageId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/memes/$messageId/upvote'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to upvote meme: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getMemeReactions(String messageId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/memes/$messageId/reactions'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException('Token has expired or is invalid');
    } else {
      throw Exception('Failed to get meme reactions: ${response.statusCode}');
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
String getProxiedImageUrl(String imageUrl) {
  // If URL is already proxied, return as-is
  if (imageUrl.contains('/api/proxy/image')) {
    return imageUrl;
  }

  final apiBaseUrl = ApiService.baseUrl.replaceFirst('/api', '');
  final encodedUrl = Uri.encodeComponent(imageUrl);
  return '$apiBaseUrl/api/proxy/image?url=$encodedUrl';
}
