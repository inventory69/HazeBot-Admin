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

class _LiveUsersScreenState extends State<LiveUsersScreen> {
  Map<String, dynamic>? _sessionData;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
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
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveSessions({bool silent = false}) async {
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
        });
      }
    } catch (e) {
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
    if (userAgent.toLowerCase().contains('mobile') ||
        userAgent.toLowerCase().contains('android') ||
        userAgent.toLowerCase().contains('iphone')) {
      return 'Mobile';
    } else if (userAgent.toLowerCase().contains('tablet') ||
        userAgent.toLowerCase().contains('ipad')) {
      return 'Tablet';
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadActiveSessions,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
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
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final username = session['username'] ?? 'Unknown';
                      final role = session['role'] ?? 'unknown';
                      final discordId = session['discord_id'] ?? 'Unknown';
                      final lastSeen = session['last_seen'] as String?;
                      final secondsAgo = session['seconds_ago'] ?? 0;
                      final ip = session['ip'] ?? 'Unknown';
                      final userAgent = session['user_agent'] ?? 'Unknown';
                      final lastEndpoint =
                          session['last_endpoint'] ?? 'unknown';

                      final isRecent = secondsAgo < 30;

                      return Card(
                        margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                        child: ExpansionTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    _getRoleColor(role).withValues(alpha: 0.2),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      borderRadius: BorderRadius.circular(12),
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
                                      timeago.format(DateTime.parse(lastSeen)),
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
                              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
              ],
            ),
          ),
        );
      },
    );
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
