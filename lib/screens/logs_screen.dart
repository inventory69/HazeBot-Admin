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
    _loadLogs();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
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
          _logs = _logs.reversed.toList(); // Neueste zuerst
          _availableCogs = List<String>.from(result['available_cogs'] ?? []);
        });
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

  String _getLevelEmoji(String level) {
    switch (level.toUpperCase()) {
      case 'DEBUG':
        return '🔧';
      case 'INFO':
        return 'ℹ️';
      case 'WARNING':
        return '⚠️';
      case 'ERROR':
        return '❌';
      default:
        return '📝';
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level.toUpperCase()) {
      case 'DEBUG':
        return Icons.bug_report;
      case 'INFO':
        return Icons.info_outline;
      case 'WARNING':
        return Icons.warning_amber;
      case 'ERROR':
        return Icons.error_outline;
      default:
        return Icons.description;
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

  String _extractCogName(String message) {
    final match = RegExp(r'\[([^\]]+)\]').firstMatch(message);
    return match?.group(1) ?? '';
  }

  Color? _getCogColor(String cogName) {
    if (cogName.isEmpty) return null;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.cyan,
      Colors.amber,
    ];
    final index = cogName.hashCode % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    // Monet/normal mode card color logic (match other config screens)
    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh != ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;

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
                                  DropdownMenuItem(value: 100, child: Text('100')),
                                  DropdownMenuItem(value: 250, child: Text('250')),
                                  DropdownMenuItem(value: 500, child: Text('500')),
                                  DropdownMenuItem(value: 1000, child: Text('1000')),
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
                                      setState(() => _searchQuery = _searchController.text);
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
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                final level = log['level'] ?? 'INFO';
                                final timestamp = log['timestamp'] ?? '';
                                final message = log['message'] ?? '';
                                final fullLogText = '[$timestamp] $level | $message';
                                final cogName = _extractCogName(message);
                                final cogColor = _getCogColor(cogName);

                                return InkWell(
                                  onLongPress: () {
                                    Clipboard.setData(ClipboardData(text: fullLogText));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Log entry copied'),
                                        duration: Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                        width: 200,
                                      ),
                                    );
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    color: cardColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: cardPadding, vertical: cardPadding * 0.75),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Emoji + Icon
                                          Container(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(_getLevelEmoji(level), style: const TextStyle(fontSize: 16)),
                                                const SizedBox(width: 4),
                                                Icon(_getLevelIcon(level), color: _getLevelTextColor(level), size: 16),
                                              ],
                                            ),
                                          ),
                                          // Content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Level badge + Timestamp
                                                Wrap(
                                                  spacing: 8,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).colorScheme.primaryContainer,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        level.toUpperCase(),
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                                                    color: cogColor ?? Theme.of(context).textTheme.bodyMedium?.color,
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
                                              Clipboard.setData(ClipboardData(text: fullLogText));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Log entry copied'),
                                                  duration: Duration(seconds: 1),
                                                  behavior: SnackBarBehavior.floating,
                                                  width: 200,
                                                ),
                                              );
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
                      Icon(Icons.description, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${_logs.length} logs',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      if (_autoRefresh)
                        Row(
                          children: [
                            Icon(Icons.autorenew, size: 16, color: Colors.green[600]),
                            const SizedBox(width: 4),
                            Text('Auto-refresh: 5s', style: TextStyle(fontSize: 12, color: Colors.green[600])),
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
