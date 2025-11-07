import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:5070/api';

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
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
}

// Custom exception for token expiration
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);

  @override
  String toString() => message;
}
