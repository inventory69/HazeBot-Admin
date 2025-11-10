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
        screen:
            ChannelsConfigScreen(key: ValueKey('channels_$_reloadCounter')),
      ),
      NavigationItem(
        icon: Icons.people,
        label: 'Roles',
        screen: RolesConfigScreen(key: ValueKey('roles_$_reloadCounter')),
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
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
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
                                        final adminIndex = userItems.length + index;
                                        final item = adminItems[index];
                                        final isSelected = _selectedIndex == adminIndex;
                                        
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
                                              borderRadius: BorderRadius.circular(12),
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
                                                        fontSize: item.label.contains('\n')
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
          _optInRoles = List<Map<String, dynamic>>.from(
            profile['opt_in_roles'] ?? []
          );
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
        final padding = isMobile ? 12.0 : 24.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.person,
                      size: isMobile ? 28 : 32,
                      color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Profile',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontSize: isMobile ? 24 : null,
                              ),
                        ),
                        Text(
                          'Your HazeBot profile information',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: isMobile ? 13 : null,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 20 : 32),

              // Profile Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                  child: Column(
                    children: [
                      // Avatar & Name
                      Row(
                        children: [
                          // Avatar or Icon
                          _isLoading
                              ? Container(
                                  width: isMobile ? 72 : 88,
                                  height: isMobile ? 72 : 88,
                                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor().withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const CircularProgressIndicator(),
                                )
                              : _avatarUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        _avatarUrl!,
                                        width: isMobile ? 72 : 88,
                                        height: isMobile ? 72 : 88,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: isMobile ? 72 : 88,
                                            height: isMobile ? 72 : 88,
                                            padding: EdgeInsets.all(isMobile ? 16 : 20),
                                            decoration: BoxDecoration(
                                              color: _getRoleColor().withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Icon(
                                              _getRoleIcon(),
                                              size: isMobile ? 40 : 48,
                                              color: _getRoleColor(),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor().withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        _getRoleIcon(),
                                        size: isMobile ? 40 : 48,
                                        color: _getRoleColor(),
                                      ),
                                    ),
                          SizedBox(width: isMobile ? 16 : 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _displayName ?? widget.username,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 20 : null,
                                      ),
                                ),
                                SizedBox(height: isMobile ? 4 : 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        _getRoleColor().withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getRoleDisplayName(),
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: _getRoleColor(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 24 : 32),

                      // Discord Info
                      _ProfileInfoRow(
                        icon: Icons.discord,
                        label: 'Discord ID',
                        value: widget.discordId,
                        color: const Color(0xFF5865F2),
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      _ProfileInfoRow(
                        icon: Icons.badge,
                        label: 'Role',
                        value: _getRoleDisplayName(),
                        color: _getRoleColor(),
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // Opt-In Roles Section
              if (_isLoading)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_errorMessage != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Theme.of(context).colorScheme.onErrorContainer),
                        SizedBox(width: isMobile ? 12 : 16),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Opt-In Roles Card
                if (_optInRoles.isNotEmpty)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.interests,
                                color: Theme.of(context).colorScheme.primary,
                                size: isMobile ? 24 : 28,
                              ),
                              SizedBox(width: isMobile ? 8 : 12),
                              Text(
                                'Your Opt-In Roles',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                                backgroundColor: roleColor.withValues(alpha: 0.2),
                                side: BorderSide(color: roleColor, width: 1.5),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 8 : 12,
                                  vertical: isMobile ? 4 : 6,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                if (_optInRoles.isNotEmpty && _rlRank != null)
                  SizedBox(height: isMobile ? 16 : 24),

                // Rocket League Rank Card
                if (_rlRank != null)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.sports_esports,
                                color: Theme.of(context).colorScheme.primary,
                                size: isMobile ? 24 : 28,
                              ),
                              SizedBox(width: isMobile ? 8 : 12),
                              Text(
                                'Rocket League',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          Container(
                            padding: EdgeInsets.all(isMobile ? 16 : 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Rank Icon
                                if (_rlRank!['icon_url'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _rlRank!['icon_url'],
                                      width: isMobile ? 48 : 64,
                                      height: isMobile ? 48 : 64,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: isMobile ? 48 : 64,
                                          height: isMobile ? 48 : 64,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.sports_esports,
                                            size: isMobile ? 24 : 32,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                SizedBox(width: isMobile ? 12 : 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Highest Rank',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: isMobile ? 11 : 12,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (_rlRank!['emoji'] != null &&
                                              _rlRank!['emoji'].toString().isNotEmpty)
                                            Text(
                                              _rlRank!['emoji'],
                                              style: TextStyle(
                                                fontSize: isMobile ? 18 : 20,
                                              ),
                                            ),
                                          if (_rlRank!['emoji'] != null &&
                                              _rlRank!['emoji'].toString().isNotEmpty)
                                            const SizedBox(width: 8),
                                          Text(
                                            _rlRank!['rank'] ?? 'Unknown',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isMobile ? 16 : 18,
                                                ),
                                          ),
                                        ],
                                      ),
                                      if (_rlRank!['username'] != null) ...[
                                        const SizedBox(height: 4),
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
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_optInRoles.isEmpty && _rlRank == null && _customStats == null && _notifications == null && _activity == null)
                  SizedBox(height: isMobile ? 16 : 24),
              ],

              SizedBox(height: isMobile ? 16 : 24),

              // Custom Stats Section (Warnings, Resolved Tickets)
              if (_customStats != null) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bar_chart,
                              color: Theme.of(context).colorScheme.primary,
                              size: isMobile ? 24 : 28,
                            ),
                            SizedBox(width: isMobile ? 8 : 12),
                            Text(
                              'Custom Stats',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 18 : null,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 16 : 20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: _customStats!['warnings'] > 0
                                          ? Colors.orange
                                          : Colors.green,
                                      size: isMobile ? 32 : 40,
                                    ),
                                    SizedBox(height: isMobile ? 8 : 12),
                                    Text(
                                      '${_customStats!['warnings'] ?? 0}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isMobile ? 24 : null,
                                          ),
                                    ),
                                    SizedBox(height: isMobile ? 4 : 6),
                                    Text(
                                      'Warnings',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: isMobile ? 11 : 12,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_customStats!['resolved_tickets'] != null) ...[
                              SizedBox(width: isMobile ? 12 : 16),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                        size: isMobile ? 32 : 40,
                                      ),
                                      SizedBox(height: isMobile ? 8 : 12),
                                      Text(
                                        '${_customStats!['resolved_tickets'] ?? 0}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: isMobile ? 24 : null,
                                            ),
                                      ),
                                      SizedBox(height: isMobile ? 4 : 6),
                                      Text(
                                        'Resolved Tickets',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: isMobile ? 11 : 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),
              ],

              // Notifications Section
              if (_notifications != null) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications,
                              color: Theme.of(context).colorScheme.primary,
                              size: isMobile ? 24 : 28,
                            ),
                            SizedBox(width: isMobile ? 8 : 12),
                            Text(
                              'Notifications',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 18 : null,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 16 : 20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _notifications!['changelog_opt_in'] == true
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: _notifications!['changelog_opt_in'] == true
                                          ? Colors.green
                                          : Colors.grey,
                                      size: isMobile ? 24 : 28,
                                    ),
                                    SizedBox(width: isMobile ? 12 : 16),
                                    Expanded(
                                      child: Text(
                                        'Changelog Opt-in',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontSize: isMobile ? 13 : 15,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 16 : 20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _notifications!['meme_opt_in'] == true
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: _notifications!['meme_opt_in'] == true
                                          ? Colors.green
                                          : Colors.grey,
                                      size: isMobile ? 24 : 28,
                                    ),
                                    SizedBox(width: isMobile ? 12 : 16),
                                    Expanded(
                                      child: Text(
                                        'Meme Opt-in',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontSize: isMobile ? 13 : 15,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),
              ],

              // Activity Section
              if (_activity != null) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: Theme.of(context).colorScheme.primary,
                              size: isMobile ? 24 : 28,
                            ),
                            SizedBox(width: isMobile ? 8 : 12),
                            Text(
                              'Activity',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 18 : null,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Row(
                          children: [
                            Expanded(
                              child: _ActivityStatCard(
                                icon: Icons.message,
                                label: 'Messages',
                                value: '${_activity!['messages'] ?? 0}',
                                color: Colors.blue,
                                isMobile: isMobile,
                              ),
                            ),
                            SizedBox(width: isMobile ? 8 : 12),
                            Expanded(
                              child: _ActivityStatCard(
                                icon: Icons.image,
                                label: 'Images',
                                value: '${_activity!['images'] ?? 0}',
                                color: Colors.green,
                                isMobile: isMobile,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ActivityStatCard(
                                icon: Icons.emoji_emotions,
                                label: 'Memes Requested',
                                value: '${_activity!['memes_requested'] ?? 0}',
                                color: Colors.orange,
                                isMobile: isMobile,
                              ),
                            ),
                            SizedBox(width: isMobile ? 8 : 12),
                            Expanded(
                              child: _ActivityStatCard(
                                icon: Icons.brush,
                                label: 'Memes Generated',
                                value: '${_activity!['memes_generated'] ?? 0}',
                                color: Colors.purple,
                                isMobile: isMobile,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),
              ],

              // Quick Info Card
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          size: isMobile ? 24 : 28),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to HazeBot Admin!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontSize: isMobile ? 14 : null,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use the navigation menu to access meme generation and testing features. For more info, use /profile in Discord!',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontSize: isMobile ? 12 : null,
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

// Activity Stat Card Widget
class _ActivityStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isMobile;

  const _ActivityStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isMobile ? 24 : 32,
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : 22,
                ),
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: isMobile ? 10 : 11,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Profile Info Row Widget
class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isMobile;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Old _DashboardCard removed
