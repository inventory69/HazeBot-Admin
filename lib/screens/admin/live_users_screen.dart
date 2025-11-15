import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class LiveUsersScreen extends StatefulWidget {
  const LiveUsersScreen({super.key});

  @override
  State<LiveUsersScreen> createState() => _LiveUsersScreenState();
}

class _LiveUsersScreenState extends State<LiveUsersScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _sessionData;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadActiveSessions();
    // Auto-refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadActiveSessions(silent: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload data when app comes back to foreground
    if (state == AppLifecycleState.resumed && mounted) {
      _loadActiveSessions(silent: true);
    }
  }

  Future<void> _loadActiveSessions(
      {bool silent = false, int retryCount = 0}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.apiService.getActiveSessions();

      if (mounted) {
        setState(() {
          _sessionData = response;
          _isLoading = false;
          _errorMessage = null; // Clear any previous errors on success
        });
      }
    } catch (e) {
      // Check if it's a network/DNS error that might be temporary
      final errorStr = e.toString().toLowerCase();
      final isNetworkError = errorStr.contains('socketexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('connection');

      if (isNetworkError && retryCount < 2 && mounted) {
        // Automatic retry for network errors (max 2 retries)
        await Future.delayed(Duration(seconds: 1 + retryCount));
        if (mounted) {
          return _loadActiveSessions(
              silent: silent, retryCount: retryCount + 1);
        }
      }

      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load active sessions: $e';
          _isLoading = false;
        });
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
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

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'mod':
        return Icons.shield;
      case 'lootling':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  String _getDeviceType(String userAgent) {
    final ua = userAgent.toLowerCase();

    // Check for mobile patterns (including Flutter/Dart on mobile)
    if (ua.contains('mobile') ||
        ua.contains('android') ||
        ua.contains('iphone') ||
        ua.contains('ios') ||
        // Flutter on Android typically has "Dart" in user agent
        (ua.contains('dart') &&
            (ua.contains('android') || ua.contains('linux'))) ||
        // Check for Flutter specific patterns
        (ua.contains('flutter') && !ua.contains('web'))) {
      return 'Mobile';
    } else if (ua.contains('tablet') || ua.contains('ipad')) {
      return 'Tablet';
    } else if (ua.contains('dart') || ua.contains('flutter')) {
      // If it's Dart/Flutter but not detected as mobile, check for web
      return 'Web';
    } else {
      return 'Desktop';
    }
  }

  IconData _getDeviceIcon(String userAgent) {
    final deviceType = _getDeviceType(userAgent);
    switch (deviceType) {
      case 'Mobile':
        return Icons.phone_android;
      case 'Tablet':
        return Icons.tablet;
      case 'Web':
        return Icons.web;
      default:
        return Icons.computer;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _sessionData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      // Determine if it's a network error
      final errorStr = _errorMessage!.toLowerCase();
      final isNetworkError = errorStr.contains('socketexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('connection');

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isNetworkError ? Icons.wifi_off : Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                isNetworkError ? 'Connection Issue' : 'Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isNetworkError
                    ? 'Could not connect to the server. This usually happens when the app was in the background.'
                    : 'Failed to load active sessions.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadActiveSessions(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sessions = _sessionData?['sessions'] as List? ?? [];
    final totalActive = _sessionData?['total_active'] ?? 0;
    final checkedAt = _sessionData?['checked_at'] as String?;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 12.0 : 24.0;

        return RefreshIndicator(
          onRefresh: () => _loadActiveSessions(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.people,
                            size: isMobile ? 28 : 32,
                            color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live Users',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 24 : null,
                                    ),
                              ),
                              Text(
                                'Active API sessions in real-time',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: isMobile ? 13 : null,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (!isMobile)
                          IconButton.filled(
                            onPressed: () => _loadActiveSessions(),
                            icon: _isLoading && _sessionData != null
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            tooltip: 'Refresh',
                          ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 12 : 20),

                    // Stats Card
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.online_prediction,
                                size: isMobile ? 32 : 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$totalActive',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                          fontSize: isMobile ? 32 : null,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                  Text(
                                    totalActive == 1
                                        ? 'Active User'
                                        : 'Active Users',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontSize: isMobile ? 14 : null,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  if (checkedAt != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Updated: ${timeago.format(DateTime.parse(checkedAt))}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontSize: isMobile ? 11 : null,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.7),
                                          ),
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

                    // Sessions List Header
                    Text(
                      'Active Sessions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: isMobile ? 18 : null,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: isMobile ? 8 : 12),

                    // Sessions List
                    if (sessions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(Icons.person_off,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                              const SizedBox(height: 16),
                              Text(
                                'No active users',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Users will appear here when they use the API',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              final username = session['username'] ?? 'Unknown';
                              final role = session['role'] ?? 'unknown';
                              final discordId =
                                  session['discord_id'] ?? 'Unknown';
                              final lastSeen = session['last_seen'] as String?;
                              final secondsAgo = session['seconds_ago'] ?? 0;
                              final ip = session['ip'] ?? 'Unknown';
                              final userAgent =
                                  session['user_agent'] ?? 'Unknown';
                              final lastEndpoint =
                                  session['last_endpoint'] ?? 'unknown';

                              final isRecent = secondsAgo < 30;

                              return Card(
                                margin:
                                    EdgeInsets.only(bottom: isMobile ? 8 : 12),
                                child: ExpansionTile(
                                  leading: Stack(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: _getRoleColor(role)
                                            .withValues(alpha: 0.2),
                                        child: Icon(
                                          _getRoleIcon(role),
                                          color: _getRoleColor(role),
                                          size: isMobile ? 20 : 24,
                                        ),
                                      ),
                                      if (isRecent)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 14 : null,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getRoleColor(role)
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              role.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: isMobile ? 10 : 11,
                                                fontWeight: FontWeight.bold,
                                                color: _getRoleColor(role),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            _getDeviceIcon(userAgent),
                                            size: isMobile ? 14 : 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getDeviceType(userAgent),
                                            style: TextStyle(
                                              fontSize: isMobile ? 11 : 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (lastSeen != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: isMobile ? 14 : 16,
                                              color: isRecent
                                                  ? Colors.green
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              timeago.format(
                                                  DateTime.parse(lastSeen)),
                                              style: TextStyle(
                                                fontSize: isMobile ? 11 : 12,
                                                color: isRecent
                                                    ? Colors.green
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(
                                          isMobile ? 12.0 : 16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildDetailRow(
                                            context,
                                            Icons.fingerprint,
                                            'Discord ID',
                                            discordId,
                                            isMobile,
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDetailRow(
                                            context,
                                            Icons.location_on,
                                            'IP Address',
                                            ip,
                                            isMobile,
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDetailRow(
                                            context,
                                            Icons.api,
                                            'Last Endpoint',
                                            lastEndpoint.replaceAll('_', ' '),
                                            isMobile,
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDetailRow(
                                            context,
                                            Icons.devices,
                                            'User Agent',
                                            userAgent.length > 50
                                                ? '${userAgent.substring(0, 50)}...'
                                                : userAgent,
                                            isMobile,
                                            monospace: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          SizedBox(height: isMobile ? 16 : 24),
                          // Recent Activity placed under Active Sessions
                          _buildRecentActivity(isMobile),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(bool isMobile) {
    final recentActivity =
        _sessionData?['recent_activity'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: isMobile ? 18 : null,
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        if (recentActivity.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: isMobile ? 32 : 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: isMobile ? 4 : 6),
                    Text(
                      'Activity will appear here as users interact with the API',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
                  recentActivity.length > 20 ? 20 : recentActivity.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final activity = recentActivity[index];
                final username = activity['username'] ?? 'Unknown';
                final displayName = activity['display_name'] ?? username;
                final avatarUrl = activity['avatar_url'] as String?;
                final action = activity['action'] ?? 'GET';
                final endpoint = activity['endpoint'] ?? 'unknown';
                final timestamp = activity['timestamp'] as String?;

                return ListTile(
                  dense: isMobile,
                  leading: CircleAvatar(
                    radius: isMobile ? 16 : 20,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Icon(Icons.person, size: isMobile ? 16 : 20)
                        : null,
                  ),
                  title: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getActionColor(action).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          action,
                          style: TextStyle(
                            fontSize: isMobile ? 9 : 10,
                            fontWeight: FontWeight.bold,
                            color: _getActionColor(action),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatEndpoint(endpoint),
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: timestamp != null
                      ? Text(
                          timeago.format(DateTime.parse(timestamp)),
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
      ],
    );
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
      case 'PATCH':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatEndpoint(String endpoint) {
    // Remove common prefixes and make more readable
    return endpoint
        .replaceAll('_', ' ')
        .replaceAll('get ', '')
        .replaceAll('post ', '')
        .replaceAll('update ', '')
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isMobile, {
    bool monospace = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isMobile ? 16 : 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontFamily: monospace ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
