import 'package:flutter/material.dart';
import '../models/post_editor_result.dart';
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

      // Show post editor - result is now bool? (true=success, false=error, null=cancelled)
      await showPostEditor(context);
      
      if (mounted) {
        // Pop back to previous screen
        // Snackbar is now shown directly in the editor sheet
        Navigator.pop(context);
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
