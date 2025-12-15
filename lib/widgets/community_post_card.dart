import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/community_post.dart';
import '../services/community_posts_service.dart';

/// Reusable widget to display a community post
/// Styled to match HazeHub meme/rankup/levelup cards
class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canEdit;
  final bool canDelete;
  final bool showActions;
  final bool isMobile;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onEdit,
    this.onDelete,
    this.canEdit = false,
    this.canDelete = false,
    this.showActions = true,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Match meme card styling: subtle tonal container
    final isMonet = colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    
    // Special coloring for announcements
    Color cardColor;
    if (post.isAnnouncement) {
      cardColor = Colors.orange.withOpacity(0.12);
    } else {
      cardColor = isMonet
          ? colorScheme.primaryContainer.withOpacity(0.18)
          : colorScheme.surface;
    }

    return Card(
      color: cardColor,
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      elevation: 0, // Flat card like memes
      child: InkWell(
        onTap: null, // TODO: Navigate to detail view if needed
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail (if exists) - matches meme card layout
              if (post.hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: CommunityPostsService().getImageUrl(post.imageUrl!),
                    width: isMobile ? 80 : 100,
                    height: isMobile ? 80 : 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: isMobile ? 80 : 100,
                      height: isMobile ? 80 : 100,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: isMobile ? 80 : 100,
                      height: isMobile ? 80 : 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.image, size: 32, color: Colors.grey[600]),
                    ),
                  ),
                ),
              
              SizedBox(width: isMobile ? 8 : 12),
              
              // Content area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author row with announcement badge
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.person,
                                  size: isMobile ? 14 : 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  post.authorName,
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action buttons
                        if (showActions && (canEdit || canDelete)) ...[
                          if (canEdit && post.isEditable)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: onEdit,
                              tooltip: 'Edit',
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              color: colorScheme.primary,
                            ),
                          if (canDelete)
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: onDelete,
                              tooltip: 'Delete',
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              color: Colors.red,
                            ),
                        ],
                      ],
                    ),
                    
                    // Announcement badge + timestamp
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (post.isAnnouncement) ...[
                          Icon(
                            Icons.campaign,
                            size: isMobile ? 14 : 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Announcement',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            '${post.formattedDate}${post.wasEdited ? ' (edited)' : ''}',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: Colors.grey[600],
                              fontStyle: post.wasEdited ? FontStyle.italic : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    // Content text
                    if (post.hasContent) ...[
                      const SizedBox(height: 6),
                      Text(
                        post.content!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: isMobile ? 14 : 15,
                            ),
                        maxLines: post.hasImage ? 2 : 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Discord indicator (subtle)
                    if (post.discordMessageId != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.discord,
                            size: 12,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Posted in Discord',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
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
