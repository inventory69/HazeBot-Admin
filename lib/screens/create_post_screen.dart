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

      final result = await showPostEditor(context);
      
      if (mounted) {
        // Pop back to previous screen
        Navigator.pop(context);
        
        // Show result message if available
        if (result != null) {
          if (result.success && result.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(result.message!)),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else if (!result.success && result.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.error!),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
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
