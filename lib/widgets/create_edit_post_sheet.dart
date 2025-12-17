import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/community_post.dart';
import '../providers/community_posts_provider.dart';
import '../services/permission_service.dart';
import 'markdown_toolbar.dart';

/// Reusable sheet/dialog for creating or editing community posts
/// Can be used in bottom sheet (mobile) or dialog (desktop)
class CreateEditPostSheet extends StatefulWidget {
  final CommunityPost? post; // null = create mode, not-null = edit mode
  final ScrollController? scrollController; // For bottom sheet drag

  const CreateEditPostSheet({
    super.key,
    this.post,
    this.scrollController,
  });

  @override
  State<CreateEditPostSheet> createState() => _CreateEditPostSheetState();
}

class _CreateEditPostSheetState extends State<CreateEditPostSheet> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedImage;
  String? _imageBase64;
  bool _isAnnouncement = false;
  bool _isSubmitting = false;
  bool _showPreview = false;
  bool _removeExistingImage = false; // For edit: user wants to remove image

  static const int _maxContentLength = 2000;

  bool get _isEditMode => widget.post != null;

  /// Check if user has entered any content that would be lost
  bool get _hasUnsavedContent {
    final hasText = _contentController.text.trim().isNotEmpty;
    final hasNewImage = _selectedImage != null;

    if (_isEditMode) {
      // In edit mode, check if anything changed
      final textChanged =
          _contentController.text.trim() != (widget.post!.content ?? '').trim();
      final imageChanged = _removeExistingImage || hasNewImage;
      return textChanged || imageChanged;
    }

    // In create mode, any content counts
    return hasText || hasNewImage;
  }

  /// Show confirmation dialog before closing with unsaved content
  Future<bool> _confirmClose() async {
    if (!_hasUnsavedContent) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Änderungen verwerfen?'),
        content: const Text(
          'Dein Text und Bilder gehen verloren, wenn du jetzt abbrichst.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Weiter schreiben'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  void initState() {
    super.initState();

    // If editing, pre-fill data
    if (_isEditMode) {
      _contentController.text = widget.post!.content ?? '';
      _isAnnouncement = widget.post!.isAnnouncement;
      // Note: Existing image URL is shown via widget.post.imageUrl
      // _imageBase64 is only used for NEW images
    }
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
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // Convert to base64
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);

        setState(() {
          _selectedImage = image;
          _imageBase64 = base64String;
          _removeExistingImage = false; // New image selected
        });

        debugPrint('📷 Image selected: ${image.name} (${bytes.length} bytes)');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Remove selected image (new image in create/edit)
  void _removeNewImage() {
    setState(() {
      _selectedImage = null;
      _imageBase64 = null;
    });
  }

  /// Remove existing image (edit mode only)
  void _removeExistingImageAction() {
    setState(() {
      _removeExistingImage = true;
    });
  }

  /// Undo remove existing image
  void _undoRemoveExistingImage() {
    setState(() {
      _removeExistingImage = false;
    });
  }

  /// Validate and submit post
  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    final provider =
        Provider.of<CommunityPostsProvider>(context, listen: false);

    // Validation
    final hasNewImage = _imageBase64 != null;
    final hasExistingImage =
        _isEditMode && widget.post!.imageUrl != null && !_removeExistingImage;
    final hasAnyImage = hasNewImage || hasExistingImage;

    if (content.isEmpty && !hasAnyImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add content or an image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (content.length > _maxContentLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Content too long (${content.length}/$_maxContentLength characters)',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      bool success;

      if (_isEditMode) {
        // UPDATE existing post
        String? imageToSend;
        if (_removeExistingImage) {
          imageToSend = ''; // Empty string = remove image
        } else if (_imageBase64 != null) {
          imageToSend = _imageBase64; // New image
        }
        // else: null = keep existing image

        success = await provider.updatePost(
          postId: widget.post!.id,
          content: content.isNotEmpty ? content : null,
          imageBase64: imageToSend,
        );
      } else {
        // CREATE new post
        success = await provider.createPost(
          content: content.isNotEmpty ? content : null,
          imageBase64: _imageBase64,
          isAnnouncement: _isAnnouncement,
        );
      }

      if (mounted) {
        if (success) {
          final message = _isEditMode
              ? '✏️ Post updated!'
              : _isAnnouncement
                  ? '📢 Announcement posted! ✨ +15 XP'
                  : '✨ Post created! +15 XP';

          // Close sheet with bool (type-safe for BottomSheet)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });

          // Show success snackbar after sheet closes
          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text(message)),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });
        } else {
          final error = provider.lastError ??
              (_isEditMode ? 'Failed to update post' : 'Failed to create post');

          // Close sheet with false for error
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context, false);
            }
          });

          // Show error snackbar after sheet closes
          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionService = Provider.of<PermissionService>(context);
    final canCreateAnnouncement = permissionService.hasPermission('all');
    final contentLength = _contentController.text.length;

    // Determine if existing image should be shown
    final showExistingImage = _isEditMode &&
        widget.post!.imageUrl != null &&
        !_removeExistingImage &&
        _selectedImage == null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldClose = await _confirmClose();
        if (shouldClose && mounted) {
          Navigator.pop(context);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with drag handle and title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Close button
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          final shouldClose = await _confirmClose();
                          if (shouldClose && mounted) {
                            Navigator.pop(context);
                          }
                        },
                ),
                const SizedBox(width: 8),
                // Title
                Text(
                  _isEditMode ? 'Edit Post' : 'Create Post',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // Submit button
                if (!_isSubmitting)
                  FilledButton.icon(
                    onPressed: _submitPost,
                    icon: Icon(_isEditMode
                        ? Icons.check
                        : _isAnnouncement
                            ? Icons.campaign
                            : Icons.send),
                    label: Text(_isEditMode ? 'Update' : 'Post'),
                  )
                else
                  const SizedBox(
                    width: 100,
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16.0),
              children: [
                // Markdown Toolbar
                MarkdownToolbar(
                  controller: _contentController,
                  showPreview: _showPreview,
                  onPreviewToggle: () =>
                      setState(() => _showPreview = !_showPreview),
                ),

                const SizedBox(height: 12),

                // Content TextField or Preview
                if (!_showPreview) ...[
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: 'What\'s on your mind?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: '$contentLength/$_maxContentLength',
                      helperText:
                          'Add text content (optional if image is provided)\nUse toolbar for formatting',
                    ),
                    maxLines: 8,
                    maxLength: _maxContentLength,
                    enabled: !_isSubmitting,
                    onChanged: (value) => setState(() {}),
                    autofocus: !_isEditMode, // Auto-focus in create mode
                  ),
                ] else ...[
                  // Markdown Preview
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _contentController.text.isEmpty
                        ? Center(
                            child: Text(
                              'Preview will appear here',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: MarkdownBody(
                              data: _prepareMarkdown(_contentController.text),
                              styleSheet: MarkdownStyleSheet(
                                p: Theme.of(context).textTheme.bodyMedium,
                                strong: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                em: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                code: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                    ),
                                a: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                              ),
                            ),
                          ),
                  ),
                ],

                const SizedBox(height: 24),

                // Image Section
                if (showExistingImage) ...[
                  // Show existing image (edit mode)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Existing image from URL
                        Image.network(
                          widget.post!.imageUrl!,
                          fit: BoxFit.cover,
                          height: 200,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 48),
                              ),
                            );
                          },
                        ),
                        // Remove button
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Current image',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text('Change'),
                                    onPressed:
                                        _isSubmitting ? null : _pickImage,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: _isSubmitting
                                        ? null
                                        : _removeExistingImageAction,
                                    tooltip: 'Remove image',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_removeExistingImage) ...[
                  // Show undo option when user removed existing image
                  Card(
                    color: Colors.red.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Image will be removed'),
                          ),
                          TextButton(
                            onPressed:
                                _isSubmitting ? null : _undoRemoveExistingImage,
                            child: const Text('UNDO'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Allow adding new image
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Add New Image'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ] else if (_selectedImage == null) ...[
                  // No image selected - show add button
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(_isEditMode ? 'Add New Image' : 'Add Image'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ] else ...[
                  // New image selected - show preview
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // New image preview
                        if (kIsWeb)
                          Image.network(
                            _selectedImage!.path,
                            fit: BoxFit.cover,
                            height: 200,
                          )
                        else
                          Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                            height: 200,
                          ),
                        // Remove button
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedImage!.name,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed:
                                    _isSubmitting ? null : _removeNewImage,
                                tooltip: 'Remove image',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Announcement Toggle (Admin/Mod only, CREATE mode only)
                if (!_isEditMode && canCreateAnnouncement) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isAnnouncement
                          ? Colors.orange.withOpacity(0.08)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: _isAnnouncement
                          ? Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isAnnouncement
                                ? Colors.orange.withOpacity(0.15)
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isAnnouncement
                                ? Icons.campaign
                                : Icons.campaign_outlined,
                            color: _isAnnouncement
                                ? Colors.orange
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Announcement',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _isAnnouncement
                                          ? Colors.orange
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pin this post and highlight it to all users',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Switch
                        Switch(
                          value: _isAnnouncement,
                          onChanged: _isSubmitting
                              ? null
                              : (value) =>
                                  setState(() => _isAnnouncement = value),
                          activeColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Info Box
                Card(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEditMode
                                  ? 'Edit Guidelines'
                                  : 'Posting Guidelines',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isEditMode
                              ? '• Update text and/or image\n'
                                  '• Max 2000 characters\n'
                                  '• Changes sync to Discord\n'
                                  '• Edits are logged'
                              : '• Add text, image, or both\n'
                                  '• Max 2000 characters\n'
                                  '• Posts will appear in Discord\n'
                                  '• You can edit within 24 hours',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
