import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/discord_auth_service.dart';

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _sessionsData;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadSessions();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    try {
      final authService = context.read<DiscordAuthService>();
      final apiService = authService.apiService;

      // Call the admin endpoint using the base URL
      final response = await apiService.getActiveSessions();

      setState(() {
        _sessionsData = response;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s ago';
    if (seconds < 3600) return '${(seconds / 60).floor()}m ago';
    if (seconds < 86400) return '${(seconds / 3600).floor()}h ago';
    return '${(seconds / 86400).floor()}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Sessions'),
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(_errorMessage!,
                          style: TextStyle(color: colorScheme.error)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadSessions,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildSessionsList(),
    );
  }

  Widget _buildSessionsList() {
    final sessions = (_sessionsData?['sessions'] as List?) ?? [];
    final totalActive = _sessionsData?['total_active'] ?? 0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Card
          Card(
            elevation: 0,
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalActive Active Users',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Currently using the app',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sessions List
          ...sessions
              .map((session) => _buildSessionCard(session, theme, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
      Map<String, dynamic> session, ThemeData theme, ColorScheme colorScheme) {
    final username = session['username'] ?? 'Unknown';
    final role = session['role'] ?? 'unknown';
    final lastSeen = session['seconds_ago'] ?? 0;
    final ip = session['ip'] ?? 'Unknown';
    final userAgent = session['user_agent'] ?? 'Unknown';
    final appVersion = session['app_version'] ?? 'Unknown';
    final platform = session['platform'] ?? 'Unknown';
    final lastEndpoint = session['last_endpoint'] ?? 'unknown';

    // Role color
    Color roleColor;
    switch (role.toLowerCase()) {
      case 'admin':
        roleColor = Colors.red;
        break;
      case 'moderator':
        roleColor = Colors.orange;
        break;
      default:
        roleColor = Colors.grey;
    }

    // Platform icon
    IconData platformIcon;
    switch (platform.toLowerCase()) {
      case 'android':
        platformIcon = Icons.android;
        break;
      case 'ios':
        platformIcon = Icons.apple;
        break;
      case 'web':
        platformIcon = Icons.language;
        break;
      case 'windows':
        platformIcon = Icons.desktop_windows;
        break;
      default:
        platformIcon = Icons.devices;
    }

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(
                  Icons.account_circle,
                  size: 40,
                  color: roleColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        role.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(platformIcon,
                            size: 16, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          platform,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatDuration(lastSeen),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Info Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                      Icons.phone_android, 'Version', appVersion, theme),
                  const Divider(height: 16),
                  _buildInfoRow(Icons.router, 'IP', ip, theme),
                  const Divider(height: 16),
                  _buildInfoRow(
                      Icons.api, 'Last Endpoint', lastEndpoint, theme),
                  const Divider(height: 16),
                  _buildInfoRow(
                    Icons.devices,
                    'User Agent',
                    userAgent.length > 50
                        ? '${userAgent.substring(0, 50)}...'
                        : userAgent,
                    theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
