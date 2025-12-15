import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/community_posts_provider.dart';
import '../services/permission_service.dart';

/// Screen for creating a new community post
/// Users can add text content and/or upload an image
/// Admins/Mods can mark posts as announcements
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  XFile? _selectedImage;
  String? _imageBase64;
  bool _isAnnouncement = false;
  bool _isSubmitting = false;

  static const int _maxContentLength = 2000;

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

  /// Remove selected image
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBase64 = null;
    });
  }

  /// Validate and submit post
  Future<void> _submitPost() async {
    final content = _contentController.text.trim();

    // Validation
    if (content.isEmpty && _imageBase64 == null) {
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
      final provider = Provider.of<CommunityPostsProvider>(
        context,
        listen: false,
      );

      final success = await provider.createPost(
        content: content.isNotEmpty ? content : null,
        imageBase64: _imageBase64,
        isAnnouncement: _isAnnouncement,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(_isAnnouncement
                      ? '📢 Announcement posted!'
                      : '✨ Post created!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true = post created
        } else {
          // Show error from provider
          final error = provider.lastError ?? 'Failed to create post';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          // Submit button
          if (!_isSubmitting)
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: 'Post',
              onPressed: _submitPost,
            ),
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Content TextField
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '$contentLength/$_maxContentLength',
                helperText: 'Add text content (optional if image is provided)',
              ),
              maxLines: 8,
              maxLength: _maxContentLength,
              enabled: !_isSubmitting,
              onChanged: (value) => setState(() {}),
            ),

            const SizedBox(height: 24),

            // Image Section
            if (_selectedImage == null) ...[
              // Add Image Button
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Add Image'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ] else ...[
              // Image Preview
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image
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
                          Text(
                            _selectedImage!.name,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: _isSubmitting ? null : _removeImage,
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

            // Announcement Toggle (Admin/Mod only)
            if (canCreateAnnouncement) ...[
              Card(
                color: _isAnnouncement
                    ? Colors.orange.withOpacity(0.1)
                    : null,
                child: SwitchListTile(
                  title: const Text('📢 Announcement'),
                  subtitle: const Text(
                    'Pin this post and highlight it to all users',
                  ),
                  value: _isAnnouncement,
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _isAnnouncement = value),
                  secondary: Icon(
                    _isAnnouncement ? Icons.campaign : Icons.campaign_outlined,
                    color: _isAnnouncement ? Colors.orange : null,
                  ),
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
                          'Posting Guidelines',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Add text, image, or both\n'
                      '• Max 2000 characters\n'
                      '• Posts will appear in Discord\n'
                      '• You can edit within 24 hours',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitPost,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isAnnouncement ? Icons.campaign : Icons.send),
              label: Text(_isSubmitting
                  ? 'Posting...'
                  : _isAnnouncement
                      ? 'Post Announcement'
                      : 'Post'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: _isAnnouncement ? Colors.orange : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
