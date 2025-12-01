import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// ✅ Message cache for InboxStyle notifications (persists across background handler calls)
final Map<String, List<Map<String, String>>> _ticketMessages = {};

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📱 Background message received: ${message.messageId}');
  debugPrint('   Title: ${message.data['title']}');
  debugPrint('   Body: ${message.data['body']}');
  debugPrint('   Data: ${message.data}');

  // ✅ FIX: Show single notification per ticket with InboxStyle (Discord/Telegram style)
  try {
    // Create local notifications plugin instance (background isolate)
    final localNotifications = FlutterLocalNotificationsPlugin();

    // Initialize if needed
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await localNotifications.initialize(initSettings);

    // Create notification channel
    const androidChannel = AndroidNotificationChannel(
      'hazebot_tickets',
      'HazeBot Tickets',
      description: 'Notifications for ticket updates and messages',
      importance: Importance.high,
      playSound: true,
    );
    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Extract notification data from data payload (data-only message)
    final title = message.data['title'] as String?;
    final body = message.data['body'] as String?;

    if (title == null || body == null) {
      debugPrint('⚠️ No title/body in data payload, skipping');
      return;
    }

    final ticketId = message.data['ticket_id'] as String?;
    final ticketNum = message.data['ticket_num'] as String?;

    if (ticketId == null) {
      debugPrint('⚠️ No ticket_id in message, skipping');
      return;
    }

    // ✅ Add message to cache (limit to last 10 messages)
    _ticketMessages.putIfAbsent(ticketId, () => []);
    _ticketMessages[ticketId]!.add({
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 10 messages
    if (_ticketMessages[ticketId]!.length > 10) {
      _ticketMessages[ticketId]!.removeAt(0);
    }

    final messages = _ticketMessages[ticketId]!;
    final count = messages.length;
    final ticketLabel = ticketNum != null ? '#$ticketNum' : ticketId;

    // ✅ Create InboxStyle lines (show actual message content)
    final lines = messages.map((msg) => msg['body']!).toList();

    // ✅ Use constant ID per ticket (updates existing notification)
    final notificationId = ticketId.hashCode.abs() & 0x7FFFFFFF;

    final androidDetails = AndroidNotificationDetails(
      'hazebot_tickets',
      'HazeBot Tickets',
      channelDescription: 'Notifications for ticket updates and messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@drawable/ic_notification',
      styleInformation: InboxStyleInformation(
        lines,
        contentTitle: 'Ticket $ticketLabel',
        summaryText: '$count new ${count == 1 ? "message" : "messages"}',
      ),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_read',
          'Mark as Read',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'reply',
          'Reply',
          showsUserInterface: true,
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              label: 'Reply...',
            ),
          ],
        ),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: ticketId,
    );

    await localNotifications.show(
      notificationId,
      'Ticket $ticketLabel',
      '$count new ${count == 1 ? "message" : "messages"}',
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: jsonEncode(message.data),
    );

    debugPrint('✅ Background notification shown with grouping');
  } catch (e, stackTrace) {
    debugPrint('❌ Error showing background notification: $e');
    debugPrint('Stack trace: $stackTrace');
  }
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

  // ✅ Message cache for InboxStyle notifications (foreground)
  final Map<String, List<Map<String, String>>> _foregroundTicketMessages = {};

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
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Check current permission status (without requesting)
      NotificationSettings settings =
          await _firebaseMessaging!.getNotificationSettings();
      _permissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (_permissionGranted) {
        debugPrint('✅ Notification permission already granted');
        await _setupMessaging();

        // ✅ FIX: Auto re-register token on app start (in case backend lost it)
        await _autoReRegisterTokenOnStartup();
      } else {
        debugPrint(
            'ℹ️ Notification permission not yet granted (will request later)');
      }

      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage =
          await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
            '� App opened from notification: ${initialMessage.messageId}');
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
      NotificationSettings settings =
          await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _permissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!_permissionGranted) {
        debugPrint('❌ Notification permission denied by user');
        return false;
      }

      debugPrint(
          '✅ Notification permission granted: ${settings.authorizationStatus}');

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

    // ✅ FIX: Save token to SharedPreferences for persistence
    if (_fcmToken != null) {
      await _saveTokenToPrefs(_fcmToken!);
    }

    // Listen to token refresh
    _firebaseMessaging!.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      _fcmToken = newToken;
      // Save new token
      _saveTokenToPrefs(newToken);
      // Re-register with backend
      _registerTokenWithBackend(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Save FCM token to SharedPreferences
  Future<void> _saveTokenToPrefs(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      debugPrint('💾 Saved FCM token to SharedPreferences');
    } catch (e) {
      debugPrint('❌ Error saving FCM token to prefs: $e');
    }
  }

  /// Load FCM token from SharedPreferences
  Future<String?> _loadTokenFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcm_token');
      if (token != null) {
        debugPrint('📂 Loaded FCM token from SharedPreferences');
      }
      return token;
    } catch (e) {
      debugPrint('❌ Error loading FCM token from prefs: $e');
      return null;
    }
  }

  /// Auto re-register token on app startup (prevents token loss)
  Future<void> _autoReRegisterTokenOnStartup() async {
    try {
      // Check if we have a saved token and current token
      final savedToken = await _loadTokenFromPrefs();

      if (_fcmToken == null || savedToken == null) {
        debugPrint('⚠️ No token available for auto re-registration');
        return;
      }

      // ✅ FIX: Always re-register on app start (idempotent, prevents token loss)
      // Backend handles duplicate registrations gracefully
      debugPrint(
          '🔄 Auto re-registering FCM token on app start (prevents backend token loss)');
      await _registerTokenWithBackend(_fcmToken!);

      // Update last registration time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'fcm_token_last_registered', DateTime.now().millisecondsSinceEpoch);
      debugPrint('✅ Token re-registered successfully');
    } catch (e) {
      debugPrint('❌ Error in auto re-registration: $e');
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    debugPrint('✅ Local notifications initialized');
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message received: ${message.messageId}');
    debugPrint('   Title: ${message.data['title']}');
    debugPrint('   Body: ${message.data['body']}');
    debugPrint('   Data: ${message.data}');

    // Display local notification when app is in foreground
    showNotificationFromMessage(message);
  }

  /// Show single notification per ticket with InboxStyle (Discord/Telegram style)
  Future<void> showNotificationFromMessage(RemoteMessage message) async {
    // ✅ FIX: Read title/body from data payload (data-only message)
    final title = message.data['title'] as String?;
    final body = message.data['body'] as String?;

    if (title == null || body == null) {
      debugPrint('⚠️ No title/body in data payload, skipping');
      return;
    }

    final ticketId = message.data['ticket_id'] as String?;
    final ticketNum = message.data['ticket_num'] as String?;

    if (ticketId == null) {
      debugPrint('⚠️ No ticket_id in message, skipping');
      return;
    }

    // ✅ Add message to cache (limit to last 10 messages)
    _foregroundTicketMessages.putIfAbsent(ticketId, () => []);
    _foregroundTicketMessages[ticketId]!.add({
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 10 messages
    if (_foregroundTicketMessages[ticketId]!.length > 10) {
      _foregroundTicketMessages[ticketId]!.removeAt(0);
    }

    final messages = _foregroundTicketMessages[ticketId]!;
    final count = messages.length;
    final ticketLabel = ticketNum != null ? '#$ticketNum' : ticketId;

    // ✅ Create InboxStyle lines (show actual message content)
    final lines = messages.map((msg) => msg['body']!).toList();

    // ✅ Use constant ID per ticket (updates existing notification)
    final notificationId = ticketId.hashCode.abs() & 0x7FFFFFFF;

    final androidDetails = AndroidNotificationDetails(
      'hazebot_tickets',
      'HazeBot Tickets',
      channelDescription: 'Notifications for ticket updates and messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@drawable/ic_notification',
      styleInformation: InboxStyleInformation(
        lines,
        contentTitle: 'Ticket $ticketLabel',
        summaryText: '$count new ${count == 1 ? "message" : "messages"}',
      ),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_read',
          'Mark as Read',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'reply',
          'Reply',
          showsUserInterface: true,
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              label: 'Reply...',
            ),
          ],
        ),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: ticketId,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications!.show(
      notificationId,
      'Ticket $ticketLabel',
      '$count new ${count == 1 ? "message" : "messages"}',
      details,
      payload: jsonEncode(message.data),
    );

    debugPrint('✅ Updated notification for ticket $ticketId ($count messages)');
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

    // Handle "Mark as Read" action
    if (response.actionId == 'mark_read') {
      debugPrint('✅ Marked notification as read (dismissed)');
      // Notification already dismissed by cancelNotification: true
      return;
    }

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

  Future<bool> _registerTokenWithBackend(String token,
      {ApiService? apiService}) async {
    try {
      final api = apiService ?? ApiService();

      final success = await api.registerFCMToken(
        token,
        'Flutter ${defaultTargetPlatform.name}',
      );

      if (success) {
        debugPrint('✅ FCM token registered with backend');

        // Save registration timestamp
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
            'fcm_token_last_registered', DateTime.now().millisecondsSinceEpoch);
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
  Future<Map<String, bool>?> getNotificationSettings(
      ApiService apiService) async {
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

  /// Dismiss notification for a specific ticket (when user opens the ticket)
  Future<void> dismissTicketNotifications(String ticketId) async {
    if (_localNotifications == null) return;

    try {
      // Cancel the single InboxStyle notification for this ticket
      final notificationId = ticketId.hashCode.abs() & 0x7FFFFFFF;
      await _localNotifications!.cancel(notificationId);
      debugPrint('✅ Dismissed notification for ticket $ticketId');

      // Clear message cache
      _foregroundTicketMessages.remove(ticketId);
    } catch (e) {
      debugPrint('❌ Error dismissing notification for ticket $ticketId: $e');
    }
  }

  /// Dismiss all active notifications
  Future<void> dismissAllNotifications() async {
    if (_localNotifications == null) return;

    try {
      await _localNotifications!.cancelAll();
      _foregroundTicketMessages.clear();
      debugPrint('✅ Dismissed all notifications');
    } catch (e) {
      debugPrint('❌ Error dismissing all notifications: $e');
    }
  }
}
