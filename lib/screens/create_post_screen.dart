import 'package:flutter/material.dart';
import '../utils/post_editor_helper.dart';

/// Screen for creating a new community post
/// This is now a simple wrapper that shows the CreateEditPostSheet
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  @override
  void initState() {
    super.initState();
    // Show the editor immediately after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final result = await showPostEditor(context);
      if (mounted) {
        // Return to previous screen with result
        Navigator.pop(context, result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while waiting for sheet to open
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
