import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, kReleaseMode;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/discord_auth_service.dart';
import 'services/permission_service.dart';
import 'services/config_service.dart';
import 'services/theme_service.dart';
import 'services/deep_link_service.dart';
import 'services/notification_service.dart';
import 'services/error_reporter.dart';
import 'providers/data_cache_provider.dart';
import 'providers/community_posts_provider.dart';
import 'utils/app_config.dart';
import 'utils/notification_navigation.dart';

// Global navigation key for push notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize error reporter (loads device info)
  await ErrorReporter().initialize();

  // ✅ FIX 2: Initialize AuthService BEFORE app starts to prevent race conditions
  final authService = AuthService();
  await authService.init(); // Wait for token to load before running app
  debugPrint('✅ AuthService initialized');

  // ✅ ERROR REPORTING: Global error handler for uncaught Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log locally (always)
    ErrorReporter().error(
      details.exception.toString(),
      context: {
        'stackTrace': details.stack.toString(),
        'library': details.library ?? 'unknown',
      },
    );

    // In debug mode: print to console
    if (kDebugMode) {
      FlutterError.presentError(details);
    }

    // In release mode: check if auto-reporting is enabled
    if (kReleaseMode) {
      _checkAndSendError(details.exception, details.stack);
    }
  };

  // ✅ ERROR REPORTING: Global error handler for async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorReporter().error(
      error.toString(),
      context: {'stackTrace': stack.toString()},
    );

    if (kReleaseMode) {
      _checkAndSendError(error, stack);
    }

    return true; // Handled
  };

  // Initialize Firebase & Notifications (graceful - continues even if Firebase not configured)
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Set up notification tap handler
    notificationService.onNotificationTap = (data) {
      debugPrint('📱 Notification tapped with data: $data');
      handleNotificationTap(navigatorKey.currentContext, data);
    };

    debugPrint('✅ Notifications initialized');
  } catch (e) {
    debugPrint(
        'ℹ️ Notifications not available (Web or Firebase not configured): $e');
    // Continue without notifications - app still works
  }

  runApp(HazeBotAdminApp(authService: authService));
}

/// Check if auto-reporting is enabled and send error silently
Future<void> _checkAndSendError(dynamic error, StackTrace? stack) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final autoSendEnabled = prefs.getBool('auto_send_error_reports') ?? false;

    if (autoSendEnabled) {
      await ErrorReporter().sendErrorSilently(error, stackTrace: stack);
    }
  } catch (e) {
    debugPrint('Failed to auto-send error: $e');
  }
}

class HazeBotAdminApp extends StatefulWidget {
  final AuthService authService;

  const HazeBotAdminApp({super.key, required this.authService});

  @override
  State<HazeBotAdminApp> createState() => _HazeBotAdminAppState();
}

