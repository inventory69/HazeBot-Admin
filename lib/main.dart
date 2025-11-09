import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/discord_auth_service.dart';
import 'services/permission_service.dart';
import 'services/config_service.dart';
import 'services/theme_service.dart';
import 'services/deep_link_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(const HazeBotAdminApp());
}

class HazeBotAdminApp extends StatefulWidget {
  const HazeBotAdminApp({super.key});

  @override
  State<HazeBotAdminApp> createState() => _HazeBotAdminAppState();
}

class _HazeBotAdminAppState extends State<HazeBotAdminApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    await _deepLinkService.init(onDeepLink: (uri) {
      debugPrint('Handling deep link: $uri');
      
      // Handle OAuth callback: hazebot://oauth?token=...
      if (uri.scheme == 'hazebot' && uri.host == 'oauth') {
        final token = uri.queryParameters['token'];
        if (token != null) {
          // Get DiscordAuthService and set token directly
          final discordAuthService = 
              // ignore: use_build_context_synchronously
              Provider.of<DiscordAuthService>(context, listen: false);
          discordAuthService.setTokenFromDeepLink(token);
        }
      }
    });
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DiscordAuthService()),
        ChangeNotifierProvider(create: (_) => PermissionService()),
        ChangeNotifierProvider(create: (_) => ConfigService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
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
                // Use dynamic colors from system (Material You)
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
                title: 'HazeBot Admin',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  colorScheme: lightColorScheme,
                  useMaterial3: true,
                  appBarTheme: const AppBarTheme(
                    centerTitle: true,
                    elevation: 2,
                  ),
                  cardTheme: CardThemeData(
                    elevation: 2,
                    color: lightColorScheme.surfaceContainer, // Better contrast
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                    elevation: 2,
                    color: darkColorScheme.surfaceContainer, // Better contrast
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
