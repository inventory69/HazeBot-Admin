import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📱 Background message received: ${message.messageId}');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _firebaseMessaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  
  bool _isInitialized = false;
  bool _permissionGranted = false;
  String? _fcmToken;
  
  // Callback for notification tap
  Function(Map<String, dynamic>)? onNotificationTap;
  
  bool get isInitialized => _isInitialized;
  bool get hasPermission => _permissionGranted;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase (without requesting permission)
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('🔔 Notification service already initialized');
      return true;
    }

    try {
      // Check if running on web - Firebase Messaging doesn't work on web without config
      if (kIsWeb) {
        debugPrint('ℹ️ Running on Web - Firebase Messaging not supported');
        _isInitialized = true; // Mark as initialized to prevent retries
        return false;
      }

      // Initialize Firebase for mobile
      await Firebase.initializeApp();
      debugPrint('✅ Firebase initialized');

      // Initialize Firebase Messaging instance
      _firebaseMessaging = FirebaseMessaging.instance;
      _localNotifications = FlutterLocalNotificationsPlugin();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Check current permission status (without requesting)
      NotificationSettings settings = await _firebaseMessaging!.getNotificationSettings();
      _permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                          settings.authorizationStatus == AuthorizationStatus.provisional;
      
      if (_permissionGranted) {
        debugPrint('✅ Notification permission already granted');
        await _setupMessaging();
      } else {
        debugPrint('ℹ️ Notification permission not yet granted (will request later)');
      }

      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('� App opened from notification: ${initialMessage.messageId}');
        _handleNotificationTap(initialMessage);
      }

      _isInitialized = true;
      debugPrint('✅ Notification service initialized successfully');
      return true;

    } catch (e) {
      debugPrint('❌ Failed to initialize notification service: $e');
      return false;
    }
  }

  /// Request permission and setup messaging (call when user needs notifications)
  Future<bool> requestPermissionAndRegister() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Service not initialized, initializing now...');
      await initialize();
    }

    if (_firebaseMessaging == null) {
      debugPrint('⚠️ Firebase Messaging not available (Web or init failed)');
      return false;
    }

    if (_permissionGranted) {
      debugPrint('ℹ️ Permission already granted');
      return true;
    }

    try {
      debugPrint('📱 Requesting notification permission...');
      
      // Request permission
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!_permissionGranted) {
        debugPrint('❌ Notification permission denied by user');
        return false;
      }

      debugPrint('✅ Notification permission granted: ${settings.authorizationStatus}');

      // Setup messaging with token
      await _setupMessaging();
      
      return true;

    } catch (e) {
      debugPrint('❌ Failed to request permission: $e');
      return false;
    }
  }

  /// Setup FCM messaging (token, listeners)
  Future<void> _setupMessaging() async {
    if (_firebaseMessaging == null) return;
    
    // Get FCM token
    _fcmToken = await _firebaseMessaging!.getToken();
    debugPrint('🔑 FCM Token: $_fcmToken');

    // Listen to token refresh
    _firebaseMessaging!.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      _fcmToken = newToken;
      // Re-register with backend
      _registerTokenWithBackend(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'hazebot_tickets',
      'HazeBot Tickets',
      description: 'Notifications for ticket updates and messages',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications!
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    debugPrint('✅ Local notifications initialized');
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message received: ${message.messageId}');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    // Display local notification when app is in foreground
    _showLocalNotification(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'hazebot_tickets',
      'HazeBot Tickets',
      channelDescription: 'Notifications for ticket updates and messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications!.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification tap (from background/terminated state)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    
    if (onNotificationTap != null) {
      onNotificationTap!(message.data);
    }
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('👆 Local notification tapped: ${response.payload}');
    
    if (response.payload != null && onNotificationTap != null) {
      try {
        final data = jsonDecode(response.payload!);
        onNotificationTap!(data);
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Register FCM token with backend
  Future<bool> registerWithBackend(ApiService apiService) async {
    if (_fcmToken == null) {
      debugPrint('⚠️ No FCM token available');
      return false;
    }

    return _registerTokenWithBackend(_fcmToken!, apiService: apiService);
  }

  Future<bool> _registerTokenWithBackend(String token, {ApiService? apiService}) async {
    try {
      final api = apiService ?? ApiService();
      
      final success = await api.registerFCMToken(
        token,
        'Flutter ${defaultTargetPlatform.name}',
      );

      if (success) {
        debugPrint('✅ FCM token registered with backend');
      } else {
        debugPrint('⚠️ Failed to register FCM token');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error registering FCM token: $e');
      return false;
    }
  }

  /// Unregister FCM token from backend
  Future<bool> unregisterFromBackend(ApiService apiService) async {
    if (_fcmToken == null) {
      debugPrint('⚠️ No FCM token available');
      return false;
    }

    try {
      final success = await apiService.unregisterFCMToken(_fcmToken!);
      
      if (success) {
        debugPrint('✅ FCM token unregistered from backend');
      } else {
        debugPrint('⚠️ Failed to unregister FCM token');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error unregistering FCM token: $e');
      return false;
    }
  }

  /// Delete FCM token locally (for logout)
  Future<void> deleteToken() async {
    if (_firebaseMessaging == null) return;
    
    try {
      await _firebaseMessaging!.deleteToken();
      _fcmToken = null;
      debugPrint('✅ FCM token deleted locally');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }

  /// Get notification settings from backend
  Future<Map<String, bool>?> getNotificationSettings(ApiService apiService) async {
    try {
      return await apiService.getNotificationSettings();
    } catch (e) {
      debugPrint('❌ Error getting notification settings: $e');
      return null;
    }
  }

  /// Update notification settings on backend
  Future<bool> updateNotificationSettings(
    ApiService apiService,
    Map<String, bool> settings,
  ) async {
    try {
      return await apiService.updateNotificationSettings(settings);
    } catch (e) {
      debugPrint('❌ Error updating notification settings: $e');
      return false;
    }
  }
}
