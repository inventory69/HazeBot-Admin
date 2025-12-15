import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/community_post.dart';
import '../services/community_posts_service.dart';

/// Reusable widget to display a community post
/// Shows author info, content, image, and action buttons
class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canEdit;
  final bool canDelete;
  final bool showActions;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onEdit,
    this.onDelete,
    this.canEdit = false,
    this.canDelete = false,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Determine card color based on post type
    Color? cardColor;
    if (post.isAnnouncement) {
      cardColor = Colors.orange.withOpacity(0.1);
    } else if (post.postType == 'admin') {
      cardColor = Colors.blue.withOpacity(0.05);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Author info and actions
            Row(
              children: [
                // Author Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primary,
                  child: post.authorAvatar != null
                      ? CachedNetworkImage(
                          imageUrl: post.authorAvatar!,
                          imageBuilder: (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: colorScheme.onPrimary,
                        ),
                ),
                const SizedBox(width: 12),

                // Author name and timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.authorName,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (post.isAnnouncement) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '📢 Announcement',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        post.formattedDate,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (post.wasEdited)
                        Text(
                          '(edited)',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),

                // Action buttons
                if (showActions) ...[
                  if (canEdit && post.isEditable)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit post',
                      color: colorScheme.primary,
                    ),
                  if (canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete post',
                      color: Colors.red,
                    ),
                ],
              ],
            ),

            // Content
            if (post.hasContent) ...[
              const SizedBox(height: 12),
              Text(
                post.content!,
                style: textTheme.bodyMedium,
              ),
            ],

            // Image
            if (post.hasImage) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: CommunityPostsService().getImageUrl(post.imageUrl!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: colorScheme.surfaceVariant,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: colorScheme.errorContainer,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Discord info (for debugging)
            if (post.discordMessageId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.discord,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Posted in Discord',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact version of CommunityPostCard for list views
class CommunityPostCardCompact extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onTap;

  const CommunityPostCardCompact({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Thumbnail or icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: post.hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: CommunityPostsService()
                              .getImageUrl(post.imageUrl!),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image),
                        ),
                      )
                    : Icon(
                        post.isAnnouncement ? Icons.campaign : Icons.article,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 12),

              // Content preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.authorName,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (post.isAnnouncement) ...[
                          const SizedBox(width: 6),
                          const Text(
                            '📢',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          post.formattedDate,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (post.hasContent)
                      Text(
                        post.content!,
                        style: textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (!post.hasContent)
                      Text(
                        '[Image only]',
                        style: textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
