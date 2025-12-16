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
  int _limit = 100; // Optimiert: 100 statt 500 für bessere Performance
  bool _autoRefresh = false;
  Timer? _refreshTimer;

  // Selection mode
  bool _isSelectionMode = false;
  Set<int> _selectedIndices = {};

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load data after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLogs();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.getLogs(
        cog: _selectedCog,
        level: _selectedLevel,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        limit: _limit,
      );

      if (mounted) {
        setState(() {
          _logs = List<Map<String, dynamic>>.from(result['logs'] ?? []);
          _availableCogs = List<String>.from(result['available_cogs'] ?? []);
          debugPrint(
              'Available cogs loaded: $_availableCogs (${_availableCogs.length} cogs)');
        });
        // No need to scroll! ListView with reverse: true starts at bottom automatically
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading logs: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
      if (_autoRefresh) {
        _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
          // Merke alte Länge und Scroll-Position
          final oldLength = _logs.length;
          final wasAtBottom = _scrollController.hasClients
              ? _scrollController.position.pixels >=
                  _scrollController.position.maxScrollExtent - 100
              : false;

          await _loadLogs();

          // Nur auto-scrollen wenn User bereits unten war UND neue Logs gekommen sind
          if (wasAtBottom &&
              _logs.length > oldLength &&
              _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
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

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _enterSelectionMode(int index) {
    setState(() {
      _isSelectionMode = true;
      _selectedIndices.add(index);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIndices.clear();
    });
  }

  void _copySelectedLogs() {
    final selectedLogs = _selectedIndices.map((index) {
      final log = _logs[index];
      final level = log['level'] ?? 'INFO';
      final timestamp = log['timestamp'] ?? '';
      final message = log['message'] ?? '';
      return '[$timestamp] $level | $message';
    }).join('\n');

    Clipboard.setData(ClipboardData(text: selectedLogs));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedIndices.length} log entries copied'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _exitSelectionMode();
  }

  void _selectAll() {
    setState(() {
      _selectedIndices = Set.from(List.generate(_logs.length, (i) => i));
    });
  }

  // Better emoji matching Logger.py styling
  String _getLevelEmoji(String level) {
    switch (level.toUpperCase()) {
      case 'DEBUG':
        return '�';
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

  Color _getLevelTextColor(String level) {
    switch (level.toUpperCase()) {
      case 'DEBUG':
        return Colors.grey;
      case 'INFO':
        return Colors.blue;
      case 'WARNING':
        return Colors.orange;
      case 'ERROR':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Extract cog name from message (matching Config.py COG_PREFIXES)
  String? _extractCogName(String message) {
    // Check for cog prefixes in the message (from Config.py)
    final cogPrefixes = {
      '[CogManager]': 'CogManager',
      '[Changelog]': 'Changelog',
      '[DailyMeme]': 'DailyMeme',
      '[DiscordLogging]': 'DiscordLogging',
      '[GamingHub]': 'GamingHub',
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
      case 'GamingHub':
        return Colors.deepPurple.shade400; // Deep purple for gaming
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Monet/normal mode card color logic (match other config screens)
    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedIndices.length} selected')
            : const Text('Bot Logs'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
                tooltip: 'Cancel selection',
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _selectAll,
                  tooltip: 'Select all',
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed:
                      _selectedIndices.isEmpty ? null : _copySelectedLogs,
                  tooltip: 'Copy selected',
                ),
              ]
            : [
                IconButton(
                  icon: Icon(_autoRefresh ? Icons.pause : Icons.play_arrow),
                  onPressed: _toggleAutoRefresh,
                  tooltip: _autoRefresh
                      ? 'Pause auto-refresh'
                      : 'Start auto-refresh',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadLogs,
                  tooltip: 'Refresh',
                ),
              ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final padding = isMobile ? 12.0 : 16.0;
          final cardPadding = isMobile ? 12.0 : 16.0;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                // Filters Card
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              width: 200,
                              child: DropdownButtonFormField<String>(
                                value: _selectedCog,
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
                            SizedBox(
                              width: 150,
                              child: DropdownButtonFormField<String>(
                                value: _selectedLevel,
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
                            SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<int>(
                                value: _limit,
                                decoration: const InputDecoration(
                                  labelText: 'Limit',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 50, child: Text('50 logs')),
                                  DropdownMenuItem(
                                      value: 100, child: Text('100 logs')),
                                  DropdownMenuItem(
                                      value: 200, child: Text('200 logs')),
                                  DropdownMenuItem(
                                      value: 500, child: Text('500 logs')),
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
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search in messages',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _clearFilters,
                                    tooltip: 'Clear filters',
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: () {
                                      setState(() => _searchQuery =
                                          _searchController.text);
                                      _loadLogs();
                                    },
                                    tooltip: 'Search',
                                  ),
                          ),
                          onSubmitted: (value) {
                            setState(() => _searchQuery = value);
                            _loadLogs();
                          },
                          onChanged: (value) {
                            setState(() {});
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
                          ? const Center(child: Text('No logs found'))
                          : ListView.builder(
                              controller: _scrollController,
                              reverse: true, // Start at bottom (newest logs)
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                // Reverse index to show newest logs at bottom
                                final reversedIndex = _logs.length - 1 - index;
                                final log = _logs[reversedIndex];
                                final level = log['level'] ?? 'INFO';
                                final timestamp = log['timestamp'] ?? '';
                                final message = log['message'] ?? '';
                                final fullLogText =
                                    '[$timestamp] $level | $message';
                                final cogName = _extractCogName(message);
                                final cogColor = _getCogColor(cogName);
                                final isSelected =
                                    _selectedIndices.contains(reversedIndex);

                                return InkWell(
                                  onTap: _isSelectionMode
                                      ? () => _toggleSelection(reversedIndex)
                                      : null,
                                  onLongPress: () {
                                    if (_isSelectionMode) {
                                      _toggleSelection(reversedIndex);
                                    } else {
                                      _enterSelectionMode(reversedIndex);
                                    }
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withOpacity(0.5)
                                        : cardColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: isSelected
                                          ? BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              width: 2,
                                            )
                                          : BorderSide.none,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: cardPadding,
                                          vertical: cardPadding * 0.75),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Selection checkbox
                                          if (_isSelectionMode)
                                            Container(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
                                              child: Checkbox(
                                                value: isSelected,
                                                onChanged: (_) =>
                                                    _toggleSelection(
                                                        reversedIndex),
                                              ),
                                            ),
                                          // Emoji + Icon
                                          Container(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(_getLevelEmoji(level),
                                                    style: const TextStyle(
                                                        fontSize: 16)),
                                                const SizedBox(width: 4),
                                                Icon(_getLevelIcon(level),
                                                    color: _getLevelTextColor(
                                                        level),
                                                    size: 16),
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
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _getLevelBadgeColor(
                                                                level),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(3),
                                                      ),
                                                      child: Text(
                                                        level.toUpperCase(),
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                          fontFamily:
                                                              'monospace',
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
                                          // Copy button (only show when not in selection mode)
                                          if (!_isSelectionMode)
                                            IconButton(
                                              icon: const Icon(Icons.copy,
                                                  size: 16),
                                              color: Colors.grey,
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(
                                                    text: fullLogText));
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Log entry copied'),
                                                    duration:
                                                        Duration(seconds: 1),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    width: 200,
                                                  ),
                                                );
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                  minWidth: 32, minHeight: 32),
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

                // Footer
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Row(
                    children: [
                      Icon(Icons.description,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${_logs.length} logs',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      if (_autoRefresh)
                        Row(
                          children: [
                            Icon(Icons.autorenew,
                                size: 16, color: Colors.green[600]),
                            const SizedBox(width: 4),
                            Text('Auto-refresh: 5s',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.green[600])),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
