import 'package:flutter/material.dart';

class ApiErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isOffline;

  const ApiErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sloth emoji (cute and calming)
            Text(
              '🦥',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 24),
            
            // Main message
            Text(
              isOffline 
                ? 'Taking it easy... 🌴'
                : 'Something went wrong... 🍃',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Secondary message
            Text(
              isOffline
                ? 'The server is taking a siesta.\nCome back when it\'s well rested!'
                : message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Snackbar variant for errors that don't need full screen
class ApiErrorSnackbar {
  static void show(BuildContext context, {bool isOffline = false}) {
    final message = isOffline
        ? '🦥 Server is taking a break... Try again in a moment!'
        : '🍃 Connection issue... But don\'t panic!';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
