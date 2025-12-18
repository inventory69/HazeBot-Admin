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
    // 📊 ANALYTICS FIX: Auto-refresh every 30 seconds (reduced from 5s)
    // This reduces polling spam from 720 calls/hour to 120 calls/hour (83% reduction)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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
    } else if (ua.contains('dart') ||
        ua.contains('flutter') ||
        ua.contains('testventory') ||
        ua.contains('chillventory')) {
      // If it's Dart/Flutter/our app, it's Web (unless already detected as mobile/tablet)
      return 'Web';
    } else if (ua.contains('mozilla') ||
        ua.contains('chrome') ||
        ua.contains('safari') ||
        ua.contains('firefox') ||
        ua.contains('edge')) {
      // Browser user agents
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
    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;
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
                      color: cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
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
                                      'Updated: ${timeago.format(DateTime.parse(checkedAt).toLocal())}',
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
                              final userAgent =
                                  session['user_agent'] ?? 'Unknown';
                              final lastEndpoint =
                                  session['last_endpoint'] ?? 'unknown';
                              final appVersion =
                                  session['app_version'] ?? 'Unknown';
                              final platform = session['platform'] ?? 'Unknown';
                              final deviceInfo =
                                  session['device_info'] ?? 'Unknown';

                              // Monitor detection (Uptime Kuma)
                              final isMonitor = session['is_monitor'] ?? false;
                              final monitorType = session['monitor_type'] ?? '';
                              final monitorStatus =
                                  session['monitor_status'] ?? '';

                              // Emulator detection
                              final isEmulator =
                                  session['is_emulator'] ?? false;

                              final isRecent = secondsAgo < 30;

                              return Card(
                                margin:
                                    EdgeInsets.only(bottom: isMobile ? 8 : 12),
                                color: cardColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    dividerColor: Colors.transparent,
                                  ),
                                  child: ExpansionTile(
                                    leading: Stack(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: isMonitor
                                              ? Colors.blue
                                                  .withValues(alpha: 0.2)
                                              : _getRoleColor(role)
                                                  .withValues(alpha: 0.2),
                                          child: Icon(
                                            isMonitor
                                                ? Icons.monitor_heart
                                                : _getRoleIcon(role),
                                            color: isMonitor
                                                ? Colors.blue
                                                : _getRoleColor(role),
                                            size: isMobile ? 20 : 24,
                                          ),
                                        ),
                                        if (isRecent && !isMonitor)
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
                                        if (isMonitor)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: monitorStatus == 'up'
                                                    ? Colors.green
                                                    : monitorStatus == 'down'
                                                        ? Colors.red
                                                        : Colors.orange,
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
                                            if (isMonitor) ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.monitor_heart,
                                                      size: isMobile ? 12 : 14,
                                                      color: Colors.blue,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      monitorType.toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize:
                                                            isMobile ? 10 : 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ] else ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _getRoleColor(role)
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  role.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize:
                                                        isMobile ? 10 : 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getRoleColor(role),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            if (!isMonitor) ...[
                                              Icon(
                                                isEmulator
                                                    ? Icons.laptop_chromebook
                                                    : _getDeviceIcon(userAgent),
                                                size: isMobile ? 14 : 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isEmulator
                                                    ? 'Emulator'
                                                    : _getDeviceType(userAgent),
                                                style: TextStyle(
                                                  fontSize: isMobile ? 11 : 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
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
                                                    DateTime.parse(lastSeen)
                                                        .toLocal()),
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
                                            if (isMonitor) ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.blue
                                                        .withValues(alpha: 0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.info_outline,
                                                      color: Colors.blue,
                                                      size: isMobile ? 18 : 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Automated monitoring system',
                                                        style: TextStyle(
                                                          fontSize: isMobile
                                                              ? 11
                                                              : 12,
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              _buildDetailRow(
                                                context,
                                                Icons.monitor_heart,
                                                'Monitor Type',
                                                monitorType,
                                                isMobile,
                                              ),
                                              const SizedBox(height: 8),
                                              _buildDetailRow(
                                                context,
                                                Icons.health_and_safety,
                                                'Status',
                                                monitorStatus.toUpperCase(),
                                                isMobile,
                                              ),
                                              const SizedBox(height: 12),
                                            ],
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
                                              Icons.api,
                                              'Last Endpoint',
                                              lastEndpoint.replaceAll('_', ' '),
                                              isMobile,
                                            ),
                                            const SizedBox(height: 8),
                                            if (!isMonitor) ...[
                                              _buildDetailRow(
                                                context,
                                                isEmulator
                                                    ? Icons.laptop_chromebook
                                                    : Icons.phone_android,
                                                'Device',
                                                isEmulator
                                                    ? '$deviceInfo (Emulator)'
                                                    : deviceInfo,
                                                isMobile,
                                              ),
                                              const SizedBox(height: 8),
                                              _buildDetailRow(
                                                context,
                                                Icons.smartphone,
                                                'App Version',
                                                '$appVersion ($platform)',
                                                isMobile,
                                              ),
                                              const SizedBox(height: 8),
                                            ],
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
    final rawActivity =
        _sessionData?['recent_activity'] as List<dynamic>? ?? [];

    // Filter out uninteresting endpoints (health checks, pings, auto-refresh)
    final recentActivity = rawActivity.where((activity) {
      final endpoint = activity['endpoint'] as String? ?? '';
      return !endpoint.contains('ping') &&
          !endpoint.contains('health') &&
          !endpoint.contains('get_active_sessions');
    }).toList();

    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;

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
            color: cardColor,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            color: cardColor,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatEndpoint(endpoint, action),
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timestamp != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          timeago.format(DateTime.parse(timestamp).toLocal()),
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Color _getActionColor(String action) {
  //   switch (action.toUpperCase()) {
  //     case 'GET':
  //       return Colors.blue;
  //     case 'POST':
  //       return Colors.green;
  //     case 'PUT':
  //     case 'PATCH':
  //       return Colors.orange;
  //     case 'DELETE':
  //       return Colors.red;
  //     default:
  //       return Colors.grey;
  //   }
  // }

  String _formatEndpoint(String endpoint, String action) {
    // Backend sends endpoint names without /api/ prefix (e.g., "community_posts.get_posts")
    // Action + Endpoint combinations for precise descriptions
    final actionKey = '${action.toUpperCase()} $endpoint';

    // Endpoint name mappings (backend format: module.function_name)
    final endpointDescriptions = {
      // Auth & User
      'auth.discord_callback': '🔐 Logged in via Discord',
      'auth.logout': '👋 Logged out',
      'auth.validate': '✓ Session validated',
      'user.me': '👤 Viewed profile',
      'user.get_stats': '📊 Checked statistics',
      'user.update': '✏️ Updated profile',
      'user.get_gaming_members': '🎮 Viewed gaming members',
      'user.get_profile': '👤 Viewed user profile',
      'user.update_profile': '✏️ Updated user profile',

      // Community Posts
      'community_posts.get_posts': '📝 Browsed community posts',
      'community_posts.create_post': '✨ Created new post',
      'community_posts.update_post': '✏️ Updated post',
      'community_posts.delete_post': '🗑️ Deleted post',
      'community_posts.get_post': '👁️ Viewed post details',
      'community_posts.toggle_like_post': '❤️ Liked post',
      'community_posts.get_post_likes': '👥 Viewed post likes',

      // Memes
      'memes.get_memes': '😂 Browsed memes',
      'memes.upload': '📤 Uploaded meme',
      'memes.vote': '👍 Voted on meme',
      'memes.delete': '🗑️ Deleted meme',
      'memes.random': '🎲 Got random meme',
      'memes.get_latest_memes': '😂 Browsed latest memes',

      // Admin
      'admin.get_users': '👥 Viewed user list',
      'admin.get_analytics': '📈 Checked analytics',
      'admin.get_live_users': '👁️ Viewed live users',
      'admin.get_active_sessions': '🔄 Refreshed live users',

      // Config
      'config.get_config': '⚙️ Viewed config',
      'config.update': '🔧 Updated config',
      'config.get_channels': '📺 Viewed channels',
      'config.get_roles': '🎭 Viewed roles',

      // Rocket League
      'rocket_league.get_profile': '🚀 Viewed RL profile',
      'rocket_league.get_stats': '📊 Checked RL stats',
      'rocket_league.get_user_rl_account': '🚀 Checked RL account',
      'rocket_league.link_account': '🔗 Linked RL account',
      'rocket_league.unlink_account': '🔓 Unlinked RL account',
      'rocket_league.refresh_stats': '🔄 Refreshed RL data',

      // Notifications
      'notifications.get_notifications': '🔔 Checked notifications',
      'notifications.mark_read': '✓ Marked notification read',
      'notifications.get_settings': '⚙️ Notification settings',

      // Tickets
      'tickets.get_tickets': '🎫 Viewed tickets',
      'tickets.create': '➕ Created ticket',
      'tickets.close': '✓ Closed ticket',

      // Cogs & Features
      'cogs.get_cogs': '🔌 Viewed bot features',
      'cogs.toggle': '🔄 Toggled feature',
      'features.get_features': '✨ Viewed features',

      // Monitoring
      'monitoring.health': '💚 Health check',
      'monitoring.metrics': '📊 Viewed metrics',

      // Data Cache
      'data_cache.get_latest_memes': '😂 Loaded memes',
      'data_cache.get_latest_rankups': '📊 Loaded rankups',
      'data_cache.get_latest_levelups': '⭐ Loaded level-ups',
      'data_cache.get_gaming_members': '🎮 Loaded gaming data',
    };

    // Try exact match first
    if (endpointDescriptions.containsKey(endpoint)) {
      return endpointDescriptions[endpoint]!;
    }

    // Try with action prefix
    if (endpointDescriptions.containsKey(actionKey)) {
      return endpointDescriptions[actionKey]!;
    }

    // Pattern matching for common variations
    if (endpoint.contains('community_posts') || endpoint.contains('posts')) {
      if (action.toUpperCase() == 'POST') return '✨ Created new post';
      if (action.toUpperCase() == 'PUT' || action.toUpperCase() == 'PATCH')
        return '✏️ Updated post';
      if (action.toUpperCase() == 'DELETE') return '🗑️ Deleted post';
      if (endpoint.contains('like')) return '❤️ Liked post';
      return '📝 Viewed community posts';
    }

    if (endpoint.contains('meme')) {
      if (endpoint.contains('upload')) return '📤 Uploaded meme';
      if (endpoint.contains('vote')) return '👍 Voted on meme';
      if (endpoint.contains('random')) return '🎲 Got random meme';
      return '😂 Browsed memes';
    }

    if (endpoint.contains('config')) {
      if (action.toUpperCase() == 'POST' || action.toUpperCase() == 'PUT')
        return '🔧 Updated config';
      return '⚙️ Viewed config';
    }

    if (endpoint.contains('admin')) {
      if (endpoint.contains('live') || endpoint.contains('session'))
        return '👁️ Viewed live users';
      if (endpoint.contains('analytics')) return '📈 Checked analytics';
      return '👥 Admin panel activity';
    }

    // Enhanced fallback: Try module-based pattern matching
    final parts = endpoint.split('.');
    if (parts.length >= 2) {
      final module = parts[0];
      final functionName = parts[1];

      // Gaming-related endpoints
      if (functionName.contains('gaming')) {
        return '🎮 ${_humanizeEndpoint(functionName)}';
      }
      // Rocket League endpoints
      else if (module == 'rocket_league' || functionName.contains('rl_')) {
        return '🚀 ${_humanizeEndpoint(functionName)}';
      }
      // User-related
      else if (module == 'user') {
        return '👤 ${_humanizeEndpoint(functionName)}';
      }
      // Data cache
      else if (module == 'data_cache') {
        return '💾 ${_humanizeEndpoint(functionName)}';
      }
      // Generic with module icon
      else {
        final icon = _getModuleIcon(module);
        return '$icon ${_humanizeEndpoint(functionName)}';
      }
    }

    // Final fallback: Format endpoint nicely
    return '📌 ${_humanizeEndpoint(endpoint)}';
  }

  /// Convert snake_case endpoint to Human Readable format
  String _humanizeEndpoint(String snakeCase) {
    String formatted = snakeCase
        .replaceAll('/api/', '')
        .replaceAll('/', ' › ')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ');

    return formatted
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Get emoji icon for module
  String _getModuleIcon(String module) {
    const moduleIcons = {
      'auth': '🔐',
      'user': '👤',
      'admin': '👑',
      'memes': '😂',
      'config': '⚙️',
      'tickets': '🎫',
      'notifications': '🔔',
      'cogs': '🔌',
      'monitoring': '📊',
      'analytics': '📈',
      'data_cache': '💾',
      'rocket_league': '🚀',
      'community_posts': '📝',
    };
    return moduleIcons[module] ?? '📌';
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