class _HazeBotAdminAppState extends State<HazeBotAdminApp>
    with WidgetsBindingObserver {
  final DeepLinkService _deepLinkService = DeepLinkService();
  String? _pendingToken; // Store token until Provider is ready

  @override
  void initState() {
    super.initState();
    _initDeepLinks();

    // ✅ Monitor app lifecycle for WebSocket management
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Get WebSocket service from DiscordAuthService
    final context = navigatorKey.currentContext;
    if (context != null) {
      try {
        final discordAuthService =
            Provider.of<DiscordAuthService>(context, listen: false);

        if (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) {
          // Web should NOT disconnect on inactive (tab switch)
          // Only mobile disconnects when app goes to background
          if (!kIsWeb) {
            discordAuthService.wsService.disconnect();
          }
        } else if (state == AppLifecycleState.resumed) {
          // Reconnect if authenticated
          if (discordAuthService.isAuthenticated) {
            final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
            if (baseUrl.isNotEmpty) {
              discordAuthService.wsService.connect(baseUrl);
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error managing WebSocket lifecycle: $e');
      }
    }
  }

  Future<void> _initDeepLinks() async {
    await _deepLinkService.init(onDeepLink: (uri) {
      debugPrint('🔗 DEEP LINK RECEIVED: $uri');
      debugPrint('🔗 Scheme: ${uri.scheme}, Host: ${uri.host}');
      debugPrint('🔗 Query params: ${uri.queryParameters}');

      // Handle OAuth callback: hazebot://oauth?token=...
      if (uri.scheme == 'hazebot' && uri.host == 'oauth') {
        debugPrint('✅ Deep link matches OAuth pattern');
        final token = uri.queryParameters['token'];

        if (token != null) {
          debugPrint(
              '✅ Token found in deep link: ${token.substring(0, 20)}...');

          // Store token to be processed after build
          setState(() {
            _pendingToken = token;
          });
          debugPrint('✅ Token stored, will be processed after build');
        } else {
          debugPrint('❌ No token in deep link query parameters');
        }
      } else {
        debugPrint(
            '❌ Deep link does not match OAuth pattern (expected hazebot://oauth)');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
            value: widget.authService), // Use pre-initialized instance
        ChangeNotifierProvider(create: (_) => DiscordAuthService()),
        ChangeNotifierProvider(create: (_) => PermissionService()),
        ChangeNotifierProvider(create: (_) => ConfigService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => DataCacheProvider()),
        ChangeNotifierProvider(create: (_) => CommunityPostsProvider()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              // Use system color scheme if available AND enabled in settings
              ColorScheme lightColorScheme;
              ColorScheme darkColorScheme;

              if (themeService.useDynamicColor &&
                  lightDynamic != null &&
                  darkDynamic != null) {
                // Use dynamic colors from system (Material You / Android 16 Monet)
                // Apply harmonization for color consistency
                lightColorScheme = lightDynamic.harmonized();
                darkColorScheme = darkDynamic.harmonized();
              } else {
                // Fallback to custom pink theme
                lightColorScheme = ColorScheme.fromSeed(
                  seedColor: const Color(0xFFAD1457),
                  brightness: Brightness.light,
                );
                darkColorScheme = ColorScheme.fromSeed(
                  seedColor: const Color(0xFFAD1457),
                  brightness: Brightness.dark,
                );
              }

              return MaterialApp(
                navigatorKey: navigatorKey,
                title: AppConfig.appName,
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  colorScheme: lightColorScheme,
                  useMaterial3: true,
                  appBarTheme: const AppBarTheme(
                    centerTitle: true,
                    elevation: 2,
                  ),
                  cardTheme: CardThemeData(
                    elevation: 2, // Use light elevation so surfaceTint shows
                    // Don't set a fixed color here so Material can apply
                    // the Material 3 surface tint to indicate tonal elevation
                    // (e.g. surfaceContainer variants). The default color will
                    // be surface and the tone will be applied automatically.
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  scaffoldBackgroundColor: lightColorScheme.surface,
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: lightColorScheme.surfaceContainerHighest,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lightColorScheme.primary,
                      foregroundColor: lightColorScheme.onPrimary,
                    ),
                  ),
                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: lightColorScheme.primary,
                    ),
                  ),
                ),
                darkTheme: ThemeData(
                  colorScheme: darkColorScheme,
                  useMaterial3: true,
                  appBarTheme: const AppBarTheme(
                    centerTitle: true,
                    elevation: 2,
                  ),
                  cardTheme: CardThemeData(
                    elevation: 2, // Let tonal elevation be visible in dark mode
                    // Avoid forcing a color so the system's surface tint
                    // appears with the elevation.
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  scaffoldBackgroundColor: darkColorScheme.surface,
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: darkColorScheme.surfaceContainerHighest,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkColorScheme.primary,
                      foregroundColor: darkColorScheme.onPrimary,
                    ),
                  ),
                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkColorScheme.primary,
                    ),
                  ),
                ),
                themeMode: ThemeMode.system, // Follow system theme
                home: Consumer2<AuthService, DiscordAuthService>(
                  builder: (context, authService, discordAuthService, _) {
                    // Process pending token from deep link
                    if (_pendingToken != null) {
                      final token = _pendingToken!;
                      _pendingToken = null; // Clear it immediately

                      debugPrint(
                          '🔐 Processing pending token from deep link...');
                      // Process token after this frame
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        discordAuthService.setTokenFromDeepLink(token);
                      });
                    }

                    // Update permission service when auth changes
                    if (discordAuthService.isAuthenticated &&
                        discordAuthService.userInfo != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final permissionService =
                            Provider.of<PermissionService>(context,
                                listen: false);
                        permissionService.updatePermissions(
                          discordAuthService.role,
                          discordAuthService.permissions,
                        );
                      });
                    }

                    return authService.isAuthenticated ||
                            discordAuthService.isAuthenticated
                        ? const HomeScreen()
                        : const LoginScreen();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
