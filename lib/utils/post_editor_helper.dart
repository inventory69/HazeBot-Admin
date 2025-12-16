import 'package:flutter/material.dart';
import '../models/community_post.dart';
import '../models/post_editor_result.dart';
import '../widgets/create_edit_post_sheet.dart';

/// Show post creation/editing UI in bottom sheet (mobile) or dialog (desktop)
///
/// [context] - BuildContext
/// [post] - Optional post to edit (null = create new post)
///
/// Returns PostEditorResult with success status and message/error
Future<PostEditorResult?> showPostEditor(BuildContext context,
    {CommunityPost? post}) async {
  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 600;

  if (isMobile) {
    // Mobile: Bottom Sheet with drag handle
    return await showModalBottomSheet<PostEditorResult>(
      context: context,
      isScrollControlled: true, // Allow full-height sheet
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9, // Start at 90% height
        minChildSize: 0.5, // Can drag down to 50%
        maxChildSize: 0.95, // Can drag up to 95%
        expand: false,
        builder: (context, scrollController) => CreateEditPostSheet(
          post: post,
          scrollController: scrollController,
        ),
      ),
    );
  } else {
    // Desktop: Dialog with fixed size
    return await showDialog<PostEditorResult>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 700,
          ),
          child: CreateEditPostSheet(post: post),
        ),
      ),
    );
  }
}
