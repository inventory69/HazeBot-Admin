import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class MemeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> meme;

  const MemeDetailScreen({super.key, required this.meme});

  @override
  State<MemeDetailScreen> createState() => _MemeDetailScreenState();
}

class _MemeDetailScreenState extends State<MemeDetailScreen> {
  int _upvotes = 0;
  bool _hasUpvoted = false;
  bool _hasDiscordUpvoted = false;
  bool _isUpvoting = false;
  bool _isLoadingReactions = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _upvotes = widget.meme['upvotes'] as int? ?? 0;
    _loadReactions();
  }

  Future<void> _loadReactions() async {
    final messageId = widget.meme['message_id'] as String?;
    if (messageId == null) {
      setState(() {
        _isLoadingReactions = false;
      });
      return;
    }

    try {
      final response = await ApiService().getMemeReactions(messageId);
      print('Reactions response: $response'); // Debug
      if (response['success'] == true) {
        setState(() {
          _upvotes = response['upvotes'] as int? ?? 0;
          _hasUpvoted = response['has_upvoted'] as bool? ?? false;
          _hasDiscordUpvoted = response['has_discord_upvoted'] as bool? ?? false;
          _isLoadingReactions = false;
          print('Set _hasUpvoted to: $_hasUpvoted, _hasDiscordUpvoted: $_hasDiscordUpvoted'); // Debug
        });
      }
    } catch (e) {
      print('Error loading reactions: $e'); // Debug
      // Silently fail - not critical
      setState(() {
        _isLoadingReactions = false;
      });
    }
  }

  Future<void> _toggleUpvote() async {
    final messageId = widget.meme['message_id'] as String?;
    if (messageId == null || _isUpvoting) return;

    setState(() {
      _isUpvoting = true;
    });

    try {
      final response = await ApiService().upvoteMeme(messageId);
      if (response['success'] == true) {
        final action = response['action'] as String?;

        // After toggling, fetch the FULL reaction count (custom + Discord)
        final reactionsResponse =
            await ApiService().getMemeReactions(messageId);
        if (reactionsResponse['success'] == true) {
          setState(() {
            _hasUpvoted = reactionsResponse['has_upvoted'] as bool? ?? false;
            _upvotes = reactionsResponse['upvotes'] as int? ??
                0; // Total count (custom + Discord)
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(action == 'added' ? 'Upvoted! 👍' : 'Upvote removed'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle upvote: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpvoting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.meme['image_url'] as String?;
    final title = widget.meme['title'] as String? ?? 'Untitled Meme';
    final author = widget.meme['author'] as String? ?? 'Unknown';
    final score = widget.meme['score'] as int? ?? 0;
    final source = widget.meme['source'] as String? ?? 'Unknown';
    final url = widget.meme['url'] as String?;
    final timestamp = widget.meme['timestamp'] as String?;
    final isCustom = widget.meme['is_custom'] as bool? ?? false;
    final messageId = widget.meme['message_id'] as String?;

    DateTime? postedDate;
    if (timestamp != null) {
      try {
        postedDate = DateTime.parse(timestamp);
      } catch (e) {
        // Ignore parse error
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meme Details'),
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop({'upvotes': _upvotes});
          },
        ),
        actions: [
          if (url != null && url.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open Original',
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Meme Image
            if (imageUrl != null)
              Hero(
                tag: 'meme_${widget.meme['message_id']}',
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            size: 64, color: Colors.grey),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 300,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image_not_supported,
                      size: 64, color: Colors.grey),
                ),
              ),

            // Meme Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon:
                                isCustom ? Icons.person : Icons.account_circle,
                            label: isCustom ? 'Created by' : 'Author',
                            value: author,
                          ),
                          if (!isCustom) ...[
                            const Divider(height: 24),
                            _InfoRow(
                              icon: Icons.thumb_up,
                              label: 'Upvotes',
                              value: '$score',
                            ),
                          ],
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.source,
                            label: 'Source',
                            value: source,
                          ),
                          if (postedDate != null) ...[
                            const Divider(height: 24),
                            _InfoRow(
                              icon: Icons.calendar_today,
                              label: 'Posted',
                              value: _formatDate(postedDate),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      // Upvote Button
                      Expanded(
                        child: Tooltip(
                          message: messageId == null
                              ? 'Meme wird noch verarbeitet...'
                              : _hasDiscordUpvoted
                                  ? 'Du hast bereits über Discord upgevotet'
                                  : '',
                          child: ElevatedButton.icon(
                            onPressed: (_isUpvoting || _isLoadingReactions || _hasDiscordUpvoted || messageId == null)
                                ? null
                                : _toggleUpvote,
                            icon: (_isUpvoting || _isLoadingReactions)
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(
                                    _hasUpvoted
                                        ? Icons.thumb_up
                                        : Icons.thumb_up_outlined,
                                  ),
                            label: Text('$_upvotes'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              // Only apply upvoted style after loading is complete
                              backgroundColor: (!_isLoadingReactions && _hasUpvoted)
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : null,
                              foregroundColor: (!_isLoadingReactions && _hasUpvoted)
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      if (url != null && url.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Original'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays >= 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays >= 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
