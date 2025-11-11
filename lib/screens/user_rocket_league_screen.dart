import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class UserRocketLeagueScreen extends StatefulWidget {
  const UserRocketLeagueScreen({super.key});

  @override
  State<UserRocketLeagueScreen> createState() => _UserRocketLeagueScreenState();
}

class _UserRocketLeagueScreenState extends State<UserRocketLeagueScreen> {
  bool _isLoading = true;
  bool _isLinked = false;
  Map<String, dynamic>? _linkedAccount;

  // Link form controllers
  final _linkFormKey = GlobalKey<FormState>();
  String _selectedPlatform = 'steam';
  final _usernameController = TextEditingController();
  bool _isLinking = false;

  // Test stats controllers
  final _testFormKey = GlobalKey<FormState>();
  String _testPlatform = 'steam';
  final _testUsernameController = TextEditingController();
  bool _isLoadingStats = false;
  Map<String, dynamic>? _testStats;

  final List<String> _platforms = [
    'steam',
    'epic',
    'psn',
    'xbl',
    'switch',
  ];

  final Map<String, String> _platformNames = {
    'steam': 'Steam',
    'epic': 'Epic Games',
    'psn': 'PlayStation',
    'xbl': 'Xbox Live',
    'switch': 'Nintendo Switch',
  };

  final Map<String, IconData> _platformIcons = {
    'steam': Icons.computer,
    'epic': Icons.videogame_asset,
    'psn': Icons.sports_esports,
    'xbl': Icons.sports_esports_outlined,
    'switch': Icons.gamepad,
  };

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _testUsernameController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.getUserRLAccount();

