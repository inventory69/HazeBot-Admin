import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'websocket_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();
  bool _isAuthenticated = false;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  WebSocketService get wsService => _wsService;

  AuthService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    if (_token != null) {
      _apiService.setToken(_token!);
      _isAuthenticated = true;

      // Connect WebSocket
      _wsService.connect(_apiService.baseUrl);

      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      _token = response['token'];

      if (_token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);

        _apiService.setToken(_token!);
        _isAuthenticated = true;

        // Connect WebSocket after successful login
        _wsService.connect(_apiService.baseUrl);

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    // Disconnect WebSocket
    _wsService.disconnect();

    // Call backend logout endpoint to remove session
    try {
      await _apiService.logout();
    } catch (e) {
      // Ignore errors - logout locally anyway
      debugPrint('Backend logout failed: $e');
    }

    // Clear local token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    _token = null;
    _isAuthenticated = false;
    _apiService.clearToken();
    notifyListeners();
  }

  ApiService get apiService => _apiService;
}
