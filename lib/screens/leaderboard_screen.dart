import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _leaderboard = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().getLeaderboard(limit: 50);

      if (response['success'] == true) {
        setState(() {
          _leaderboard = List<Map<String, dynamic>>.from(
              response['leaderboard'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load leaderboard';
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

  Color? _parseTierColor(String? tierColor) {
    if (tierColor == null) return null;
    try {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XP Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadLeaderboard,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _leaderboard.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.leaderboard,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No leaderboard data yet',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        
                        return RefreshIndicator(
                          onRefresh: _loadLeaderboard,
                          child: ListView.builder(
                            padding: EdgeInsets.all(isMobile ? 8 : 16),
                            itemCount: _leaderboard.length,
                            itemBuilder: (context, index) {
                              final entry = _leaderboard[index];
                              return _buildLeaderboardCard(
                                context,
                                entry,
                                isMobile,
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildLeaderboardCard(
    BuildContext context,
    Map<String, dynamic> entry,
    bool isMobile,
  ) {
    final rank = entry['rank'] as int? ?? 0;
    final username = entry['username'] as String? ?? 'Unknown';
    final level = entry['current_level'] as int? ?? 0;
    final totalXp = entry['total_xp'] as int? ?? 0;
    final tierName = entry['tier_name'] as String? ?? 'common';
    final tierColor = entry['tier_color'] as String?;

    final parsedTierColor = _parseTierColor(tierColor);

    // Special styling for top 3
    Color? rankBgColor;
    IconData? rankIcon;
    if (rank == 1) {
      rankBgColor = Colors.amber[600];
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankBgColor = Colors.grey[400];
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankBgColor = Colors.brown[400];
      rankIcon = Icons.emoji_events;
    }

    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;

    return Card(
      color: cardColor,
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      elevation: rank <= 3 ? 4 : 0,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 10 : 14),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: isMobile ? 45 : 50,
              height: isMobile ? 45 : 50,
              decoration: BoxDecoration(
                color: rankBgColor ??
                    Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: rankIcon != null
                    ? Icon(rankIcon, color: Colors.white, size: isMobile ? 24 : 28)
                    : Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: isMobile ? 15 : 17,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: parsedTierColor?.withOpacity(0.2) ??
                              Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tierName.toUpperCase(),
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 11,
                            fontWeight: FontWeight.bold,
                            color: parsedTierColor ??
                                Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.stars,
                          size: isMobile ? 14 : 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${totalXp.toString()} XP',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: isMobile ? 12 : 13,
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Level Badge
            Container(
              width: isMobile ? 55 : 65,
              height: isMobile ? 55 : 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: parsedTierColor != null
                      ? [parsedTierColor, parsedTierColor.withOpacity(0.6)]
                      : [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.6)
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LVL',
                      style: TextStyle(
                        fontSize: isMobile ? 8 : 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$level',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