      if (mounted) {
        setState(() {
          _isLinked = result['linked'] ?? false;
          _linkedAccount = result['account'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading account: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _linkAccount() async {
    if (!_linkFormKey.currentState!.validate()) return;

    setState(() => _isLinking = true);

    try {
      // First, fetch stats to verify account exists (like bot does)
      final authService = Provider.of<AuthService>(context, listen: false);
      final stats = await authService.apiService.getRLStats(
        _selectedPlatform,
        _usernameController.text,
      );

      if (!mounted) return;

      // Show confirmation dialog with stats (like bot does)
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🔗 Confirm Account Linking'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Player found: ${stats['stats']['username']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Platform: ${_platformNames[_selectedPlatform]}'),
                const SizedBox(height: 12),
                const Text(
                  'Current Ranks:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('1v1: ${stats['stats']['rank_1v1']}'),
                Text('2v2: ${stats['stats']['rank_2v2']}'),
                Text('3v3: ${stats['stats']['rank_3v3']}'),
                Text('4v4: ${stats['stats']['rank_4v4']}'),
                const SizedBox(height: 12),
                const Text(
                  'Do you want to link this account?',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Confirm Link'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // Now actually link the account
      await authService.apiService.linkUserRLAccount(
        _selectedPlatform,
        _usernameController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Account linked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _usernameController.clear();
        await _loadAccount();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to link account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLinking = false);
      }
    }
  }

  Future<void> _postToChannel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Stats to Channel?'),
        content: const Text(
          'This will post your Rocket League stats to the configured Rocket League channel in Discord.\n\n'
          'Everyone in the server will be able to see your stats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Post Stats'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Posting stats to channel...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.postUserRLStats();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Stats posted to Rocket League channel!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post stats: $e')),
        );
      }
    }
  }

  Future<void> _unlinkAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink RL Account?'),
        content: Text(
          'This will remove the link to your Rocket League account '
          '"${_linkedAccount!['username']}" on ${_platformNames[_linkedAccount!['platform']]}.\n\n'
          'You can link it again later.',
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

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.unlinkUserRLAccount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account unlinked successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadAccount();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unlink account: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testPlayerStats() async {
    if (!_testFormKey.currentState!.validate()) return;

    setState(() {
      _isLoadingStats = true;
      _testStats = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.getRocketLeagueStats(
        _testPlatform,
        _testUsernameController.text,
      );

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 12.0 : 16.0;
        final cardPadding = isMobile ? 12.0 : 16.0;

        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rocket League',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: isMobile ? 24 : null,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLinked
                      ? 'Your linked account and rank tracking'
                      : 'Link your Rocket League account to track your ranks',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 13 : null,
                      ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Linked Account or Link Form
                if (_isLinked)
                  _buildLinkedAccountCard(isMobile, cardPadding)
                else
                  _buildLinkFormCard(isMobile, cardPadding),

                SizedBox(height: isMobile ? 12 : 16),

                // Test Player Stats
                _buildTestStatsCard(isMobile, cardPadding),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLinkedAccountCard(bool isMobile, double cardPadding) {
    final account = _linkedAccount!;
    final platform = account['platform'] as String;
    final username = account['username'] as String;
    final rankDisplay = account['rank_display'] as Map<String, dynamic>? ?? {};
    final tierNames = account['ranks'] as Map<String, dynamic>? ?? {};
    final iconUrls = account['icon_urls'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _platformIcons[platform] ?? Icons.sports_esports,
                  color: Colors.blue,
                  size: isMobile ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your Ranks',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: isMobile ? 18 : null,
                        ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _postToChannel,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Post'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 8 : 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _unlinkAccount,
                  icon: const Icon(Icons.link_off, size: 18),
                  label: const Text('Unlink'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 8 : 12,
                    ),
                  ),
                ),
              ],
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
                  Icon(
                    _platformIcons[platform],
                    color: Colors.blue[700],
                    size: isMobile ? 32 : 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        Text(
                          _platformNames[platform] ?? platform,
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (rankDisplay.isNotEmpty) ...[
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'Current Ranks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: isMobile ? 15 : null,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: isMobile ? 8 : 12,
                runSpacing: isMobile ? 8 : 12,
                children: rankDisplay.entries.map((entry) {
                  final playlist = entry.key;
                  final rank = entry.value as String;
                  final tierName = tierNames[playlist] as String? ??
                      _getTierNameFromRank(rank);
                  final iconUrl = iconUrls[playlist] as String?;

                  return _buildRankCard(
                    _formatPlaylistName(playlist),
                    rank,
                    tierName,
                    iconUrl,
                    isMobile,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLinkFormCard(bool isMobile, double cardPadding) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Form(
          key: _linkFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.link,
                    color: Colors.blue,
                    size: isMobile ? 20 : 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Link Your Account',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: isMobile ? 18 : null,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedPlatform,
                decoration: InputDecoration(
                  labelText: 'Platform',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(_platformIcons[_selectedPlatform]),
                  isDense: isMobile,
                ),
                items: _platforms.map((platform) {
                  return DropdownMenuItem(
                    value: platform,
                    child: Row(
                      children: [
                        Icon(_platformIcons[platform], size: 20),
                        const SizedBox(width: 8),
                        Text(_platformNames[platform]!),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPlatform = value);
                  }
                },
              ),
              SizedBox(height: isMobile ? 12 : 16),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Your Rocket League username',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  isDense: isMobile,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
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
                        size: isMobile ? 18 : 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The bot will verify your account exists and track your ranks automatically.',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLinking ? null : _linkAccount,
                  icon: _isLinking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.link),
                  label: Text(_isLinking ? 'Linking...' : 'Link Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestStatsCard(bool isMobile, double cardPadding) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Form(
          key: _testFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.purple,
                    size: isMobile ? 20 : 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Test Player Stats',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: isMobile ? 18 : null,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Look up any Rocket League player\'s current ranks',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: isMobile ? 12 : null,
                    ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              DropdownButtonFormField<String>(
                initialValue: _testPlatform,
                decoration: InputDecoration(
                  labelText: 'Platform',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(_platformIcons[_testPlatform]),
                  isDense: isMobile,
                ),
                items: _platforms.map((platform) {
                  return DropdownMenuItem(
                    value: platform,
                    child: Row(
                      children: [
                        Icon(_platformIcons[platform], size: 20),
                        const SizedBox(width: 8),
                        Text(_platformNames[platform]!),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _testPlatform = value);
                  }
                },
              ),
              SizedBox(height: isMobile ? 12 : 16),
              TextFormField(
                controller: _testUsernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter username to look up',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_search),
                  isDense: isMobile,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              SizedBox(height: isMobile ? 12 : 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoadingStats ? null : _testPlayerStats,
                  icon: _isLoadingStats
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                      _isLoadingStats ? 'Fetching...' : 'Fetch Player Stats'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                ),
              ),
              if (_testStats != null) ...[
                SizedBox(height: isMobile ? 12 : 16),
                const Divider(),
                SizedBox(height: isMobile ? 8 : 12),
                _buildTestStatsResults(isMobile),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestStatsResults(bool isMobile) {
    if (_testStats == null) return const SizedBox.shrink();

    // Check if we have any ranked data
    final hasRanks = _testStats!['rank_1v1'] != null ||
        _testStats!['rank_2v2'] != null ||
        _testStats!['rank_3v3'] != null ||
        _testStats!['rank_4v4'] != null ||
        _testStats!['rank_hoops'] != null ||
        _testStats!['rank_rumble'] != null ||
        _testStats!['rank_dropshot'] != null ||
        _testStats!['rank_snowday'] != null;

    if (!hasRanks) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No ranked playlists found for this player.',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Player info header
        if (_testStats!['username'] != null) ...[
          Row(
            children: [
              if (_testStats!['highest_icon_url'] != null)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _testStats!['highest_icon_url'],
                      width: isMobile ? 48 : 64,
                      height: isMobile ? 48 : 64,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.sports_esports,
                        size: isMobile ? 48 : 64,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
              if (_testStats!['highest_icon_url'] != null)
                SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _testStats!['username'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                    if (_testStats!['platform'] != null)
                      Text(
                        _testStats!['platform'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.purple[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Divider(color: Colors.purple.withValues(alpha: 0.3)),
          SizedBox(height: isMobile ? 8 : 12),
        ],
        Text(
          'Current Ranks',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: isMobile ? 15 : null,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: isMobile ? 8 : 12,
          runSpacing: isMobile ? 8 : 12,
          children: [
            if (_testStats!['rank_1v1'] != null)
              _buildRankCard(
                'Duel 1v1',
                _testStats!['rank_1v1'],
                _testStats!['tier_names']?['1v1'],
                _testStats!['icon_urls']?['1v1'],
                isMobile,
              ),
            if (_testStats!['rank_2v2'] != null)
              _buildRankCard(
                'Doubles 2v2',
                _testStats!['rank_2v2'],
                _testStats!['tier_names']?['2v2'],
                _testStats!['icon_urls']?['2v2'],
                isMobile,
              ),
            if (_testStats!['rank_3v3'] != null)
              _buildRankCard(
                'Standard 3v3',
                _testStats!['rank_3v3'],
                _testStats!['tier_names']?['3v3'],
                _testStats!['icon_urls']?['3v3'],
                isMobile,
              ),
            if (_testStats!['rank_4v4'] != null)
              _buildRankCard(
                '4v4',
                _testStats!['rank_4v4'],
                _testStats!['tier_names']?['4v4'],
                _testStats!['icon_urls']?['4v4'],
                isMobile,
              ),
            if (_testStats!['rank_hoops'] != null)
              _buildRankCard(
                'Hoops',
                _testStats!['rank_hoops'],
                _testStats!['tier_names']?['hoops'],
                _testStats!['icon_urls']?['hoops'],
                isMobile,
              ),
            if (_testStats!['rank_rumble'] != null)
              _buildRankCard(
                'Rumble',
                _testStats!['rank_rumble'],
                _testStats!['tier_names']?['rumble'],
                _testStats!['icon_urls']?['rumble'],
                isMobile,
              ),
            if (_testStats!['rank_dropshot'] != null)
              _buildRankCard(
                'Dropshot',
                _testStats!['rank_dropshot'],
                _testStats!['tier_names']?['dropshot'],
                _testStats!['icon_urls']?['dropshot'],
                isMobile,
              ),
            if (_testStats!['rank_snowday'] != null)
              _buildRankCard(
                'Snow Day',
                _testStats!['rank_snowday'],
                _testStats!['tier_names']?['snowday'],
                _testStats!['icon_urls']?['snowday'],
                isMobile,
              ),
          ],
        ),
      ],
    );
  }

  String _formatPlaylistName(String playlist) {
    switch (playlist) {
      case '1v1':
        return 'Duel 1v1';
      case '2v2':
        return 'Doubles 2v2';
      case '3v3':
        return 'Standard 3v3';
      case '4v4':
        return '4v4';
      case 'hoops':
        return 'Hoops';
      case 'rumble':
        return 'Rumble';
      case 'dropshot':
        return 'Dropshot';
      case 'snowday':
        return 'Snow Day';
      default:
        return playlist.toUpperCase();
    }
  }

  String _getTierNameFromRank(String rank) {
    final lowerRank = rank.toLowerCase();
    if (lowerRank.contains('supersonic legend')) return 'supersonic_legend';
    if (lowerRank.contains('grand champion')) return 'grand_champion';
    if (lowerRank.contains('champion')) return 'champion';
    if (lowerRank.contains('diamond')) return 'diamond';
    if (lowerRank.contains('platinum')) return 'platinum';
    if (lowerRank.contains('gold')) return 'gold';
    if (lowerRank.contains('silver')) return 'silver';
    if (lowerRank.contains('bronze')) return 'bronze';
    if (lowerRank.contains('unranked')) return 'unranked';
    return 'unranked';
  }

  Color _getRankColor(String? tierName) {
    if (tierName == null) return Colors.grey;
    switch (tierName.toLowerCase()) {
      case 'supersonic_legend':
      case 'supersonic legend':
        return const Color(0xFFFF00FF);
      case 'grand_champion':
      case 'grand champion':
        return const Color(0xFFFF0000);
      case 'champion':
        return const Color(0xFFAA00FF);
      case 'diamond':
        return const Color(0xFF0080FF);
      case 'platinum':
        return const Color(0xFF00BFFF);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      default:
        return Colors.grey;
    }
  }

  String _extractDivision(String rank) {
    // Extract Division from rank string (e.g., "Diamond I Div III" -> "Div III")
    final divMatch = RegExp(r'Div(?:ision)?\s+([IVX]+|\d+)').firstMatch(rank);
    if (divMatch != null) {
      return 'Div ${divMatch.group(1)}';
    }
    return '';
  }

  String _cleanRankText(String rank) {
    // Remove Discord emojis (e.g., "<:diamond:123456789>") and Division text
    return rank
        .replaceAll(RegExp(r'<:[^:]+:\d+>\s*'), '') // Remove Discord emojis
        .replaceAll(RegExp(r'\s*Div(?:ision)?\s+[IVX]+\s*'), ' ')
        .replaceAll(RegExp(r'\s*Division\s+\d+\s*'), ' ')
        .replaceAll(RegExp(r'\s*Div\s+\d+\s*'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Widget _buildRankCard(String mode, String? rankDisplay, String? tierName,
      String? iconUrl, bool isMobile) {
    final cleanRank =
        rankDisplay != null ? _cleanRankText(rankDisplay) : 'Unranked';
    final division = rankDisplay != null ? _extractDivision(rankDisplay) : '';
    final color = _getRankColor(tierName);

    final iconSize = isMobile ? 40.0 : 50.0;
    final modeFontSize = isMobile ? 10.0 : 11.0;
    final rankFontSize = isMobile ? 12.0 : 14.0;
    final divisionFontSize = isMobile ? 10.0 : 12.0;
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
                  iconUrl,
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        cleanRank,
                        style: TextStyle(
                          fontSize: rankFontSize,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (division.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        division,
                        style: TextStyle(
                          fontSize: divisionFontSize,
                          fontWeight: FontWeight.w500,
                          color: color.withValues(alpha: 0.8),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
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
