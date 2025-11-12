import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/app_config.dart';

class GamingHubScreen extends StatefulWidget {
  const GamingHubScreen({super.key});

  @override
  State<GamingHubScreen> createState() => _GamingHubScreenState();
}

class _GamingHubScreenState extends State<GamingHubScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, online, playing

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.getGamingMembers();

      if (mounted) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(result['members'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading members: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredMembers {
    var filtered = _members.where((member) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final username = (member['username'] as String?)?.toLowerCase() ?? '';
        final displayName =
            (member['display_name'] as String?)?.toLowerCase() ?? '';
        if (!username.contains(query) && !displayName.contains(query)) {
          return false;
        }
      }

      // Status filter
      if (_filterStatus == 'online') {
        return member['status'] != 'offline';
      } else if (_filterStatus == 'playing') {
        return member['activity'] != null;
      }

      return true;
    }).toList();

    return filtered;
  }

  void _showGameRequestDialog(Map<String, dynamic> targetMember) {
    final gameController = TextEditingController();
    final messageController = TextEditingController();

    // Pre-fill game name if user is playing something
    if (targetMember['activity'] != null) {
      gameController.text = targetMember['activity']['name'] ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.videogame_asset, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('Send Game Request')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target user info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: targetMember['avatar_url'] != null
                          ? NetworkImage(targetMember['avatar_url'])
                          : null,
                      child: targetMember['avatar_url'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            targetMember['display_name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '@${targetMember['username'] ?? 'unknown'}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Game name
              TextField(
                controller: gameController,
                decoration: const InputDecoration(
                  labelText: 'Game Name *',
                  hintText: 'e.g., Rocket League, Minecraft',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sports_esports),
                ),
              ),
              const SizedBox(height: 12),
              // Optional message
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  hintText: 'Add a personal message...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
              ),
              const SizedBox(height: 12),
              // Info text
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will post a public request in the gaming channel with a mention for the user.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (gameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a game name')),
                );
                return;
              }

              Navigator.pop(context);
              await _sendGameRequest(
                targetMember['id'],
                gameController.text.trim(),
                messageController.text.trim(),
              );
            },
            icon: const Icon(Icons.send),
            label: const Text('Send Request'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendGameRequest(
      String targetUserId, String gameName, String message) async {
    // Show loading
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
              Text('Sending game request...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.postGameRequest(
        targetUserId,
        gameName,
        message,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎮 Game request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to send request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMemberCard(Map<String, dynamic> member, bool isMobile) {
    final status = member['status'] as String? ?? 'offline';
    final activity = member['activity'] as Map<String, dynamic>?;
    final isOnline = status != 'offline';
    final usingApp = member['using_app'] as bool? ?? false;

    Color statusColor;
    switch (status) {
      case 'online':
        statusColor = Colors.green;
        break;
      case 'idle':
        statusColor = Colors.orange;
        break;
      case 'dnd':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12,
        vertical: 6,
      ),
      child: InkWell(
        onTap: () => _showGameRequestDialog(member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Row(
            children: [
              // Avatar with status indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: isMobile ? 24 : 28,
                    backgroundImage: member['avatar_url'] != null
                        ? NetworkImage(member['avatar_url'])
                        : null,
                    child: member['avatar_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: isMobile ? 14 : 16,
                      height: isMobile ? 14 : 16,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: isMobile ? 12 : 16),
              // User info and activity
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['display_name'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 15 : 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '@${member['username'] ?? 'unknown'}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: isMobile ? 11 : 12,
                          ),
                        ),
                        // App badge
                        if (usingApp) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Using ${AppConfig.appName}',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.purple.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.phone_android,
                                    size: isMobile ? 9 : 10,
                                    color: Colors.purple[300],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'APP',
                                    style: TextStyle(
                                      color: Colors.purple[300],
                                      fontSize: isMobile ? 8 : 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (activity != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getActivityIcon(activity['type']),
                              size: isMobile ? 12 : 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                activity['name'] ?? 'Unknown Activity',
                                style: TextStyle(
                                  color: Colors.green[300],
                                  fontSize: isMobile ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (activity['details'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          activity['details'],
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: isMobile ? 10 : 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ] else if (!isOnline) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Offline',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isMobile ? 11 : 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Action button
              IconButton(
                icon: const Icon(Icons.videogame_asset),
                color: Colors.green,
                tooltip: 'Send game request',
                onPressed: () => _showGameRequestDialog(member),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'playing':
        return Icons.sports_esports;
      case 'streaming':
        return Icons.live_tv;
      case 'listening':
        return Icons.headphones;
      case 'watching':
        return Icons.tv;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gaming Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMembers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Search field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text('All (${_members.length})'),
                        selected: _filterStatus == 'all',
                        onSelected: (_) {
                          setState(() => _filterStatus = 'all');
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(
                          'Online (${_members.where((m) => m['status'] != 'offline').length})',
                        ),
                        selected: _filterStatus == 'online',
                        onSelected: (_) {
                          setState(() => _filterStatus = 'online');
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(
                          'Playing (${_members.where((m) => m['activity'] != null).length})',
                        ),
                        selected: _filterStatus == 'playing',
                        onSelected: (_) {
                          setState(() => _filterStatus = 'playing');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Members list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No members found'
                                  : 'No members match your search',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMembers,
                        child: ListView.builder(
                          itemCount: _filteredMembers.length,
                          itemBuilder: (context, index) {
                            return _buildMemberCard(
                              _filteredMembers[index],
                              isMobile,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
