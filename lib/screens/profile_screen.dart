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
  Map<String, dynamic>? _xp;
  String? _joinedAt;
  String? _createdAt;

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
          _optInRoles =
              List<Map<String, dynamic>>.from(profile['opt_in_roles'] ?? []);
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
          _xp = profile['xp'];
          _joinedAt = profile['joined_at'];
          _createdAt = profile['created_at'];
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

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return '$years year${years > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else {
        return 'Today';
      }
    } catch (e) {
      return 'Unknown';
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
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
                                    color: _getRoleColor(_role)
                                        .withValues(alpha: 0.2),
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
                              color:
                                  _getRoleColor(_role).withValues(alpha: 0.2),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 18 : 22,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(_role)
                                      .withValues(alpha: 0.2),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
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

                // Opt-In Roles (Interest Roles)
                if (_optInRoles.isNotEmpty) ...[
                  Card(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎯 Interest Roles',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _optInRoles.map((role) {
                              final colorValue = role['color'] as int? ?? 0;
                              final color = colorValue != 0
                                  ? Color(colorValue | 0xFF000000)
                                  : Theme.of(context).colorScheme.primary;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: color.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  role['name'] ?? 'Unknown Role',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Rocket League Rank Card (if available)
                if (_rlRank != null) ...[
                  Card(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🚗 Rocket League',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Rank Icon
                              if (_rlRank!['icon_url'] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    getProxiedImageUrl(_rlRank!['icon_url']),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.sports_esports,
                                          size: 24,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
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
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    if (_rlRank!['platform'] != null)
                                      Text(
                                        '${_rlRank!['platform']}: ${_rlRank!['username'] ?? 'Unknown'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
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

                // Account Details
                if (_joinedAt != null || _createdAt != null) ...[
                  Card(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📅 Account Details',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (_joinedAt != null)
                            _StatRow(
                              icon: Icons.group_add,
                              label: 'Member Since',
                              value: _formatDate(_joinedAt!),
                            ),
                          if (_createdAt != null)
                            _StatRow(
                              icon: Icons.cake,
                              label: 'Account Created',
                              value: _formatDate(_createdAt!),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // XP & Level Section
                if (_xp != null) ...[
                  Card(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⭐ Level & Experience',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          // Level Badge (circular, centered)
                          Center(
                            child: _buildLevelBadge(
                              level: _xp!['level'] as int? ?? 0,
                              tierColor: _xp!['tier_color'] as String?,
                              isMobile: isMobile,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Tier Name
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _parseTierColor(_xp!['tier_color'])
                                        ?.withOpacity(0.2) ??
                                    Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (_xp!['tier'] ?? 'common')
                                    .toString()
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: _parseTierColor(_xp!['tier_color']) ??
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // XP Stats
                          _StatRow(
                            icon: Icons.stars,
                            label: 'Total XP',
                            value: _xp!['total_xp']?.toString() ?? '0',
                          ),
                          _StatRow(
                            icon: Icons.trending_up,
                            label: 'XP for Next Level',
                            value: _xp!['xp_for_next_level']?.toString() ?? '0',
                          ),
                          const SizedBox(height: 12),
                          // Progress Bar to Next Level
                          if (_xp!['total_xp'] != null &&
                              _xp!['xp_for_next_level'] != null) ...[
                            _buildProgressBar(
                              current: _xp!['total_xp'] as int? ?? 0,
                              target: _xp!['xp_for_next_level'] as int? ?? 0,
                              tierColor: _xp!['tier_color'] as String?,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Activity Stats
                if (_activity != null) ...[
                  Card(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 Activity Stats',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
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
                            value: _activity!['memes_requested']?.toString() ??
                                '0',
                          ),
                          _StatRow(
                            icon: Icons.create,
                            label: 'Memes Generated',
                            value: _activity!['memes_generated']?.toString() ??
                                '0',
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
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚙️ Custom Stats',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
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
                              value:
                                  _customStats!['resolved_tickets'].toString(),
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
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔔 Notifications',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _StatRow(
                            icon: Icons.announcement,
                            label: 'Changelog',
                            value: _notifications!['changelog_opt_in'] == true
                                ? '✅ Enabled'
                                : '❌ Disabled',
                          ),
                          _StatRow(
                            icon: Icons.emoji_emotions,
                            label: 'Daily Meme',
                            value: _notifications!['meme_opt_in'] == true
                                ? '✅ Enabled'
                                : '❌ Disabled',
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

  Widget _buildLevelBadge({
    required int level,
    String? tierColor,
    required bool isMobile,
  }) {
    final parsedColor = _parseTierColor(tierColor);
    
    return Container(
      width: isMobile ? 100 : 120,
      height: isMobile ? 100 : 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: parsedColor != null
              ? [parsedColor, parsedColor.withOpacity(0.6)]
              : [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.6)
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (parsedColor ?? Theme.of(context).colorScheme.primary)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LEVEL',
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.8),
                letterSpacing: 1.2,
              ),
            ),
            Text(
              '$level',
              style: TextStyle(
                fontSize: isMobile ? 36 : 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar({
    required int current,
    required int target,
    String? tierColor,
  }) {
    final parsedColor = _parseTierColor(tierColor);
    
    // Calculate progress (0.0 to 1.0)
    // For level progress, we need to calculate XP within current level
    // current is total XP, target is XP needed for next level
    // We need to find XP for current level to calculate progress within this level
    final currentLevel = _xp!['level'] as int? ?? 1;
    
    // Calculate XP needed for current level (previous level boundary)
    int xpForCurrentLevel = 0;
    if (currentLevel > 1) {
      // Simple formula: base * (multiplier ^ (level - 1))
      // This should match Config.calculate_xp_for_next_level logic
      for (int i = 1; i < currentLevel; i++) {
        xpForCurrentLevel += (100 * (1.5 * i)).round();
      }
    }
    
    final xpInCurrentLevel = current - xpForCurrentLevel;
    final xpNeededForLevel = target;
    final progress = xpNeededForLevel > 0 
        ? (xpInCurrentLevel / xpNeededForLevel).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress to Next Level',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: parsedColor ?? Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              parsedColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$xpInCurrentLevel XP',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '$xpNeededForLevel XP',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Color? _parseTierColor(String? tierColor) {
    if (tierColor == null) return null;
    try {
      // Handle both #RRGGBB and 0xFFRRGGBB formats
      if (tierColor.startsWith('#')) {
        return Color(int.parse(tierColor.replaceFirst('#', '0xFF')));
      } else if (tierColor.startsWith('0x')) {
        return Color(int.parse(tierColor));
      }
      return null;
    } catch (e) {
      return null;
    }
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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
