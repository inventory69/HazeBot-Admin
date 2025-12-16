import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/community_post.dart';
import '../services/community_posts_service.dart';
import '../services/api_service.dart';
import '../screens/profile_screen.dart';

/// Reusable widget to display a community post
/// Styled to match HazeHub meme/rankup/levelup cards
class CommunityPostCard extends StatefulWidget {
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
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  bool _isExpanded = false;

  // Calculate dynamic font size based on content length
  double _getContentFontSize(String content, bool isMobile) {
    final baseSize = isMobile ? 15.0 : 16.0;
    if (content.length < 100) return baseSize + 1; // Short: 16/17
    if (content.length < 300) return baseSize; // Medium: 15/16
    if (content.length < 500) return baseSize - 1; // Long: 14/15
    return baseSize - 2; // Very long: 13/14
  }

  // Check if content needs "Read More" button
  bool _needsReadMore(String content) {
    return content.length > 300 || content.split('\n').length > 5;
  }

  // Truncate content for "Read More" state (preserving markdown blocks)
  String _truncateContent(String content) {
    final lines = content.split('\n');

    // Check if we need to truncate by line count
    if (lines.length > 5) {
      // Take first 5 lines, but check if we're inside a code block
      final truncatedLines = lines.take(5).toList();
      final truncatedText = truncatedLines.join('\n');

      // Count opening ``` markers (multi-line code blocks)
      final tripleBacktickCount = '```'.allMatches(truncatedText).length;

      // Count single ` markers (inline code)
      final singleBacktickCount =
          '`'.allMatches(truncatedText).length - (tripleBacktickCount * 3);

      // If odd number of triple backticks, we're inside a multi-line code block
      if (tripleBacktickCount.isOdd) {
        return truncatedText + '\n```\n...';
      }

      // If odd number of single backticks, we're inside inline code
      if (singleBacktickCount.isOdd) {
        return truncatedText + '`\n...';
      }

      return truncatedText + '\n...';
    }

    // Check if we need to truncate by character count
    if (content.length > 300) {
      var truncateAt = 300;
      final substring = content.substring(0, truncateAt);

      // Count opening ``` markers (multi-line code blocks)
      final tripleBacktickCount = '```'.allMatches(substring).length;

      // Count single ` markers (inline code)
      final singleBacktickCount =
          '`'.allMatches(substring).length - (tripleBacktickCount * 3);

      // If odd number of triple backticks, we're inside a multi-line code block
      if (tripleBacktickCount.isOdd) {
        return substring + '\n```\n...';
      }

      // If odd number of single backticks, we're inside inline code
      if (singleBacktickCount.isOdd) {
        return substring + '`...';
      }

      return substring + '...';
    }

    return content;
  }

