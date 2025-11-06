import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/config_service.dart';
import 'config/general_config_screen.dart';
import 'config/channels_config_screen.dart';
import 'config/roles_config_screen.dart';
import 'config/meme_config_screen.dart';
import 'config/daily_meme_config_screen.dart';
import 'config/daily_meme_preferences_screen.dart';
import 'config/rocket_league_config_screen.dart';
import 'config/welcome_config_screen.dart';
import 'test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isDrawerExpanded = true; // Track drawer state
  
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
    await configService.loadConfig(authService.apiService);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    final screens = [
      const DashboardScreen(),
      const GeneralConfigScreen(),
      const ChannelsConfigScreen(),
      const RolesConfigScreen(),
      const MemeConfigScreen(),
      const DailyMemeConfigScreen(),
      const DailyMemePreferencesScreen(),
      const RocketLeagueConfigScreen(),
      const WelcomeConfigScreen(),
      const TestScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(_isDrawerExpanded ? Icons.menu_open : Icons.menu),
          tooltip: _isDrawerExpanded ? 'Collapse Menu' : 'Expand Menu',
          onPressed: () {
            setState(() {
              _isDrawerExpanded = !_isDrawerExpanded;
            });
          },
        ),
        title: const Text('HazeBot Admin'),
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
            },
          ),
        ],
      ),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isDrawerExpanded ? null : 72,
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              extended: _isDrawerExpanded,
              labelType: _isDrawerExpanded 
                  ? NavigationRailLabelType.none 
                  : NavigationRailLabelType.all,
              destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('General'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.tag),
                label: Text('Channels'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Roles'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.image),
                label: Text('Memes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.schedule),
                label: Text('Daily Meme'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.tune),
                label: Text('Meme Prefs'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.sports_esports),
                label: Text('Rocket League'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.waving_hand),
                label: Text('Welcome'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.science),
                label: Text('Test'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigService>(
      builder: (context, configService, _) {
        if (configService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final config = configService.config;
        if (config == null) {
          return const Center(
            child: Text('Failed to load configuration'),
          );
        }

        // Calculate meme sources count
        final subredditCount = (config['meme']?['subreddits'] as List?)?.length ?? 0;
        final lemmyCount = (config['meme']?['lemmy_communities'] as List?)?.length ?? 0;
        final totalMemeSources = subredditCount + lemmyCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive grid: 1 column for narrow, 2 for medium, 3 for wide
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 600) crossAxisCount = 2;
                  if (constraints.maxWidth > 900) crossAxisCount = 3;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.5, // Wider cards for better text display
                    children: [
                      _DashboardCard(
                        title: 'Bot Name',
                        value: config['general']?['bot_name'] ?? 'N/A',
                        icon: Icons.smart_toy,
                        color: Colors.blue,
                      ),
                      _DashboardCard(
                        title: 'Mode',
                        value: config['general']?['prod_mode'] == true ? 'Production' : 'Test',
                        icon: Icons.flag,
                        color: config['general']?['prod_mode'] == true 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      _DashboardCard(
                        title: 'Command Prefix',
                        value: config['general']?['command_prefix'] ?? 'N/A',
                        icon: Icons.terminal,
                        color: Colors.purple,
                      ),
                      _DashboardCard(
                        title: 'Discord Server',
                        value: config['discord_ids']?['guild_name']?.toString() ?? 
                                config['discord_ids']?['guild_id']?.toString() ?? 'N/A',
                        icon: Icons.discord,
                        color: Colors.teal,
                      ),
                      _DashboardCard(
                        title: 'Meme Sources',
                        value: '$subredditCount subreddits + $lemmyCount lemmy',
                        subtitle: 'Total: $totalMemeSources',
                        icon: Icons.image,
                        color: Colors.pink,
                      ),
                      _DashboardCard(
                        title: 'RL Check Interval',
                        value: '${config['rocket_league']?['rank_check_interval_hours'] ?? 'N/A'}h',
                        icon: Icons.sports_esports,
                        color: Colors.indigo,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, 
                               color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Configuration Info',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Use the navigation menu on the left to configure different aspects of the HazeBot. '
                        'All changes are saved automatically to the bot configuration.',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• General: Bot name, command prefix, cooldowns, and thresholds',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Text(
                        '• Channels: Discord channel IDs for different features',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Text(
                        '• Roles: Discord role IDs for permissions and features',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Text(
                        '• Memes: Subreddits, Lemmy communities, and meme sources',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Text(
                        '• Rocket League: Rank checking intervals and cache settings',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Text(
                        '• Welcome: Rules text and welcome messages',
                        style: TextStyle(fontWeight: FontWeight.w500),
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

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
