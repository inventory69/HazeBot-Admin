import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class RocketLeagueConfigScreen extends StatefulWidget {
  const RocketLeagueConfigScreen({super.key});

  @override
  State<RocketLeagueConfigScreen> createState() =>
      _RocketLeagueConfigScreenState();
}

class _RocketLeagueConfigScreenState extends State<RocketLeagueConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingAccounts = false;
  bool _isCheckingRanks = false;

  // Configuration values
  final _rankCheckIntervalController = TextEditingController();
  final _cacheTtlController = TextEditingController();

  // Linked accounts
  List<Map<String, dynamic>> _linkedAccounts = [];

  // Test stats
  final _testPlatformController = TextEditingController();
  final _testUsernameController = TextEditingController();
  Map<String, dynamic>? _testStats;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadLinkedAccounts();
  }

  @override
  void dispose() {
    _rankCheckIntervalController.dispose();
    _cacheTtlController.dispose();
    _testPlatformController.dispose();
    _testUsernameController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final config = await authService.apiService.getRocketLeagueConfig();

      if (mounted) {
        setState(() {
          _rankCheckIntervalController.text =
              config['rank_check_interval_hours'].toString();
          _cacheTtlController.text =
              config['rank_cache_ttl_seconds'].toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading configuration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLinkedAccounts() async {
    if (mounted) {
      setState(() => _isLoadingAccounts = true);
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final accounts = await authService.apiService.getRocketLeagueAccounts();

      if (mounted) {
        setState(() {
          _linkedAccounts = accounts;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading linked accounts: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAccounts = false);
      }
    }
  }

  Future<void> _deleteAccount(String userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Account?'),
        content: Text(
          'Are you sure you want to unlink the Rocket League account for $username?\n\n'
          'This will remove rank tracking for this user.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.deleteRocketLeagueAccount(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account unlinked for $username')),
        );
        await _loadLinkedAccounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unlinking account: $e')),
        );
      }
    }
  }

  Future<void> _triggerRankCheck() async {
    if (mounted) {
      setState(() => _isCheckingRanks = true);
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.triggerRankCheck();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Rank check completed'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload accounts to get updated ranks
        await _loadLinkedAccounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking ranks: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingRanks = false);
      }
    }
  }

  Future<void> _testPlayerStats() async {
    final platform = _testPlatformController.text.trim().toLowerCase();
    final username = _testUsernameController.text.trim();

    if (platform.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both platform and username')),
      );
      return;
    }

    if (!['steam', 'epic', 'psn', 'xbl', 'switch'].contains(platform)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Invalid platform. Use: steam, epic, psn, xbl, or switch')),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingStats = true;
        _testStats = null;
      });
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result =
          await authService.apiService.getRocketLeagueStats(platform, username);

      if (mounted) {
        setState(() {
          _testStats = result['stats'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching stats: $e')),
        );
        setState(() {
          _testStats = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final config = {
        'rank_check_interval_hours':
            int.parse(_rankCheckIntervalController.text),
        'rank_cache_ttl_seconds': int.parse(_cacheTtlController.text),
      };

      await authService.apiService.updateRocketLeagueConfig(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving configuration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will reset all Rocket League settings to their default values:\n\n'
          '• Rank Check Interval: 3 hours\n'
          '• Cache TTL: 10500 seconds (2h 55min)\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.resetRocketLeagueConfig();
      await _loadConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration reset to defaults'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting configuration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatSeconds(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours h $minutes min $secs s';
    } else if (minutes > 0) {
      return '$minutes min $secs s';
    } else {
      return '$secs s';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _rankCheckIntervalController.text.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Monet/normal mode card color logic (match channels/roles config screens)
    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 12.0 : 16.0;
        final cardPadding = isMobile ? 12.0 : 16.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rocket League Configuration',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: isMobile ? 24 : null,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure rank tracking and caching settings',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 13 : null,
                      ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Rank Check Settings
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.refresh,
                              color: Colors.blue,
                              size: isMobile ? 20 : 24,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Rank Check Settings',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        TextFormField(
                          controller: _rankCheckIntervalController,
                          decoration: InputDecoration(
                            labelText: 'Rank Check Interval (hours)',
                            hintText: 'How often to check for rank changes',
                            helperText:
                                'Bot will check for rank updates at this interval',
                            helperMaxLines: isMobile ? 2 : 1,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.schedule),
                            suffixText: 'hours',
                            isDense: isMobile,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field is required';
                            }
                            final intValue = int.tryParse(value);
                            if (intValue == null) {
                              return 'Must be a valid number';
                            }
                            if (intValue < 1) {
                              return 'Must be at least 1 hour';
                            }
                            if (intValue > 24) {
                              return 'Must be at most 24 hours';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: isMobile ? 18 : 20,
                                  color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This determines how often the bot checks for rank changes. '
                                  'Recommended: 3 hours for balanced updates.',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // Cache Settings
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.storage,
                              color: Colors.green,
                              size: isMobile ? 20 : 24,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Cache Settings',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        TextFormField(
                          controller: _cacheTtlController,
                          decoration: InputDecoration(
                            labelText: 'Cache TTL (seconds)',
                            hintText: 'How long to cache rank data',
                            helperText: _cacheTtlController.text.isNotEmpty
                                ? 'Duration: ${_formatSeconds(int.tryParse(_cacheTtlController.text) ?? 0)}'
                                : 'Time-to-live for cached rank data',
                            helperMaxLines: isMobile ? 2 : 1,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.timer),
                            suffixText: 'seconds',
                            isDense: isMobile,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (value) {
                            // Trigger rebuild to update helper text
                            setState(() {});
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field is required';
                            }
                            final intValue = int.tryParse(value);
                            if (intValue == null) {
                              return 'Must be a valid number';
                            }
                            if (intValue < 60) {
                              return 'Must be at least 60 seconds';
                            }
                            if (intValue > 86400) {
                              return 'Must be at most 86400 seconds (24h)';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: isMobile ? 18 : 20,
                                  color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cache duration should be slightly less than check interval to avoid race conditions. '
                                  'Recommended: 10500 seconds (2h 55min) for 3-hour interval.',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Quick Presets
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tune,
                              color: Colors.purple,
                              size: isMobile ? 20 : 24,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Quick Presets',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPresetChip(
                              label: 'Default (3h)',
                              interval: 3,
                              cacheTtl: 10500,
                              icon: Icons.star,
                            ),
                            _buildPresetChip(
                              label: 'Frequent (1h)',
                              interval: 1,
                              cacheTtl: 3300,
                              icon: Icons.speed,
                            ),
                            _buildPresetChip(
                              label: 'Balanced (6h)',
                              interval: 6,
                              cacheTtl: 21300,
                              icon: Icons.balance,
                            ),
                            _buildPresetChip(
                              label: 'Relaxed (12h)',
                              interval: 12,
                              cacheTtl: 43200,
                              icon: Icons.nightlight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Linked Accounts Management
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: Colors.orange,
                              size: isMobile ? 20 : 24,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Linked Accounts',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon:
                                  Icon(Icons.refresh, size: isMobile ? 20 : 24),
                              onPressed: _isLoadingAccounts
                                  ? null
                                  : _loadLinkedAccounts,
                              tooltip: 'Refresh accounts',
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        if (_isLoadingAccounts)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_linkedAccounts.isEmpty)
                          Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.grey,
                                  size: isMobile ? 20 : 24,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'No linked accounts found',
                                    style:
                                        TextStyle(fontSize: isMobile ? 13 : 14),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth:
                                    constraints.maxWidth - (isMobile ? 48 : 64),
                              ),
                              child: DataTable(
                                columnSpacing: isMobile ? 12 : 20,
                                horizontalMargin: isMobile ? 8 : 24,
                                headingRowHeight: isMobile ? 56 : 56,
                                dataRowMinHeight: isMobile ? 48 : 48,
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      'Discord User',
                                      style: TextStyle(
                                          fontSize: isMobile ? 12 : 14),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Platform',
                                      style: TextStyle(
                                          fontSize: isMobile ? 12 : 14),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'RL Username',
                                      style: TextStyle(
                                          fontSize: isMobile ? 12 : 14),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      '1v1',
                                      style: TextStyle(
                                          fontSize: isMobile ? 12 : 14),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      '2v2',
                                      style: TextStyle(
                                          fontSize: isMobile ? 12 : 14),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      '3v3',
                                      style: TextStyle(
                                          fontSize: isMobile ? 12 : 14),
                                    ),
                                  ),
                                  if (!isMobile)
                                    DataColumn(
                                      label: Text(
                                        'Last Checked',
                                        style: TextStyle(
                                            fontSize: isMobile ? 12 : 14),
                                      ),
                                    ),
                                  DataColumn(
                                    label: Text(
                                      'Actions',
                                      style: TextStyle(
                                          fontSize: isMobile ? 12 : 14),
                                    ),
                                  ),
                                ],
                                rows: _linkedAccounts.map((account) {
                                  final ranks = account['rank_display'] ?? {};
                                  final iconUrls = account['icon_urls'] ?? {};
                                  final lastFetched = account['last_fetched'];
                                  final lastFetchedDisplay = lastFetched != null
                                      ? DateTime.parse(lastFetched)
                                          .toLocal()
                                          .toString()
                                          .split('.')[0]
                                      : 'Never';

                                  final avatarRadius = isMobile ? 14.0 : 16.0;
                                  final textSize = isMobile ? 12.0 : 14.0;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (account['avatar_url'] != null)
                                              CircleAvatar(
                                                radius: avatarRadius,
                                                backgroundImage: NetworkImage(
                                                    account['avatar_url']),
                                              )
                                            else
                                              CircleAvatar(
                                                radius: avatarRadius,
                                                child: Icon(Icons.person,
                                                    size: avatarRadius),
                                              ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    account['display_name'] ??
                                                        'Unknown',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: textSize,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (!isMobile)
                                                    Text(
                                                      account['username'] ?? '',
                                                      style: TextStyle(
                                                        fontSize: textSize - 2,
                                                        color: Colors.grey,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          (account['platform'] ?? 'unknown')
                                              .toString()
                                              .toUpperCase(),
                                          style: TextStyle(fontSize: textSize),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          account['rl_username'] ?? 'N/A',
                                          style: TextStyle(fontSize: textSize),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DataCell(_buildTableRankCell(ranks['1v1'],
                                          iconUrls['1v1'], isMobile)),
                                      DataCell(_buildTableRankCell(ranks['2v2'],
                                          iconUrls['2v2'], isMobile)),
                                      DataCell(_buildTableRankCell(ranks['3v3'],
                                          iconUrls['3v3'], isMobile)),
                                      if (!isMobile)
                                        DataCell(
                                          Tooltip(
                                            message: lastFetchedDisplay,
                                            child: Text(
                                              _formatRelativeTime(lastFetched),
                                              style:
                                                  TextStyle(fontSize: textSize),
                                            ),
                                          ),
                                        ),
                                      DataCell(
                                        IconButton(
                                          icon: Icon(Icons.delete_outline,
                                              color: Colors.red,
                                              size: isMobile ? 20 : 24),
                                          onPressed: () => _deleteAccount(
                                            account['user_id'],
                                            account['display_name'] ??
                                                'Unknown',
                                          ),
                                          tooltip: 'Unlink account',
                                          padding:
                                              EdgeInsets.all(isMobile ? 4 : 8),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        SizedBox(height: isMobile ? 12 : 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isCheckingRanks ? null : _triggerRankCheck,
                            icon: _isCheckingRanks
                                ? SizedBox(
                                    width: isMobile ? 14 : 16,
                                    height: isMobile ? 14 : 16,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(Icons.refresh, size: isMobile ? 20 : 24),
                            label: Text(
                              _isCheckingRanks
                                  ? 'Checking Ranks...'
                                  : 'Check All Ranks Now',
                              style: TextStyle(fontSize: isMobile ? 14 : 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.all(isMobile ? 12 : 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // Test Player Stats
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.science,
                              color: Colors.teal,
                              size: isMobile ? 20 : 24,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Test Player Stats',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        if (isMobile)
                          Column(
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue:
                                    _testPlatformController.text.isEmpty
                                        ? null
                                        : _testPlatformController.text,
                                decoration: const InputDecoration(
                                  labelText: 'Platform',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.gamepad),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'steam', child: Text('Steam')),
                                  DropdownMenuItem(
                                      value: 'epic', child: Text('Epic')),
                                  DropdownMenuItem(
                                      value: 'psn', child: Text('PSN')),
                                  DropdownMenuItem(
                                      value: 'xbl', child: Text('Xbox')),
                                  DropdownMenuItem(
                                      value: 'switch', child: Text('Switch')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    _testPlatformController.text = value;
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _testUsernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  hintText: 'Enter RL username',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isLoadingStats ? null : _testPlayerStats,
                                  icon: _isLoadingStats
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.search, size: 20),
                                  label: const Text('Fetch Stats',
                                      style: TextStyle(fontSize: 14)),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(14),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  initialValue:
                                      _testPlatformController.text.isEmpty
                                          ? null
                                          : _testPlatformController.text,
                                  decoration: const InputDecoration(
                                    labelText: 'Platform',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.gamepad),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'steam', child: Text('Steam')),
                                    DropdownMenuItem(
                                        value: 'epic', child: Text('Epic')),
                                    DropdownMenuItem(
                                        value: 'psn', child: Text('PSN')),
                                    DropdownMenuItem(
                                        value: 'xbl', child: Text('Xbox')),
                                    DropdownMenuItem(
                                        value: 'switch', child: Text('Switch')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _testPlatformController.text = value;
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _testUsernameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    hintText: 'Enter RL username',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed:
                                    _isLoadingStats ? null : _testPlayerStats,
                                icon: _isLoadingStats
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.search),
                                label: const Text('Fetch Stats'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(20),
                                ),
                              ),
                            ],
                          ),
                        if (_testStats != null) ...[
                          SizedBox(height: isMobile ? 12 : 16),
                          Container(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1A1A2E),
                                  Color(0xFF16213E),
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.circular(isMobile ? 12 : 16),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with player info
                                if (isMobile)
                                  Column(
                                    children: [
                                      if (_testStats!['highest_icon_url'] !=
                                          null)
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.blue
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 16,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              getProxiedImageUrl(_testStats![
                                                  'highest_icon_url']),
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _testStats!['username'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF00B4DB),
                                              Color(0xFF0083B0),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _testStats!['platform'] ?? 'Unknown',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      if (_testStats!['highest_icon_url'] !=
                                          null)
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.blue
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 16,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              getProxiedImageUrl(_testStats![
                                                  'highest_icon_url']),
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _testStats!['username'] ??
                                                  'Unknown',
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF00B4DB),
                                                    Color(0xFF0083B0),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.blue
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                _testStats!['platform'] ??
                                                    'Unknown',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                SizedBox(height: isMobile ? 16 : 24),
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.blue.withValues(alpha: 0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: isMobile ? 16 : 24),

                                // Ranks Grid
                                Text(
                                  'Competitive Ranks',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 12 : 16),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: isMobile ? 1 : 2,
                                  mainAxisSpacing: isMobile ? 12 : 16,
                                  crossAxisSpacing: isMobile ? 12 : 16,
                                  childAspectRatio: isMobile ? 3.5 : 2.2,
                                  children: [
                                    _buildRankCard(
                                      '1v1 Duel',
                                      _testStats!['rank_1v1'],
                                      _testStats!['tier_names']?['1v1'],
                                      _testStats!['icon_urls']?['1v1'],
                                      isMobile,
                                    ),
                                    _buildRankCard(
                                      '2v2 Doubles',
                                      _testStats!['rank_2v2'],
                                      _testStats!['tier_names']?['2v2'],
                                      _testStats!['icon_urls']?['2v2'],
                                      isMobile,
                                    ),
                                    _buildRankCard(
                                      '3v3 Standard',
                                      _testStats!['rank_3v3'],
                                      _testStats!['tier_names']?['3v3'],
                                      _testStats!['icon_urls']?['3v3'],
                                      isMobile,
                                    ),
                                    _buildRankCard(
                                      '4v4 Quads',
                                      _testStats!['rank_4v4'],
                                      _testStats!['tier_names']?['4v4'],
                                      _testStats!['icon_urls']?['4v4'],
                                      isMobile,
                                    ),
                                  ],
                                ),
                                SizedBox(height: isMobile ? 16 : 24),

                                // Season Reward
                                Container(
                                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.orange.withValues(alpha: 0.3),
                                        Colors.amber.withValues(alpha: 0.3),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          Colors.orange.withValues(alpha: 0.5),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding:
                                            EdgeInsets.all(isMobile ? 10 : 12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orange
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 12,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.emoji_events,
                                          size: isMobile ? 28 : 32,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: isMobile ? 12 : 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Season Reward Level',
                                              style: TextStyle(
                                                fontSize: isMobile ? 11 : 12,
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(height: isMobile ? 2 : 4),
                                            Text(
                                              _cleanRankText(_testStats![
                                                      'season_reward'] ??
                                                  'N/A'),
                                              style: TextStyle(
                                                fontSize: isMobile ? 16 : 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Action Buttons
                if (isMobile)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _resetToDefaults,
                          icon: const Icon(Icons.restore, size: 20),
                          label: const Text('Reset to Defaults',
                              style: TextStyle(fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveConfig,
                          icon: const Icon(Icons.save, size: 20),
                          label: const Text('Save Configuration',
                              style: TextStyle(fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _resetToDefaults,
                          icon: const Icon(Icons.restore),
                          label: const Text('Reset to Defaults'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveConfig,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Configuration'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetChip({
    required String label,
    required int interval,
    required int cacheTtl,
    required IconData icon,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        setState(() {
          _rankCheckIntervalController.text = interval.toString();
          _cacheTtlController.text = cacheTtl.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied preset: $label'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  Widget _buildTableRankCell(dynamic rank, String? iconUrl, bool isMobile) {
    if (rank == null)
      return Text('N/A', style: TextStyle(fontSize: isMobile ? 11 : 12));

    final cleanRank = _cleanRankText(rank.toString());
    final iconSize = isMobile ? 20.0 : 24.0;
    final fontSize = isMobile ? 11.0 : 12.0;

    return Tooltip(
      message: cleanRank,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconUrl != null)
            Image.network(
              getProxiedImageUrl(iconUrl),
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => SizedBox(
                width: iconSize,
                height: iconSize,
              ),
            ),
          if (iconUrl != null) SizedBox(width: isMobile ? 4 : 6),
          Flexible(
            child: Text(
              cleanRank,
              style: TextStyle(fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(String? timestamp) {
    if (timestamp == null) return 'Never';
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  String _cleanRankText(String text) {
    // Remove Discord emoji codes like <:d1:142538985622969146>
    return text.replaceAll(RegExp(r'<:[^:]+:\d+>'), '').trim();
  }

  Color _getRankColor(String? tierName) {
    if (tierName == null) return Colors.grey;

    final tier = tierName.toLowerCase();
    if (tier.contains('supersonic legend')) return const Color(0xFFB026FF);
    if (tier.contains('grand champion')) return const Color(0xFFE8E8E8);
    if (tier.contains('champion')) return const Color(0xFFBE5EE8);
    if (tier.contains('diamond')) return const Color(0xFF5E8EE8);
    if (tier.contains('platinum')) return const Color(0xFF5EBEE8);
    if (tier.contains('gold')) return const Color(0xFFE8B85E);
    if (tier.contains('silver')) return const Color(0xFFB8B8B8);
    if (tier.contains('bronze')) return const Color(0xFFCD7F32);
    return Colors.grey;
  }

  Widget _buildRankCard(String mode, String? rankDisplay, String? tierName,
      String? iconUrl, bool isMobile) {
    final cleanRank =
        rankDisplay != null ? _cleanRankText(rankDisplay) : 'Unranked';
    final color = _getRankColor(tierName);

    final iconSize = isMobile ? 40.0 : 50.0;
    final modeFontSize = isMobile ? 10.0 : 11.0;
    final rankFontSize = isMobile ? 12.0 : 14.0;
    final cardPadding = isMobile ? 10.0 : 14.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2A3E),
            Color(0xFF1F1F2E),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(
          color: color.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Icon
          if (iconUrl != null)
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  getProxiedImageUrl(iconUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.sports_esports,
                    color: color,
                    size: iconSize * 0.6,
                  ),
                ),
              ),
            )
          else
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.sports_esports,
                color: color,
                size: iconSize * 0.6,
              ),
            ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  mode,
                  style: TextStyle(
                    fontSize: modeFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  cleanRank,
                  style: TextStyle(
                    fontSize: rankFontSize,
                    fontWeight: FontWeight.bold,
                    color: color,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
