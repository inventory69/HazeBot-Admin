import 'package:flutter/material.dart';
import '../utils/web_utils.dart';

class MemeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> meme;

  const MemeDetailScreen({super.key, required this.meme});

  @override
  Widget build(BuildContext context) {
    final imageUrl = meme['image_url'] as String?;
    final title = meme['title'] as String? ?? 'Untitled Meme';
    final author = meme['author'] as String? ?? 'Unknown';
    final score = meme['score'] as int? ?? 0;
    final source = meme['source'] as String? ?? 'Unknown';
    final url = meme['url'] as String?;
    final timestamp = meme['timestamp'] as String?;
    final isCustom = meme['is_custom'] as bool? ?? false;

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
        actions: [
          if (url != null && url.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open Original',
              onPressed: () {
                WebUtils.openInNewTab(url);
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
                tag: 'meme_${meme['message_id']}',
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
                  if (url != null && url.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          WebUtils.openInNewTab(url);
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('View Original'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
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
