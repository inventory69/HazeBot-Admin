import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  // ignore: unused_field
  List<Map<String, dynamic>> _optInRoles = [];
  Map<String, dynamic>? _rlRank;
  String? _errorMessage;
  String? _displayName;
  String? _avatarUrl;
  String? _username;
  String? _discordId;
  String? _role;
  String? _roleName;
  Map<String, dynamic>? _notifications;
  Map<String, dynamic>? _customStats;
  Map<String, dynamic>? _activity;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().getUserProfile();

      if (response['success'] == true && response['profile'] != null) {
        final profile = response['profile'];
        setState(() {
          _optInRoles = List<Map<String, dynamic>>.from(profile['opt_in_roles'] ?? []);
          _rlRank = profile['rl_rank'];
          _displayName = profile['display_name'];
          _avatarUrl = profile['avatar_url'];
          _username = profile['username'];
          _discordId = profile['discord_id'];
          _role = profile['role'];
          _roleName = profile['role_name'];
          _notifications = profile['notifications'];
          _customStats = profile['custom_stats'];
          _activity = profile['activity'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Color _getRoleColor(String? roleStr) {
    if (roleStr == null) return Colors.grey;
    switch (roleStr.toLowerCase()) {
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

  IconData _getRoleIcon(String? roleStr) {
    if (roleStr == null) return Icons.person;
    switch (roleStr.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'mod':
        return Icons.shield;
      case 'lootling':
        return Icons.backpack;
      default:
        return Icons.person;
    }
  }

  String _getRoleDisplayName(String? roleStr) {
    // Use actual role name from Discord if available
    if (_roleName != null && _roleName!.isNotEmpty) {
      return _roleName!;
    }
    // Fallback to default names
    if (roleStr == null) return 'User';
    switch (roleStr.toLowerCase()) {
      case 'admin':
        return '🧊 Inventory Master';
      case 'mod':
        return '📦 Slot Keeper';
      case 'lootling':
        return '🎒 Lootling';
      default:
        return roleStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadProfileData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 16,
              isMobile ? 16 : 24,
              isMobile ? 12 : 16,
              isMobile ? 16 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Information Card
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    child: Row(
                      children: [
                        // Avatar
                        if (_avatarUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _avatarUrl!,
                              width: isMobile ? 56 : 64,
                              height: isMobile ? 56 : 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: isMobile ? 56 : 64,
                                  height: isMobile ? 56 : 64,
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(_role).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getRoleIcon(_role),
                                    size: isMobile ? 28 : 32,
                                    color: _getRoleColor(_role),
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          Container(
                            width: isMobile ? 56 : 64,
                            height: isMobile ? 56 : 64,
                            decoration: BoxDecoration(
                              color: _getRoleColor(_role).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getRoleIcon(_role),
                              size: isMobile ? 28 : 32,
                              color: _getRoleColor(_role),
                            ),
                          ),
                        SizedBox(width: isMobile ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayName ?? _username ?? 'User',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 18 : 22,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(_role).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _getRoleDisplayName(_role),
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getRoleColor(_role),
                                  ),
                                ),
                              ),
                              if (_discordId != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Discord ID: $_discordId',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Rocket League Rank Card (if available)
                if (_rlRank != null) ...[
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🚗 Rocket League',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Rank Icon
                              if (_rlRank!['icon_url'] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _rlRank!['icon_url'],
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.sports_esports,
                                          size: 24,
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _rlRank!['rank'] ?? 'Unranked',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    if (_rlRank!['platform'] != null)
                                      Text(
                                        '${_rlRank!['platform']}: ${_rlRank!['username'] ?? 'Unknown'}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Activity Stats
                if (_activity != null) ...[
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 Activity Stats',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _StatRow(
                            icon: Icons.message,
                            label: 'Messages',
                            value: _activity!['messages']?.toString() ?? '0',
                          ),
                          _StatRow(
                            icon: Icons.image,
                            label: 'Images',
                            value: _activity!['images']?.toString() ?? '0',
                          ),
                          _StatRow(
                            icon: Icons.emoji_emotions,
                            label: 'Memes Requested',
                            value: _activity!['memes_requested']?.toString() ?? '0',
                          ),
                          _StatRow(
                            icon: Icons.create,
                            label: 'Memes Generated',
                            value: _activity!['memes_generated']?.toString() ?? '0',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Custom Stats
                if (_customStats != null) ...[
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚙️ Custom Stats',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (_customStats!['warnings'] != null)
                            _StatRow(
                              icon: Icons.warning,
                              label: 'Warnings',
                              value: _customStats!['warnings'].toString(),
                            ),
                          if (_customStats!['resolved_tickets'] != null)
                            _StatRow(
                              icon: Icons.check_circle,
                              label: 'Resolved Tickets',
                              value: _customStats!['resolved_tickets'].toString(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Notifications
                if (_notifications != null) ...[
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔔 Notifications',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _StatRow(
                            icon: Icons.announcement,
                            label: 'Changelog',
                            value: _notifications!['changelog_opt_in'] == true ? '✅ Enabled' : '❌ Disabled',
                          ),
                          _StatRow(
                            icon: Icons.emoji_emotions,
                            label: 'Daily Meme',
                            value: _notifications!['meme_opt_in'] == true ? '✅ Enabled' : '❌ Disabled',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
