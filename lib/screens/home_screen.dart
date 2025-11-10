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
      _loadConfig();
    });
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

  List<NavigationItem> _getAvailableNavigationItems(
      PermissionService permissionService) {
    final items = <NavigationItem>[];

    // Dashboard - available to all
    if (permissionService.hasPermission('all') ||
        permissionService.hasPermission('meme_generator')) {
      items.add(NavigationItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        screen: DashboardScreen(key: ValueKey('dashboard_$_reloadCounter')),
      ));
    }

    // Admin/Mod only sections
    if (permissionService.hasPermission('all')) {
      items.addAll([
        NavigationItem(
          icon: Icons.tune_outlined,
          label: 'General',
          screen: GeneralConfigScreen(key: ValueKey('general_$_reloadCounter')),
        ),
        NavigationItem(
          icon: Icons.tag,
          label: 'Channels',
          screen:
              ChannelsConfigScreen(key: ValueKey('channels_$_reloadCounter')),
        ),
        NavigationItem(
          icon: Icons.people,
          label: 'Roles',
          screen: RolesConfigScreen(key: ValueKey('roles_$_reloadCounter')),
        ),
        NavigationItem(
          icon: Icons.image,
          label: 'Memes',
          screen: MemeConfigScreen(key: ValueKey('meme_$_reloadCounter')),
        ),
        NavigationItem(
          icon: Icons.schedule,
          label: 'Daily\nMeme',
          screen: DailyMemeConfigScreen(
              key: ValueKey('daily_meme_$_reloadCounter')),
        ),
        NavigationItem(
          icon: Icons.tune,
          label: 'Meme\nPrefs',
          screen: DailyMemePreferencesScreen(
              key: ValueKey('daily_meme_prefs_$_reloadCounter')),
        ),
      ]);
    }

    // Meme Generator - available to all users
    items.add(NavigationItem(
      icon: Icons.auto_awesome,
      label: 'Meme\nGen',
      screen:
          MemeGeneratorScreen(key: ValueKey('meme_generator_$_reloadCounter')),
    ));

    // Admin/Mod only sections
    if (permissionService.hasPermission('all')) {
      items.addAll([
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
          icon: Icons.settings,
          label: 'Settings',
          screen: SettingsScreen(key: ValueKey('settings_$_reloadCounter')),
        ),
        NavigationItem(
          icon: Icons.science,
          label: 'Test',
          screen: TestScreen(key: ValueKey('test_$_reloadCounter')),
        ),
      ]);
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final discordAuthService = Provider.of<DiscordAuthService>(context);
    final permissionService = Provider.of<PermissionService>(context);

    final navigationItems = _getAvailableNavigationItems(permissionService);

    // Ensure selected index is within bounds
    if (_selectedIndex >= navigationItems.length) {
      _selectedIndex = 0;
    }

    final screens = [
      DashboardScreen(key: ValueKey('dashboard_$_reloadCounter')),
      GeneralConfigScreen(key: ValueKey('general_$_reloadCounter')),
      ChannelsConfigScreen(key: ValueKey('channels_$_reloadCounter')),
      RolesConfigScreen(key: ValueKey('roles_$_reloadCounter')),
      MemeConfigScreen(key: ValueKey('meme_$_reloadCounter')),
      DailyMemeConfigScreen(key: ValueKey('daily_meme_$_reloadCounter')),
      DailyMemePreferencesScreen(
          key: ValueKey('daily_meme_prefs_$_reloadCounter')),
      MemeGeneratorScreen(key: ValueKey('meme_generator_$_reloadCounter')),
      RocketLeagueConfigScreen(key: ValueKey('rocket_league_$_reloadCounter')),
      TextsConfigScreen(key: ValueKey('texts_$_reloadCounter')),
      LogsScreen(key: ValueKey('logs_$_reloadCounter')),
      SettingsScreen(key: ValueKey('settings_$_reloadCounter')),
      TestScreen(key: ValueKey('test_$_reloadCounter')),
    ];

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
        title: Row(
          children: [
            const Text('HazeBot Admin'),
            const SizedBox(width: 16),
            if (discordAuthService.isAuthenticated &&
                discordAuthService.userInfo != null &&
                discordAuthService.userInfo!['discord_id'] != null)
              Chip(
                avatar: Icon(
                  Icons.discord,
                  size: 16,
                  color: const Color(0xFF5865F2),
                ),
                label: Text(
                  '${discordAuthService.userInfo!['user']} (${permissionService.role})',
                  style: TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        actions: [
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
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      extended: false,
                      labelType: NavigationRailLabelType.all,
                      destinations: navigationItems
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
                    ),
                  ),
                ),
              ),
            ),
          if (_isDrawerVisible) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: navigationItems[_selectedIndex].screen,
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
              Row(
                children: [
                  Icon(Icons.dashboard,
                      size: 32, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Dashboard',
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

// Old _DashboardCard removed
