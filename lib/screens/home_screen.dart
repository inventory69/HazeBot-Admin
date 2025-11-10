import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/discord_auth_service.dart';
import '../services/permission_service.dart';
import '../services/config_service.dart';
import '../services/api_service.dart';
import 'config/general_config_screen.dart';
import 'config/channels_config_screen.dart';
import 'config/roles_config_screen.dart';
import 'config/meme_config_screen.dart';
import 'config/daily_meme_config_screen.dart';
import 'config/daily_meme_preferences_screen.dart';
import 'config/meme_generator_screen.dart';
import 'config/rocket_league_config_screen.dart';
import 'config/texts_config_screen.dart';
import 'admin/live_users_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';
import 'test_screen.dart';
import 'user_rocket_league_screen.dart';
import 'preferences_screen.dart';

class NavigationItem {
  final IconData icon;
  final String label;
  final Widget screen;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isDrawerVisible = true; // Track drawer visibility
  int _reloadCounter = 0; // Counter to force screen rebuild

  @override
  void initState() {
    super.initState();
    // Load config after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pingServer();
      _loadConfig();
    });
  }

  Future<void> _pingServer() async {
    // Ping server to register session (works for all users)
    try {
      await ApiService().ping();
      debugPrint('Session ping successful');
    } catch (e) {
      debugPrint('Session ping failed: $e');
      // Don't show error to user - this is just for session tracking
    }
  }

  Future<void> _loadConfig() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final configService = Provider.of<ConfigService>(context, listen: false);
    // Use singleton ApiService directly instead of authService.apiService
    await configService.loadConfig(ApiService());

    // Check if token expired
    if (configService.error == 'token_expired') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Session expired. Please login again.'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        // Logout and return to login screen
        authService.logout();
      }
    } else if (mounted) {
      // Increment counter to force screen rebuild
      setState(() {
        _reloadCounter++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Configuration reloaded successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // User features (available to all)
  List<NavigationItem> _getUserNavigationItems() {
    final items = <NavigationItem>[];

    // Dashboard - available to all
    items.add(NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      screen: DashboardScreen(key: ValueKey('dashboard_$_reloadCounter')),
    ));

    // Preferences - available to all users
    items.add(NavigationItem(
      icon: Icons.tune,
      label: 'Prefs',
      screen: PreferencesScreen(key: ValueKey('preferences_$_reloadCounter')),
    ));

    // Rocket League - available to all users
    items.add(NavigationItem(
      icon: Icons.sports_esports,
      label: 'Rocket\nLeague',
      screen: UserRocketLeagueScreen(
          key: ValueKey('user_rocket_league_$_reloadCounter')),
    ));

    // Meme Generator - available to all users
    items.add(NavigationItem(
      icon: Icons.auto_awesome,
      label: 'Meme\nGen',
      screen:
          MemeGeneratorScreen(key: ValueKey('meme_generator_$_reloadCounter')),
    ));

    // Meme Testing - available to all users (Daily Meme Test removed, now admin-only in Daily Meme Config)
    items.add(NavigationItem(
      icon: Icons.image,
      label: 'Memes',
      screen: MemeConfigScreen(key: ValueKey('meme_$_reloadCounter')),
    ));

    // Settings - available to all users
    items.add(NavigationItem(
      icon: Icons.settings,
      label: 'Settings',
      screen: SettingsScreen(key: ValueKey('settings_$_reloadCounter')),
    ));

    return items;
  }

  // Admin features (admin/mod only)
  List<NavigationItem> _getAdminNavigationItems() {
    final items = <NavigationItem>[];

    items.addAll([
      NavigationItem(
        icon: Icons.tune_outlined,
        label: 'General',
        screen: GeneralConfigScreen(key: ValueKey('general_$_reloadCounter')),
      ),
      NavigationItem(
        icon: Icons.tag,
        label: 'Channels',
        screen: ChannelsConfigScreen(key: ValueKey('channels_$_reloadCounter')),
      ),
      NavigationItem(
        icon: Icons.people,
        label: 'Roles',
        screen: RolesConfigScreen(key: ValueKey('roles_$_reloadCounter')),
      ),
      NavigationItem(
        icon: Icons.schedule,
        label: 'Daily\nMeme',
        screen:
            DailyMemeConfigScreen(key: ValueKey('daily_meme_$_reloadCounter')),
      ),
      NavigationItem(
        icon: Icons.tune,
        label: 'Meme\nPrefs',
        screen: DailyMemePreferencesScreen(
            key: ValueKey('daily_meme_prefs_$_reloadCounter')),
      ),
      NavigationItem(
        icon: Icons.sports_esports,
        label: 'Rocket\nLeague',
        screen: RocketLeagueConfigScreen(
            key: ValueKey('rocket_league_$_reloadCounter')),
      ),
      NavigationItem(
        icon: Icons.text_fields,
        label: 'Texts',
        screen: TextsConfigScreen(key: ValueKey('texts_$_reloadCounter')),
      ),
      NavigationItem(
        icon: Icons.people_outline,
        label: 'Live\nUsers',
        screen: LiveUsersScreen(key: ValueKey('live_users_$_reloadCounter')),
      ),
      NavigationItem(
        icon: Icons.description,
        label: 'Logs',
        screen: LogsScreen(key: ValueKey('logs_$_reloadCounter')),
      ),
      NavigationItem(
        icon: Icons.science,
        label: 'Test',
        screen: TestScreen(key: ValueKey('test_$_reloadCounter')),
      ),
    ]);

    return items;
  }

  List<NavigationItem> _getAllNavigationItems(
      PermissionService permissionService) {
    final items = <NavigationItem>[];

    // Always add user features
    items.addAll(_getUserNavigationItems());

    // Add admin features if user has permissions
    if (permissionService.hasPermission('all')) {
      items.addAll(_getAdminNavigationItems());
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final discordAuthService = Provider.of<DiscordAuthService>(context);
    final permissionService = Provider.of<PermissionService>(context);

    final userItems = _getUserNavigationItems();
    final adminItems = _getAdminNavigationItems();
    final allItems = _getAllNavigationItems(permissionService);

    // Ensure selected index is within bounds
    if (_selectedIndex >= allItems.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(_isDrawerVisible ? Icons.menu_open : Icons.menu),
          tooltip: _isDrawerVisible ? 'Hide Menu' : 'Show Menu',
          onPressed: () {
            setState(() {
              _isDrawerVisible = !_isDrawerVisible;
            });
          },
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = MediaQuery.of(context).size.width < 600;
            final isTablet = MediaQuery.of(context).size.width < 900;

            return Row(
              children: [
                if (!isMobile)
                  const Text('HazeBot Admin')
                else
                  const Text('HazeBot', style: TextStyle(fontSize: 18)),
                if (!isMobile &&
                    discordAuthService.isAuthenticated &&
                    discordAuthService.userInfo != null &&
                    discordAuthService.userInfo!['discord_id'] != null) ...[
                  const SizedBox(width: 16),
                  Flexible(
                    child: Chip(
                      avatar: Icon(
                        Icons.discord,
                        size: 16,
                        color: const Color(0xFF5865F2),
                      ),
                      label: Text(
                        '${discordAuthService.userInfo!['user']} (${permissionService.role})',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = MediaQuery.of(context).size.width < 600;

              if (isMobile) {
                // Mobile: Show dropdown menu
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Menu',
                  onSelected: (value) {
                    switch (value) {
                      case 'reload':
                        _loadConfig();
                        break;
                      case 'logout':
                        authService.logout();
                        discordAuthService.logout();
                        permissionService.clear();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (discordAuthService.isAuthenticated &&
                        discordAuthService.userInfo != null &&
                        discordAuthService.userInfo!['discord_id'] != null)
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Row(
                          children: [
                            Icon(
                              Icons.discord,
                              size: 16,
                              color: const Color(0xFF5865F2),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    discordAuthService.userInfo!['user'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    permissionService.role,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (discordAuthService.isAuthenticated &&
                        discordAuthService.userInfo != null &&
                        discordAuthService.userInfo!['discord_id'] != null)
                      const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'reload',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 20),
                          SizedBox(width: 12),
                          Text('Reload Config'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 12),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Desktop/Tablet: Show regular buttons
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Reload Configuration',
                      onPressed: _loadConfig,
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: 'Logout',
                      onPressed: () {
                        authService.logout();
                        discordAuthService.logout();
                        permissionService.clear();
                      },
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (_isDrawerVisible)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      selectedIndex: _selectedIndex < userItems.length
                          ? _selectedIndex
                          : null,
                      onDestinationSelected: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      extended: false,
                      labelType: NavigationRailLabelType.all,
                      // User features (always visible)
                      destinations: userItems
                          .map((item) => NavigationRailDestination(
                                icon: Icon(item.icon),
                                label: Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  style: item.label.contains('\n')
                                      ? const TextStyle(fontSize: 11)
                                      : null,
                                ),
                              ))
                          .toList(),
                      // Admin features (grouped below with divider)
                      trailing: permissionService.hasPermission('all')
                          ? Expanded(
                              child: Column(
                                children: [
                                  const Divider(thickness: 1, height: 32),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.admin_panel_settings,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ADMIN',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: adminItems.length,
                                      itemBuilder: (context, index) {
                                        final adminIndex =
                                            userItems.length + index;
                                        final item = adminItems[index];
                                        final isSelected =
                                            _selectedIndex == adminIndex;

                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedIndex = adminIndex;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  item.icon,
                                                  color: isSelected
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryContainer
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.label,
                                                  textAlign: TextAlign.center,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        fontSize: item.label
                                                                .contains('\n')
                                                            ? 10
                                                            : 11,
                                                        color: isSelected
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .onPrimaryContainer
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          if (_isDrawerVisible) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: allItems[_selectedIndex].screen,
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _refreshTimer;
  bool _autoReload = false;

  @override
  void initState() {
    super.initState();
    // Load config on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _toggleAutoReload() {
    setState(() {
      _autoReload = !_autoReload;
      if (_autoReload) {
        // Start auto-refresh timer (every 5 seconds)
        _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          if (mounted) {
            _loadConfigSilently();
          }
        });
      } else {
        // Stop timer
        _refreshTimer?.cancel();
        _refreshTimer = null;
      }
    });
  }

  Future<void> _loadConfig() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final configService = Provider.of<ConfigService>(context, listen: false);
    // Use singleton ApiService directly
    await configService.loadConfig(ApiService());
  }

  Future<void> _loadConfigSilently() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final configService = Provider.of<ConfigService>(context, listen: false);
    // Use singleton ApiService directly
    await configService.loadConfig(ApiService(), silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final permissionService = Provider.of<PermissionService>(context);
    final discordAuthService = Provider.of<DiscordAuthService>(context);
    final isAdmin = permissionService.hasPermission('all');

    // Show user dashboard for non-admin users
    if (!isAdmin) {
      return _UserDashboard(
        username: discordAuthService.userInfo?['user'] ?? 'User',
        discordId: discordAuthService.userInfo?['discord_id'] ?? 'N/A',
        role: permissionService.role,
      );
    }

    // Show admin dashboard for admins
    return Consumer<ConfigService>(
      builder: (context, configService, _) {
        if (configService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final config = configService.config;
        if (config == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load configuration',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  configService.error == 'token_expired'
                      ? 'Session expired. Redirecting to login...'
                      : 'Please check your connection and try again.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (configService.error != 'token_expired') ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      // Use singleton ApiService directly
                      configService.loadConfig(ApiService());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ],
            ),
          );
        }

        // Calculate meme sources count
        final subredditCount =
            (config['meme']?['subreddits'] as List?)?.length ?? 0;
        final lemmyCount =
            (config['meme']?['lemmy_communities'] as List?)?.length ?? 0;
        final totalMemeSources = subredditCount + lemmyCount;

        // Get daily meme info
        final dailyMemeEnabled = config['daily_meme']?['enabled'] ?? false;
        final dailyMemeHour = config['daily_meme']?['hour'] ?? 12;
        final dailyMemeMinute = config['daily_meme']?['minute'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section (for admins to see their own profile)
              _UserDashboard(
                username: discordAuthService.userInfo?['username'] ?? 'N/A',
                discordId: discordAuthService.userInfo?['discord_id'] ?? 'N/A',
                role: permissionService.role,
              ),
              const SizedBox(height: 32),

              // Divider
              Divider(
                color: Theme.of(context).colorScheme.outlineVariant,
                thickness: 1,
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Icon(Icons.settings,
                      size: 32, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Bot Configuration',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const Spacer(),
                  // Auto-reload toggle
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.autorenew,
                        size: 20,
                        color: _autoReload
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Auto-reload',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _autoReload
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _autoReload,
                        onChanged: (_) => _toggleAutoReload(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bot Status Section
              _DashboardSection(
                title: 'Bot Status',
                icon: Icons.smart_toy,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          title: 'Bot Name',
                          value: config['general']?['bot_name'] ?? 'N/A',
                          icon: Icons.label,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          title: 'Mode',
                          value: config['general']?['prod_mode'] == true
                              ? 'Production'
                              : 'Test',
                          icon: Icons.flag,
                          color: config['general']?['prod_mode'] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          title: 'Prefix',
                          value: config['general']?['command_prefix'] ?? 'N/A',
                          icon: Icons.terminal,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Discord Server',
                    value: config['discord_ids']?['guild_name']?.toString() ??
                        config['discord_ids']?['guild_id']?.toString() ??
                        'N/A',
                    icon: Icons.discord,
                    color: Colors.blueAccent,
                    subtitle:
                        'ID: ${config['discord_ids']?['guild_id'] ?? 'N/A'}',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Meme Configuration Section
              _DashboardSection(
                title: 'Meme Configuration',
                icon: Icons.image,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          title: 'Subreddits',
                          value: '$subredditCount',
                          icon: Icons.reddit,
                          color: Colors.deepOrange,
                          subtitle: 'Reddit sources',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          title: 'Lemmy Communities',
                          value: '$lemmyCount',
                          icon: Icons.forum,
                          color: Colors.teal,
                          subtitle: 'Lemmy sources',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          title: 'Total Sources',
                          value: '$totalMemeSources',
                          icon: Icons.source,
                          color: Colors.pink,
                          subtitle: 'Combined',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          title: 'Daily Memes',
                          value: dailyMemeEnabled ? 'Enabled' : 'Disabled',
                          icon: dailyMemeEnabled
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: dailyMemeEnabled ? Colors.green : Colors.grey,
                          subtitle: dailyMemeEnabled
                              ? 'Posted at ${dailyMemeHour.toString().padLeft(2, '0')}:${dailyMemeMinute.toString().padLeft(2, '0')}'
                              : 'Not scheduled',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          title: 'NSFW Content',
                          value: config['daily_meme']?['allow_nsfw'] == true
                              ? 'Allowed'
                              : 'Blocked',
                          icon: config['daily_meme']?['allow_nsfw'] == true
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: config['daily_meme']?['allow_nsfw'] == true
                              ? Colors.amber
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Other Features Section
              _DashboardSection(
                title: 'Other Features',
                icon: Icons.settings,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          title: 'RL Check Interval',
                          value:
                              '${config['rocket_league']?['rank_check_interval_hours'] ?? 'N/A'}h',
                          icon: Icons.sports_esports,
                          color: Colors.indigo,
                          subtitle: 'Rank checking',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          title: 'Message Cooldown',
                          value:
                              '${config['general']?['message_cooldown'] ?? 'N/A'}s',
                          icon: Icons.timer,
                          color: Colors.deepPurple,
                          subtitle: 'Anti-spam',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          title: 'Fuzzy Matching',
                          value:
                              '${((config['general']?['fuzzy_matching_threshold'] ?? 0) * 100).toInt()}%',
                          icon: Icons.find_in_page,
                          color: Colors.cyan,
                          subtitle: 'Similarity threshold',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Tips
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Tip',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use the navigation menu to configure bot settings. Changes are saved in real-time!',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Dashboard Section Widget
class _DashboardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DashboardSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

// Compact Info Card Widget
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      // Uses theme default (surfaceContainer) for better contrast
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// User Dashboard (for non-admin users)
class _UserDashboard extends StatefulWidget {
  final String username;
  final String discordId;
  final String role;

  const _UserDashboard({
    required this.username,
    required this.discordId,
    required this.role,
  });

  @override
  State<_UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<_UserDashboard> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _optInRoles = [];
  Map<String, dynamic>? _rlRank;
  String? _errorMessage;
  String? _displayName;
  String? _avatarUrl;
  Map<String, dynamic>? _notifications;
  Map<String, dynamic>? _customStats;
  Map<String, dynamic>? _activity;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().getUserProfile();

      if (response['success'] == true && response['profile'] != null) {
        final profile = response['profile'];
        setState(() {
          _optInRoles =
              List<Map<String, dynamic>>.from(profile['opt_in_roles'] ?? []);
          _rlRank = profile['rl_rank'];
          _displayName = profile['display_name'];
          _avatarUrl = profile['avatar_url'];
          _notifications = profile['notifications'];
          _customStats = profile['custom_stats'];
          _activity = profile['activity'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Color _getRoleColor() {
    switch (widget.role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'mod':
        return Colors.orange;
      case 'lootling':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon() {
    switch (widget.role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'mod':
        return Icons.shield;
      case 'lootling':
        return Icons.backpack;
      default:
        return Icons.person;
    }
  }

  String _getRoleDisplayName() {
    switch (widget.role.toLowerCase()) {
      case 'admin':
        return '🧊 Inventory Master';
      case 'mod':
        return '📦 Slot Keeper';
      case 'lootling':
        return '🎒 Lootling';
      default:
        return widget.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth < 900;

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadProfileData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'My Profile',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 22 : null,
                    ),
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // Profile Information Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Row(
                    children: [
                      // Avatar
                      if (_avatarUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _avatarUrl!,
                            width: isMobile ? 48 : 56,
                            height: isMobile ? 48 : 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: isMobile ? 48 : 56,
                                height: isMobile ? 48 : 56,
                                decoration: BoxDecoration(
                                  color: _getRoleColor().withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getRoleIcon(),
                                  size: isMobile ? 24 : 28,
                                  color: _getRoleColor(),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          width: isMobile ? 48 : 56,
                          height: isMobile ? 48 : 56,
                          decoration: BoxDecoration(
                            color: _getRoleColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getRoleIcon(),
                            size: isMobile ? 24 : 28,
                            color: _getRoleColor(),
                          ),
                        ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName ?? widget.username,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 16 : 20,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRoleColor().withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _getRoleDisplayName(),
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 13,
                                  fontWeight: FontWeight.bold,
                                  color: _getRoleColor(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${widget.discordId}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: isMobile ? 11 : 12,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // Rocket League Rank Card (if available)
              if (_rlRank != null) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    child: Row(
                      children: [
                        // Rank Icon
                        if (_rlRank!['icon_url'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _rlRank!['icon_url'],
                              width: isMobile ? 40 : 48,
                              height: isMobile ? 40 : 48,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: isMobile ? 40 : 48,
                                  height: isMobile ? 40 : 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.sports_esports,
                                    size: isMobile ? 20 : 24,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          Container(
                            width: isMobile ? 40 : 48,
                            height: isMobile ? 40 : 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.sports_esports,
                              size: isMobile ? 20 : 24,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        SizedBox(width: isMobile ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rocket League',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: isMobile ? 11 : 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _rlRank!['rank'] ?? 'Unknown',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_rlRank!['username'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${_rlRank!['platform']}: ${_rlRank!['username']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: isMobile ? 11 : 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),
              ],

              // Stats Grid
              _buildStatsGrid(context, isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(BuildContext context, bool isMobile, bool isTablet) {
    final List<Widget> statCards = [];

    // Custom Stats
    if (_customStats != null) {
      statCards.add(
        _StatCard(
          icon: Icons.warning,
          label: 'Warnings',
          value: '${_customStats!['warnings'] ?? 0}',
          color: _customStats!['warnings'] > 0 ? Colors.orange : Colors.green,
          isMobile: isMobile,
        ),
      );
      if (_customStats!['resolved_tickets'] != null) {
        statCards.add(
          _StatCard(
            icon: Icons.check_circle,
            label: 'Resolved Tickets',
            value: '${_customStats!['resolved_tickets'] ?? 0}',
            color: Colors.blue,
            isMobile: isMobile,
          ),
        );
      }
    }

    // Notifications
    if (_notifications != null) {
      statCards.add(
        _StatCard(
          icon: _notifications!['changelog_opt_in'] == true
              ? Icons.check_circle
              : Icons.cancel,
          label: 'Changelog',
          value: _notifications!['changelog_opt_in'] == true
              ? 'Opted In'
              : 'Opted Out',
          color: _notifications!['changelog_opt_in'] == true
              ? Colors.green
              : Colors.grey,
          isMobile: isMobile,
        ),
      );
      statCards.add(
        _StatCard(
          icon: _notifications!['meme_opt_in'] == true
              ? Icons.check_circle
              : Icons.cancel,
          label: 'Meme Notifs',
          value:
              _notifications!['meme_opt_in'] == true ? 'Opted In' : 'Opted Out',
          color: _notifications!['meme_opt_in'] == true
              ? Colors.green
              : Colors.grey,
          isMobile: isMobile,
        ),
      );
    }

    // Activity Stats
    if (_activity != null) {
      statCards.addAll([
        _StatCard(
          icon: Icons.message,
          label: 'Messages',
          value: '${_activity!['messages'] ?? 0}',
          color: Colors.blue,
          isMobile: isMobile,
        ),
        _StatCard(
          icon: Icons.image,
          label: 'Images',
          value: '${_activity!['images'] ?? 0}',
          color: Colors.green,
          isMobile: isMobile,
        ),
        _StatCard(
          icon: Icons.emoji_emotions,
          label: 'Memes Requested',
          value: '${_activity!['memes_requested'] ?? 0}',
          color: Colors.orange,
          isMobile: isMobile,
        ),
        _StatCard(
          icon: Icons.brush,
          label: 'Memes Generated',
          value: '${_activity!['memes_generated'] ?? 0}',
          color: Colors.purple,
          isMobile: isMobile,
        ),
      ]);
    }

    return Column(
      children: [
        // Stats Grid
        if (statCards.isNotEmpty)
          GridView.count(
            crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: isMobile ? 8 : 12,
            mainAxisSpacing: isMobile ? 8 : 12,
            childAspectRatio: isMobile ? 1.4 : 1.6,
            children: statCards,
          ),

        if (statCards.isNotEmpty && _optInRoles.isNotEmpty)
          SizedBox(height: isMobile ? 16 : 24),

        // Opt-In Roles Card
        if (_optInRoles.isNotEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.interests,
                        size: isMobile ? 18 : 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Opt-In Roles',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _optInRoles.map((role) {
                      final roleName = role['name'] ?? 'Unknown';
                      final roleColor = Color(role['color'] ?? 0xFF808080);

                      return Chip(
                        label: Text(
                          roleName,
                          style: TextStyle(
                            color: roleColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 11 : 12,
                          ),
                        ),
                        backgroundColor: roleColor.withValues(alpha: 0.2),
                        side: BorderSide(color: roleColor, width: 1.5),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 8,
                          vertical: isMobile ? 2 : 4,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _StatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isMobile,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isMobile ? 24 : 28),
            SizedBox(height: isMobile ? 4 : 6),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 15 : 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 10 : 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ADMIN DASHBOARD STARTS HERE
class _AdminDashboard extends StatefulWidget {
  const _AdminDashboard();

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Placeholder for actual dashboard data loading
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _dashboardData = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 22 : null,
                    ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: const Center(
                    child: Text('Admin statistics and controls coming soon'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
