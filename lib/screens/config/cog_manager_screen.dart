import 'package:flutter/material.dart';
import 'package:hazebot_admin/services/api_service.dart';
import 'package:hazebot_admin/models/cog.dart' show Cog, CogAction;
import 'package:hazebot_admin/widgets/cog_card.dart';

class CogManagerScreen extends StatefulWidget {
  const CogManagerScreen({super.key});

  @override
  State<CogManagerScreen> createState() => _CogManagerScreenState();
}

class _CogManagerScreenState extends State<CogManagerScreen> {
  List<Cog> _cogs = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    // Don't call _loadCogs here - context is not available yet
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now context is available, we can load cogs
    if (_isLoading && _error == null && _cogs.isEmpty) {
      _loadCogs();
    }
  }

  Future<void> _loadCogs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final cogs = await ApiService().getCogs();

      setState(() {
        _cogs = cogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _performCogAction(String cogName, CogAction action) async {
    // Show loading snackbar for long-running operations
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text('${action.name.substring(0, 1).toUpperCase()}${action.name.substring(1)}ing "$cogName"...'),
          ],
        ),
        duration: const Duration(seconds: 30), // Long duration for reload
        backgroundColor: Colors.blue,
      ),
    );

    try {
      switch (action) {
        case CogAction.load:
          await ApiService().loadCog(cogName);
          break;
        case CogAction.unload:
          await ApiService().unloadCog(cogName);
          break;
        case CogAction.reload:
          await ApiService().reloadCog(cogName);
          break;
      }

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Only reload cog list for load/unload actions (not reload to preserve scroll position)
      if (action != CogAction.reload) {
        await _loadCogs();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cog "$cogName" ${action.name}ed successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${action.name} cog "$cogName": $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showCogLogs(String cogName) async {
    try {
      final logs = await ApiService().getCogLogs(cogName);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Logs for $cogName'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: logs.isEmpty
                  ? const Center(child: Text('No logs found'))
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            log.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getLogLevelColor(log.level),
                            ),
                          ),
                          subtitle: Text(
                            '${log.timestamp} - ${log.level}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load logs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getLogLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'INFO':
        return Colors.blue;
      case 'DEBUG':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  void _scrollToCategory(String category) {
    final key = _categoryKeys[category];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  Widget _buildCategoryFilter(bool isMobile) {
    // Get unique categories from cogs
    final categories = <String, int>{};
    for (var cog in _cogs) {
      final category = cog.category ?? 'other';
      categories[category] = (categories[category] ?? 0) + 1;
    }

    // Sort by category order
    final categoryOrder = [
      'core', 'community', 'content', 'gaming', 'moderation', 
      'support', 'user', 'info', 'productivity', 'utility', 
      'notifications', 'monitoring', 'other'
    ];
    final sortedCategories = categories.keys.toList()
      ..sort((a, b) {
        final aIndex = categoryOrder.indexOf(a);
        final bIndex = categoryOrder.indexOf(b);
        if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Jump',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedCategories.map((category) {
              final count = categories[category]!;
              final isSelected = _selectedCategory == category;
              
              return FilterChip(
                label: Text(
                  '$category ($count)',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                  });
                  if (selected) {
                    _scrollToCategory(category);
                  }
                },
                showCheckmark: false,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 4 : 6,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCogsByCategory(bool isMobile) {
    // Group cogs by category
    final cogsByCategory = <String, List<Cog>>{};
    for (var cog in _cogs) {
      final category = cog.category ?? 'other';
      cogsByCategory.putIfAbsent(category, () => []).add(cog);
    }

    // Sort categories
    final categoryOrder = [
      'core', 'community', 'content', 'gaming', 'moderation', 
      'support', 'user', 'info', 'productivity', 'utility', 
      'notifications', 'monitoring', 'other'
    ];
    final sortedCategories = cogsByCategory.keys.toList()
      ..sort((a, b) {
        final aIndex = categoryOrder.indexOf(a);
        final bIndex = categoryOrder.indexOf(b);
        if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });

    // Build widgets
    final widgets = <Widget>[];
    for (var category in sortedCategories) {
      final cogs = cogsByCategory[category]!;
      
      // Create or get key for this category
      _categoryKeys.putIfAbsent(category, () => GlobalKey());
      
      // Category header
      widgets.add(
        Container(
          key: _categoryKeys[category],
          margin: EdgeInsets.only(
            top: isMobile ? 8 : 16,
            bottom: isMobile ? 8 : 12,
          ),
          child: Text(
            category.toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.2,
              fontSize: isMobile ? 11 : 12,
            ),
          ),
        ),
      );

      // Cogs in this category
      for (var cog in cogs) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
            child: CogCard(
              cog: cog,
              isMobile: isMobile,
              onLoad: cog.canLoad ? () => _performCogAction(
                  cog.name, CogAction.load) : null,
              onUnload: cog.canUnload ? () => _performCogAction(
                  cog.name, CogAction.unload) : null,
              onReload: cog.canReload ? () => _performCogAction(
                  cog.name, CogAction.reload) : null,
              onShowLogs: () => _showCogLogs(cog.name),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 12.0 : 24.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cog Manager'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadCogs,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error,
                                size: isMobile ? 48 : 64, color: Colors.red),
                            SizedBox(height: isMobile ? 12 : 16),
                            Text(
                              'Error loading cogs',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: isMobile ? 18 : null),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isMobile ? 13 : null,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isMobile ? 16 : 24),
                            ElevatedButton.icon(
                              onPressed: _loadCogs,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _cogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.extension_off,
                                  size: isMobile ? 48 : 64,
                                  color: Colors.grey),
                              SizedBox(height: isMobile ? 12 : 16),
                              Text(
                                'No cogs found',
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCogs,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: EdgeInsets.all(padding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bot Cogs',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontSize: isMobile ? 24 : null,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Manage bot modules and extensions',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                        fontSize: isMobile ? 13 : null,
                                      ),
                                ),
                                SizedBox(height: isMobile ? 16 : 24),
                                _buildCategoryFilter(isMobile),
                                ..._buildCogsByCategory(isMobile),
                              ],
                            ),
                          ),
                        ),
        );
      },
    );
  }
}