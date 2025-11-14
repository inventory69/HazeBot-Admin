import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'api_service.dart';

class DiscordAuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  String? _token;
  Map<String, dynamic>? _userInfo;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  Map<String, dynamic>? get userInfo => _userInfo;
  String? get role => _userInfo?['role'];
  List<String> get permissions =>
      List<String>.from(_userInfo?['permissions'] ?? []);

  DiscordAuthService() {
    debugPrint('DEBUG: DiscordAuthService CONSTRUCTOR called');
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    if (_token != null) {
      debugPrint('DEBUG: DiscordAuthService loading token from storage');
      _apiService.setToken(_token!);

      // Token will be automatically checked and refreshed by ApiService before each request
      try {
        final userData = await _apiService.getCurrentUser();
        debugPrint('DEBUG: DiscordAuthService got user data: $userData');
        debugPrint('DEBUG: Auth type: ${userData['auth_type']}');
        debugPrint('DEBUG: Avatar URL from /auth/me: ${userData['avatar_url']}');

        // Only authenticate with Discord if auth_type is "discord" AND has discord_id
        if (userData['auth_type'] == 'discord' &&
            userData['discord_id'] != null) {
          debugPrint('DEBUG: Setting Discord auth as authenticated');
          _isAuthenticated = true;
          _userInfo = userData;
          notifyListeners();
        } else {
          debugPrint(
              'DEBUG: Legacy auth detected (auth_type: ${userData['auth_type']}), NOT setting Discord auth');
          // Clear any stale data
          _isAuthenticated = false;
          _userInfo = null;
        }
      } catch (e) {
        debugPrint('DEBUG: Failed to load user info in DiscordAuthService: $e');
        // Don't logout - might be a network error
      }
    }
  }

  Future<String?> getDiscordAuthUrl() async {
    try {
      final response = await _apiService.getDiscordAuthUrl();
      String authUrl = response['auth_url'];

      // Add platform=mobile parameter for mobile apps (Android/iOS)
      if (!kIsWeb) {
        final uri = Uri.parse(authUrl);
        final newUri = uri.replace(
          queryParameters: {
            ...uri.queryParameters,
            'state':
                'mobile', // Use state parameter to identify mobile platform
          },
        );
        authUrl = newUri.toString();
        debugPrint('DEBUG: Modified auth URL for mobile: $authUrl');
      }

      return authUrl;
    } catch (e) {
      debugPrint('Failed to get Discord auth URL: $e');
      return null;
    }
  }

  Future<bool> initiateDiscordLogin() async {
    try {
      final authUrl = await getDiscordAuthUrl();
      if (authUrl == null) {
        debugPrint('Failed to get auth URL');
        return false;
      }

      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        debugPrint('Could not launch $authUrl');
        return false;
      }
    } catch (e) {
      debugPrint('Failed to initiate Discord login: $e');
      return false;
    }
  }

  Future<bool> handleOAuthCallback(String code) async {
    try {
      debugPrint('DEBUG: Exchanging code: $code');
      final response = await _apiService.exchangeDiscordCode(code);
      debugPrint('DEBUG: Exchange response: $response');

      _token = response['token'];

      // Set token and get current user to get avatar_url
      _apiService.setToken(response['token']);
      final userData = await _apiService.getCurrentUser();

      _userInfo = {
        'username': response['user'],
        'role': response['role'],
        'role_name': userData['role_name'],
        'permissions': response['permissions'],
        'discord_user': response['discord_user'],
        'discord_id': userData['discord_id'],
        'avatar_url': userData['avatar_url'],
      };

      if (_token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);

        _apiService.setToken(_token!);
        _isAuthenticated = true;
        notifyListeners();
        debugPrint('DEBUG: OAuth login successful');
        return true;
      }
      debugPrint('DEBUG: No token received');
      return false;
    } catch (e) {
      debugPrint('Failed to handle OAuth callback: $e');
      return false;
    }
  }

  Future<bool> handleTokenFromUrl(String token) async {
    return await setTokenFromDeepLink(token);
  }

  /// Set token from deep link (Android OAuth callback)
  Future<bool> setTokenFromDeepLink(String token) async {
    try {
      debugPrint('🔐 setTokenFromDeepLink START');
      debugPrint('🔐 Token length: ${token.length}');
      debugPrint('🔐 Token preview: ${token.substring(0, 20)}...');

      _token = token;

      // Save token
      debugPrint('🔐 Saving token to SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      debugPrint('✅ Token saved to SharedPreferences');

      // CRITICAL: Set token in singleton ApiService
      final apiInstance = ApiService();
      debugPrint('🔐 ApiService instance hashCode: ${apiInstance.hashCode}');
      apiInstance.setToken(token);
      debugPrint('✅ Token set in ApiService');

      // Get user info from the token
      debugPrint('🔐 Calling getCurrentUser API...');
      final userData = await apiInstance.getCurrentUser();
      debugPrint('✅ Got user data: $userData');
      debugPrint('🔐 Avatar URL: ${userData['avatar_url']}');

      _userInfo = {
        'user': userData['user'],
        'username': userData['user'],
        'discord_id': userData['discord_id'],
        'role': userData['role'],
        'role_name': userData['role_name'],
        'permissions': userData['permissions'],
        'auth_type': userData['auth_type'],
        'avatar_url': userData['avatar_url'],
      };

      debugPrint('🔐 Setting _isAuthenticated = true');
      _isAuthenticated = true;

      debugPrint('🔐 Calling notifyListeners()...');
      notifyListeners();

      // Small delay to ensure state propagates before navigation
      await Future.delayed(const Duration(milliseconds: 100));

      debugPrint('✅ Token login successful - user authenticated!');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to handle token from deep link: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  bool hasPermission(String permission) {
    if (permissions.contains('all')) {
      return true;
    }
    return permissions.contains(permission);
  }

  Future<void> logout() async {
    _token = null;
    _userInfo = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    _apiService.setToken('');
    notifyListeners();
  }
}
