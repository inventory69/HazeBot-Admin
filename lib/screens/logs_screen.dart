import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'dart:async';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _logs = [];
  List<String> _availableCogs = [];

  // Filters
  String? _selectedCog;
  String? _selectedLevel;
  String _searchQuery = '';
  int _limit = 500;
  bool _autoRefresh = false;
  Timer? _refreshTimer;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load data after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableCogs();
      _loadLogs();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableCogs() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final cogs = await authService.apiService.getAvailableCogs();
      setState(() {
        _availableCogs = cogs;
      });
    } catch (e) {
      // Silently fail - cogs list is optional
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.apiService.getLogs(
        cog: _selectedCog,
        level: _selectedLevel,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        // Reverse the list so newest logs are at the top
        _logs = List<Map<String, dynamic>>.from(response['logs'] ?? [])
            .reversed
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load logs: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
      if (_autoRefresh) {
        _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          _loadLogs();
        });
      } else {
        _refreshTimer?.cancel();
        _refreshTimer = null;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCog = null;
      _selectedLevel = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadLogs();
  }

  // Extract cog name from message (matching Config.py COG_PREFIXES)
  String? _extractCogName(String message) {
    // Check for cog prefixes in the message (from Config.py)
    final cogPrefixes = {
      '[CogManager]': 'CogManager',
      '[Changelog]': 'Changelog',
      '[DailyMeme]': 'DailyMeme',
      '[DiscordLogging]': 'DiscordLogging',
      '[Leaderboard]': 'Leaderboard',
      '[MemeGenerator]': 'MemeGenerator',
      '[ModPerks]': 'ModPerks',
      '[Preferences]': 'Preferences',
      '[Presence]': 'Presence',
      '[Profile]': 'Profile',
      '[RocketLeague]': 'RocketLeague',
      '[RoleInfo]': 'RoleInfo',
      '[ServerGuide]': 'ServerGuide',
      '[SupportButtons]': 'SupportButtons',
      '[TicketSystem]': 'TicketSystem',
      '[TodoList]': 'TodoList',
      '[Utility]': 'Utility',
      '[Warframe]': 'Warframe',
      '[Welcome]': 'Welcome',
    };

    for (final entry in cogPrefixes.entries) {
      if (message.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  // Get color for specific cog (matching Logger.py ThemeDict)
  Color? _getCogColor(String? cogName) {
    if (cogName == null) return null;

    switch (cogName) {
      case 'RocketLeague':
        return const Color(0xFFFFA500); // Orange (Rocket Boost color!)
      case 'DailyMeme':
        return const Color(0xFFFF69B4); // Hot Pink
      case 'TicketSystem':
      case 'SupportButtons':
        return const Color(0xFF99FF99); // Light green
      case 'DiscordLogging':
        return const Color(0xFFE0BBFF); // Purple
      case 'Welcome':
        return Colors.cyan.shade400; // Cyan
      case 'CogManager':
      case 'Utility':
        return Colors.blueGrey.shade400; // Blue-grey for utilities
      case 'Leaderboard':
        return Colors.yellow.shade700; // Gold for leaderboard
      case 'Profile':
        return Colors.lightBlue.shade400; // Light blue
      case 'Warframe':
        return Colors.teal.shade400; // Teal for Warframe
      default:
        return null;
    }
  }

  Color _getLevelBadgeColor(String level) {
    switch (level.toUpperCase()) {
      case 'DEBUG':
        return Colors.grey.shade600;
      case 'INFO':
        return Colors.pink.shade700;
      case 'WARNING':
        return Colors.orange.shade700;
      case 'ERROR':
        return Colors.red.shade700;
      case 'CRITICAL':
        return Colors.red.shade900;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getLevelTextColor(String level) {
    switch (level.toUpperCase()) {
      case 'DEBUG':
        return Colors.grey.shade600;
      case 'INFO':
        return Colors.pink.shade700;
      case 'WARNING':
        return Colors.orange.shade700;
      case 'ERROR':
        return Colors.red.shade700;
      case 'CRITICAL':
        return Colors.red.shade900;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getLevelEmoji(String level) {
    switch (level.toUpperCase()) {
      case 'DEBUG':
        return '🚨';
      case 'INFO':
        return '💖';
      case 'WARNING':
        return '🌸';
      case 'ERROR':
        return '🩷';
      case 'CRITICAL':
        return '🚨';
      default:
        return '📝';
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level.toUpperCase()) {
      case 'DEBUG':
        return Icons.bug_report;
      case 'INFO':
        return Icons.info;
      case 'WARNING':
        return Icons.warning;
      case 'ERROR':
        return Icons.error;
      case 'CRITICAL':
        return Icons.dangerous;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot Logs'),
        actions: [
          IconButton(
            icon: Icon(_autoRefresh ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleAutoRefresh,
            tooltip: _autoRefresh ? 'Pause auto-refresh' : 'Start auto-refresh',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Cog Filter
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCog,
                          decoration: const InputDecoration(
                            labelText: 'Cog',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Cogs'),
                            ),
                            ..._availableCogs.map(
                              (cog) => DropdownMenuItem(
                                value: cog,
                                child: Text(cog),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedCog = value);
                            _loadLogs();
                          },
                        ),
                      ),

                      // Level Filter
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedLevel,
                          decoration: const InputDecoration(
                            labelText: 'Level',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('All Levels'),
                            ),
                            DropdownMenuItem(
                              value: 'DEBUG',
                              child: Text('DEBUG'),
                            ),
                            DropdownMenuItem(
                              value: 'INFO',
                              child: Text('INFO'),
                            ),
                            DropdownMenuItem(
                              value: 'WARNING',
                              child: Text('WARNING'),
                            ),
                            DropdownMenuItem(
                              value: 'ERROR',
                              child: Text('ERROR'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedLevel = value);
                            _loadLogs();
                          },
                        ),
                      ),

                      // Limit
                      SizedBox(
                        width: 120,
                        child: DropdownButtonFormField<int>(
                          initialValue: _limit,
                          decoration: const InputDecoration(
                            labelText: 'Limit',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 100, child: Text('100')),
                            DropdownMenuItem(value: 500, child: Text('500')),
                            DropdownMenuItem(value: 1000, child: Text('1000')),
                            DropdownMenuItem(value: 2000, child: Text('2000')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _limit = value);
                              _loadLogs();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search in messages',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              setState(
                                  () => _searchQuery = _searchController.text);
                              _loadLogs();
                            },
                            tooltip: 'Search',
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearFilters,
                            tooltip: 'Clear filters',
                          ),
                        ],
                      ),
                    ),
                    onSubmitted: (value) {
                      setState(() => _searchQuery = value);
                      _loadLogs();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Logs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(
                        child: Text('No logs found'),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final level = log['level'] ?? 'INFO';
                          final timestamp = log['timestamp'] ?? '';
                          final message = log['message'] ?? '';
                          final fullLogText = '[$timestamp] $level | $message';

                          // Extract cog name and get color
                          final cogName = _extractCogName(message);
                          final cogColor = _getCogColor(cogName);

                          return InkWell(
                            onLongPress: () {
                              Clipboard.setData(
                                  ClipboardData(text: fullLogText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Log entry copied'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  width: 200,
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Emoji + Icon
                                    Container(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _getLevelEmoji(level),
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            _getLevelIcon(level),
                                            color: _getLevelTextColor(level),
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Level badge + Timestamp
                                          Wrap(
                                            spacing: 8,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getLevelBadgeColor(
                                                      level),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                                child: Text(
                                                  level.toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                timestamp,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Message (use cog color if available, otherwise normal)
                                          SelectableText(
                                            message,
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              color: cogColor ??
                                                  Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Copy button
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 16),
                                      color: Colors.grey,
                                      onPressed: () {
                                        Clipboard.setData(
                                            ClipboardData(text: fullLogText));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                const Text('Log entry copied'),
                                            duration:
                                                const Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                            width: 200,
                                          ),
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      tooltip: 'Copy log entry',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Status Bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  Icons.description,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '${_logs.length} logs',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (_autoRefresh)
                  Row(
                    children: [
                      Icon(
                        Icons.autorenew,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-refresh: 5s',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
