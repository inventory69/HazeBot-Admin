import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'websocket_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();
  bool _isAuthenticated = false;
  String? _token;
  bool _isInitialized = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  WebSocketService get wsService => _wsService;
  bool get isInitialized => _isInitialized;

  AuthService(); // Constructor does NOT call _loadToken anymore

  /// Initialize AuthService - must be called before using the service
  /// This loads the token and validates it with the backend
  Future<void> init() async {
    if (_isInitialized) return; // Already initialized
    
    debugPrint('🔐 [AuthService] Initializing...');
    
    await _loadToken();
    _isInitialized = true;
    
    debugPrint('🔐 [AuthService] Initialization complete. Authenticated: $_isAuthenticated');
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    if (_token != null) {
      debugPrint('🔐 [AuthService] Token found in storage');
      
      _apiService.setToken(_token!);
      
      // Validate token with backend
      final isValid = await validateToken();
      
      if (isValid) {
        debugPrint('🔐 [AuthService] Token validation: ✅ VALID');
        _isAuthenticated = true;

        // Connect WebSocket
        _wsService.connect(_apiService.baseUrl);
      } else {
        debugPrint('🔐 [AuthService] Token validation: ❌ INVALID');
        debugPrint('⚠️ Token invalid on app start, clearing token');
        _token = null;
        _isAuthenticated = false;
        _apiService.clearToken();
        await prefs.remove('auth_token');
      }

      notifyListeners();
    } else {
      debugPrint('🔐 [AuthService] No token found in storage');
    }
  }

  /// Validate token with backend
  Future<bool> validateToken() async {
    if (_token == null) return false;
    
    try {
      // Try to make a simple API call to check if token works
      await _apiService.ping();
      return true;
    } catch (e) {
      debugPrint('🔐 [AuthService] Token validation failed: $e');
      return false;
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
