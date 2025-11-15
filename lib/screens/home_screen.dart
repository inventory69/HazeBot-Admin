import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/discord_auth_service.dart';
import '../services/permission_service.dart';
import '../services/config_service.dart';
import '../services/api_service.dart';
import '../providers/data_cache_provider.dart';
import '../utils/app_config.dart';
import 'meme_detail_screen.dart';
import 'profile_screen.dart';
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
import 'gaming_hub_screen.dart';

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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = -1; // -1 = show user tabs, 0+ = admin item
  bool _isDrawerVisible = false; // Start with admin rail hidden
  int _reloadCounter = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final userItems = _getUserNavigationItems();
    _tabController = TabController(length: userItems.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          // Tab changed
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pingServer();
      _loadConfig();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final configService = Provider.of<ConfigService>(context, listen: false);
    // Use singleton ApiService directly
    await configService.loadConfig(ApiService());

    // Check if token expired
    if (configService.error == 'token_expired') {
      debugPrint(
          '⚠️ Config load failed with token_expired - Token refresh should have handled this');
      // DON'T logout immediately - token refresh should have been attempted
      // Only logout if refresh truly failed (indicated by clearToken being called)
      // The TokenExpiredException is thrown AFTER refresh attempts
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 12),
                Text('Session issue detected, attempting recovery...'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _loadConfig();
              },
            ),
          ),
        );
        // Give token refresh a chance - retry after a short delay
        await Future.delayed(const Duration(seconds: 1));
        await _loadConfig(); // Retry loading config
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

    // Gaming Hub - available to all users
    items.add(NavigationItem(
      icon: Icons.videogame_asset,
      label: 'Gaming\nHub',
      screen: GamingHubScreen(key: ValueKey('gaming_hub_$_reloadCounter')),
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
        leading: permissionService.hasPermission('all')
            ? IconButton(
                icon: Icon(_isDrawerVisible
                    ? Icons.admin_panel_settings
                    : Icons.admin_panel_settings_outlined),
                tooltip:
                    _isDrawerVisible ? 'Hide Admin Panel' : 'Show Admin Panel',
                onPressed: () {
                  setState(() {
                    _isDrawerVisible = !_isDrawerVisible;
                  });
                },
              )
            : null,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = MediaQuery.of(context).size.width < 600;

            return Row(
              children: [
                if (!isMobile)
                  Text(AppConfig.appName)
                else
                  Text(AppConfig.appName, style: const TextStyle(fontSize: 18)),
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
          // Profile picture with bottom sheet menu (all screen sizes)
          Builder(
            builder: (context) {
              final avatarUrl =
                  discordAuthService.userInfo?['avatar_url'] as String?;

              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle bar
                          Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          // User info
                          if (discordAuthService.isAuthenticated &&
                              discordAuthService.userInfo != null &&
                              discordAuthService.userInfo!['discord_id'] !=
                                  null)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Avatar or Discord icon (clickable to profile)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ProfileScreen(),
                                        ),
                                      );
                                    },
                                    child: avatarUrl != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            child: Image.network(
                                              avatarUrl,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  width: 48,
                                                  height: 48,
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF5865F2)
                                                            .withValues(
                                                                alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.discord,
                                                    size: 24,
                                                    color: Color(0xFF5865F2),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : Container(
                                            width: 48,
                                            height: 48,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF5865F2)
                                                  .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.discord,
                                              size: 24,
                                              color: Color(0xFF5865F2),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ProfileScreen(),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            discordAuthService
                                                .userInfo!['user'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            discordAuthService
                                                    .userInfo!['role_name'] ??
                                                permissionService.role,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const Divider(height: 1),

                          // Menu items
                          ListTile(
                            leading: const Icon(Icons.tune),
                            title: const Text('Preferences'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PreferencesScreen(
                                    key:
                                        ValueKey('preferences_$_reloadCounter'),
                                  ),
                                ),
                              );
                            },
                          ),

                          ListTile(
                            leading: const Icon(Icons.settings),
                            title: const Text('Settings'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsScreen(
                                    key: ValueKey('settings_$_reloadCounter'),
                                  ),
                                ),
                              );
                            },
                          ),

                          const Divider(height: 1),

                          ListTile(
                            leading: const Icon(Icons.refresh),
                            title: const Text('Reload Config'),
                            onTap: () {
                              Navigator.pop(context);
                              _loadConfig();
                            },
                          ),

                          ListTile(
                            leading: Icon(
                              Icons.logout,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            title: Text(
                              'Logout',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              authService.logout();
                              discordAuthService.logout();
                              permissionService.clear();
                            },
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: avatarUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            avatarUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 20,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Admin Navigation Rail (only show if has admin permissions)
          if (_isDrawerVisible && permissionService.hasPermission('all'))
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
                    child: Column(
                      children: [
                        // Home button to go back to user features
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedIndex = -1; // -1 = show user tabs
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.home,
                                  size: 24,
                                  color: _selectedIndex == -1
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Home',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _selectedIndex == -1
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(thickness: 1, height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                        const Divider(thickness: 1, height: 1),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: adminItems.length,
                            itemBuilder: (context, index) {
                              final item = adminItems[index];
                              final isSelected = _selectedIndex == index;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
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
                                        size: 24,
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
                                              fontSize:
                                                  item.label.contains('\n')
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
                  ),
                ),
              ),
            ),
          if (_isDrawerVisible && permissionService.hasPermission('all'))
            const VerticalDivider(thickness: 1, width: 1),
          // Main content area
          Expanded(
            child: _selectedIndex >= 0 &&
                    _selectedIndex < adminItems.length &&
                    permissionService.hasPermission('all')
                ? // Admin selected: show admin screen directly
                adminItems[_selectedIndex].screen
                : // User features: show tabs at bottom
                Column(
                    children: [
                      // Tab content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children:
                              userItems.map((item) => item.screen).toList(),
                        ),
                      ),
                      // Tab bar for user features (at bottom)
                      Material(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        elevation: 4,
                        child: SafeArea(
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            padding: EdgeInsets.zero,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            tabAlignment: TabAlignment.center,
                            tabs: userItems
                                .map((item) => Tab(
                                      icon: Icon(item.icon, size: 20),
                                      text: item.label.replaceAll('\n', ' '),
                                    ))
                                .toList(),
                            labelColor: Theme.of(context).colorScheme.primary,
                            unselectedLabelColor:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            indicatorColor:
                                Theme.of(context).colorScheme.primary,
                            indicatorSize: TabBarIndicatorSize.label,
                            labelStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load data only if cache is empty (first time only)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cacheProvider =
          Provider.of<DataCacheProvider>(context, listen: false);
      // Only load if cache is empty - cache will prevent duplicate requests
      if (cacheProvider.memes == null || cacheProvider.rankups == null) {
        _loadData();
      }
    });
  }

  Future<void> _loadData({bool force = false}) async {
    final cacheProvider =
        Provider.of<DataCacheProvider>(context, listen: false);
    await Future.wait([
      cacheProvider.loadLatestMemes(force: force),
      cacheProvider.loadLatestRankups(force: force),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Consumer<DataCacheProvider>(
      builder: (context, cacheProvider, child) {
        final memes = cacheProvider.memes ?? [];
        final rankups = cacheProvider.rankups ?? [];
        final isLoadingMemes = cacheProvider.isLoadingMemes;
        final isLoadingRankups = cacheProvider.isLoadingRankups;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final padding = isMobile ? 12.0 : 16.0;

            return Scaffold(
              appBar: AppBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('HazeHub'),
                    if (cacheProvider.lastMemesLoad != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cacheProvider.getCacheAge(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _loadData(force: true),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () => _loadData(force: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Latest Memes Section
                      _buildMemesSection(
                          context, isMobile, memes, isLoadingMemes),

                      SizedBox(height: isMobile ? 12 : 16),

                      // Latest Rank-Ups Section
                      _buildRankupsSection(
                          context, isMobile, rankups, isLoadingRankups),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMemesSection(BuildContext context, bool isMobile,
      List<Map<String, dynamic>> memes, bool isLoadingMemes) {
    return Card(
      // Main section card uses surfaceContainerLow (from CardTheme)
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.image, size: isMobile ? 20 : 24),
                    const SizedBox(width: 8),
                    Text(
                      'Latest Memes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: isMobile ? 18 : null,
                          ),
                    ),
                  ],
                ),
                if (memes.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Navigate to full memes view
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Full memes view coming soon')),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View More'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoadingMemes)
              const Center(child: CircularProgressIndicator())
            else if (memes.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.image_not_supported,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No memes yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: memes
                    .map((meme) => _buildMemeCard(context, meme, isMobile))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemeCard(
      BuildContext context, Map<String, dynamic> meme, bool isMobile) {
    final imageUrl = meme['image_url'] as String?;
    final title = meme['title'] as String? ?? 'Untitled';
    final author = meme['author'] as String? ?? 'Unknown';
    final score = meme['score'] as int? ?? 0;
    final isCustom = meme['is_custom'] as bool? ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      // Inner card uses surfaceContainer for contrast with section card
      color: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 1,
      child: InkWell(
        onTap: () async {
          // Navigate to meme detail screen and handle result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemeDetailScreen(meme: meme),
            ),
          );

          // Refresh memes if changes were made
          if (result != null && result is Map<String, dynamic>) {
            final cacheProvider =
                Provider.of<DataCacheProvider>(context, listen: false);
            await cacheProvider.loadLatestMemes(force: true);
          }
        },
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with Hero animation
              if (imageUrl != null)
                Hero(
                  tag: 'meme_${meme['message_id']}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: isMobile ? 80 : 100,
                      height: isMobile ? 80 : 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: isMobile ? 80 : 100,
                          height: isMobile ? 80 : 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: isMobile ? 80 : 100,
                          height: isMobile ? 80 : 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.image,
                              size: 32, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                ),
              SizedBox(width: isMobile ? 8 : 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person,
                            size: isMobile ? 14 : 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            author,
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Score/Upvotes from original source
                        if (!isCustom && score > 0) ...[
                          Icon(
                            Icons.trending_up,
                            size: isMobile ? 14 : 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$score',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Custom badge
                        if (isCustom) ...[
                          Icon(
                            Icons.auto_awesome,
                            size: isMobile ? 14 : 16,
                            color: Colors.purple[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Custom',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              color: Colors.purple[400],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Discord upvotes
                        Icon(
                          Icons.thumb_up,
                          size: isMobile ? 14 : 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${meme['upvotes'] ?? 0}',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankupsSection(BuildContext context, bool isMobile,
      List<Map<String, dynamic>> rankups, bool isLoadingRankups) {
    return Card(
      // Main section card uses surfaceContainerLow (from CardTheme)
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, size: isMobile ? 20 : 24),
                    const SizedBox(width: 8),
                    Text(
                      'Latest Rank-Ups',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: isMobile ? 18 : null,
                          ),
                    ),
                  ],
                ),
                if (rankups.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Navigate to full rank-ups view
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Full rank-ups view coming soon')),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View More'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoadingRankups)
              const Center(child: CircularProgressIndicator())
            else if (rankups.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.trending_up, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No rank-ups yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: rankups
                    .map(
                        (rankup) => _buildRankupCard(context, rankup, isMobile))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankupCard(
      BuildContext context, Map<String, dynamic> rankup, bool isMobile) {
    final user = rankup['user'] as String? ?? 'Unknown Player';
    final newRank = rankup['new_rank'] as String? ?? 'Unknown Rank';
    final oldRank = rankup['old_rank'] as String?;
    final division = rankup['division'] as String?;
    final mode = rankup['mode'] as String?;
    final thumbnail = rankup['thumbnail'] as String?;
    final color = rankup['color'] as int?;

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      // Inner card uses surfaceContainer for contrast with section card
      color: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank Icon/Thumbnail
            if (thumbnail != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  thumbnail,
                  width: isMobile ? 60 : 70,
                  height: isMobile ? 60 : 70,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: isMobile ? 60 : 70,
                      height: isMobile ? 60 : 70,
                      decoration: BoxDecoration(
                        color: color != null
                            ? Color(color).withOpacity(0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: isMobile ? 60 : 70,
                      height: isMobile ? 60 : 70,
                      decoration: BoxDecoration(
                        color: color != null
                            ? Color(color).withOpacity(0.2)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.emoji_events,
                          size: 32,
                          color:
                              color != null ? Color(color) : Colors.grey[600]),
                    );
                  },
                ),
              )
            else
              Container(
                width: isMobile ? 60 : 70,
                height: isMobile ? 60 : 70,
                decoration: BoxDecoration(
                  color: color != null
                      ? Color(color).withOpacity(0.2)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.emoji_events,
                    size: 32,
                    color: color != null ? Color(color) : Colors.grey[600]),
              ),
            SizedBox(width: isMobile ? 8 : 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (oldRank != null) ...[
                    Text(
                      '$oldRank → $newRank',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    Text(
                      newRank,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (division != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      division,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  if (mode != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      mode,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// User Dashboard widget remains for now (can be extracted to separate screen later)
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

class _UserDashboardState extends State<_UserDashboard>
    with AutomaticKeepAliveClientMixin {
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
  bool get wantKeepAlive => true;

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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
          padding: EdgeInsets.fromLTRB(
            isMobile ? 12 : 16, // left
            isMobile ? 16 : 24, // top
            isMobile ? 12 : 16, // right
            isMobile ? 16 : 24, // bottom
          ),
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
              SizedBox(height: isMobile ? 12 : 16),

              // Profile Information Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 6 : 10),
                  child: Row(
                    children: [
                      // Avatar
                      if (_avatarUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network(
                            _avatarUrl!,
                            width: isMobile ? 36 : 44,
                            height: isMobile ? 36 : 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: isMobile ? 36 : 44,
                                height: isMobile ? 36 : 44,
                                decoration: BoxDecoration(
                                  color: _getRoleColor().withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _getRoleIcon(),
                                  size: isMobile ? 20 : 24,
                                  color: _getRoleColor(),
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
                            color: _getRoleColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _getRoleIcon(),
                            size: isMobile ? 20 : 24,
                            color: _getRoleColor(),
                          ),
                        ),
                      SizedBox(width: isMobile ? 10 : 12),
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
              SizedBox(height: isMobile ? 12 : 16),

              // Rocket League Rank Card (if available)
              if (_rlRank != null) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 6 : 10),
                    child: Row(
                      children: [
                        // Rank Icon
                        if (_rlRank!['icon_url'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.network(
                              _rlRank!['icon_url'],
                              width: isMobile ? 28 : 36,
                              height: isMobile ? 28 : 36,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: isMobile ? 28 : 36,
                                  height: isMobile ? 28 : 36,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Icon(
                                    Icons.sports_esports,
                                    size: isMobile ? 16 : 18,
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
                            width: isMobile ? 32 : 40,
                            height: isMobile ? 32 : 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.sports_esports,
                              size: isMobile ? 18 : 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        SizedBox(width: isMobile ? 10 : 12),
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
                SizedBox(height: isMobile ? 12 : 16),
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
            crossAxisSpacing: isMobile ? 6 : 8,
            mainAxisSpacing: isMobile ? 6 : 8,
            childAspectRatio: isMobile ? 1.5 : 1.7,
            children: statCards,
          ),

        if (statCards.isNotEmpty && _optInRoles.isNotEmpty)
          SizedBox(height: isMobile ? 12 : 16),

        // Opt-In Roles Card
        if (_optInRoles.isNotEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 8 : 12),
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
    return Builder(
      builder: (context) => Card(
        elevation: 1,
        // Use surfaceContainer for stat cards - proper contrast with background
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 4 : 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: isMobile ? 18 : 22),
              SizedBox(height: isMobile ? 2 : 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 8 : 9,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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

class _AdminDashboardState extends State<_AdminDashboard>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 12 : 16, // left
            isMobile ? 16 : 24, // top
            isMobile ? 12 : 16, // right
            isMobile ? 16 : 24, // bottom
          ),
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
              SizedBox(height: isMobile ? 12 : 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
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