  /// Convert plain newlines to Markdown hard line breaks
  String _prepareMarkdown(String text) {
    // Replace single newlines with two spaces + newline (Markdown hard break)
    // But preserve double newlines (paragraph breaks)
    return text.replaceAllMapped(
      RegExp(r'([^\n])\n(?!\n)'),
      (match) => '${match.group(1)}  \n',
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final colorScheme = Theme.of(context).colorScheme;

    // Match meme card styling: subtle tonal container
    final isMonet = colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;

    // Color coding: Announcements = yellow/orange, Admin posts = pink, Normal posts = standard
    Color cardColor;
    if (post.isAnnouncement) {
      // Announcements are yellow/orange
      cardColor = Colors.orange.withOpacity(0.12);
    } else if (post.postType == 'admin') {
      // Admin posts (non-announcements) are pink
      cardColor = Colors.pink.withOpacity(0.12);
    } else {
      // Normal user posts
      cardColor = isMonet
          ? colorScheme.primaryContainer.withOpacity(0.18)
          : colorScheme.surface;
    }

    final isMobile = widget.isMobile;
    final canEdit = widget.canEdit;
    final canDelete = widget.canDelete;
    final showActions = widget.showActions;

    return Card(
      color: cardColor,
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      elevation: 0, // Flat card like memes
      child: InkWell(
        onTap: null, // TODO: Navigate to detail view if needed
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.only(
            left: isMobile ? 8 : 12,
            right: isMobile ? 8 : 12,
            top: isMobile ? 10 : 12,
            bottom: isMobile ? 14 : 18,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail (if exists) - matches meme card layout
              if (post.hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl:
                        CommunityPostsService().getImageUrl(post.imageUrl!),
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
                      child:
                          Icon(Icons.image, size: 32, color: Colors.grey[600]),
                    ),
                  ),
                ),

              SizedBox(width: isMobile ? 8 : 12),

              // Content area
              Expanded(
                child: Stack(
                  children: [
                    // Main content column
                    Padding(
                      padding: EdgeInsets.only(
                          right:
                              showActions && (canEdit || canDelete) ? 60 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Compact author row with avatar and role badge
                          Row(
                            children: [
                              // Smaller avatar (more compact) - clickable
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProfileScreen(userId: post.authorId),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: isMobile ? 8 : 10,
                                  backgroundColor: colorScheme.primaryContainer,
                                  backgroundImage: post.authorAvatar != null &&
                                          post.authorAvatar!.isNotEmpty
                                      ? NetworkImage(post.authorAvatar!)
                                      : null,
                                  onBackgroundImageError:
                                      post.authorAvatar != null
                                          ? (exception, stackTrace) {
                                              debugPrint(
                                                  '❌ Avatar load failed for ${post.authorName}: ${post.authorAvatar}');
                                              debugPrint('Error: $exception');
                                            }
                                          : null,
                                  child: post.authorAvatar == null ||
                                          post.authorAvatar!.isEmpty
                                      ? Icon(
                                          Icons.person,
                                          size: isMobile ? 10 : 12,
                                          color: colorScheme.onPrimaryContainer,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Username (smaller, more subtle)
                              Flexible(
                                child: Text(
                                  post.authorName,
                                  style: TextStyle(
                                    fontSize: isMobile ? 10 : 11,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Role Badge (Admin/Mod)
                              if (post.postType == 'admin' ||
                                  post.postType == 'mod') ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: post.postType == 'admin'
                                        ? Colors.pink.withOpacity(0.2)
                                        : Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    post.postType == 'admin' ? 'ADMIN' : 'MOD',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: post.postType == 'admin'
                                          ? Colors.pink[700]
                                          : Colors.blue[700],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Announcement badge + timestamp (very compact and subtle)
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              if (post.isAnnouncement) ...[
                                Icon(
                                  Icons.campaign,
                                  size: 12,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Announcement',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  '${post.formattedDate}${post.wasEdited ? ' (edited)' : ''}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                    fontStyle: post.wasEdited
                                        ? FontStyle.italic
                                        : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // Content text with dynamic size and expandable (Markdown support)
                          if (post.hasContent) ...[
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MarkdownBody(
                                  data: _prepareMarkdown(_isExpanded ||
                                          !_needsReadMore(post.content!)
                                      ? post.content!
                                      : _truncateContent(post.content!)),
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      fontSize: _getContentFontSize(
                                          post.content!, isMobile),
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                      height: post.content!.length > 300
                                          ? 1.3
                                          : 1.4,
                                    ),
                                    strong: TextStyle(
                                      fontSize: _getContentFontSize(
                                          post.content!, isMobile),
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                    em: TextStyle(
                                      fontSize: _getContentFontSize(
                                          post.content!, isMobile),
                                      fontStyle: FontStyle.italic,
                                      color: colorScheme.onSurface,
                                    ),
                                    code: TextStyle(
                                      fontSize: _getContentFontSize(
                                              post.content!, isMobile) -
                                          1,
                                      fontFamily: 'monospace',
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                      color: colorScheme.onSurface,
                                    ),
                                    a: TextStyle(
                                      fontSize: _getContentFontSize(
                                          post.content!, isMobile),
                                      color: colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                    listBullet: TextStyle(
                                      fontSize: _getContentFontSize(
                                          post.content!, isMobile),
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  onTapLink: (text, href, title) {
                                    // TODO: Open links in browser
                                    debugPrint('Link tapped: $href');
                                  },
                                ),
                                // "Read More" / "Show Less" button
                                if (_needsReadMore(post.content!)) ...[
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isExpanded = !_isExpanded;
                                      });
                                    },
                                    child: Text(
                                      _isExpanded ? 'Show less' : 'Read more',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.4),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Posted in Discord',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Action buttons - fixed position in top right corner
                    if (showActions && (canEdit || canDelete))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canEdit && post.isEditable)
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: widget.onEdit,
                                tooltip: 'Edit',
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                color: colorScheme.primary,
                              ),
                            if (canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: widget.onDelete,
                                tooltip: 'Delete',
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                color: Colors.red,
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
