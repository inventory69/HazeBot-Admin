import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/discord_auth_service.dart';
import '../../services/api_service.dart' show getProxiedImageUrl;
import '../../providers/data_cache_provider.dart';

/// Format Lemmy community to user-friendly display
/// Input: "lemmy.world@memes" (instance@community)
/// Output: "memes@lemmy.world" (community@instance)
String formatLemmyDisplay(String community) {
  if (community.contains('@')) {
    final parts = community.split('@');
    if (parts.length == 2) {
      final instance = parts[0];
      final communityName = parts[1];
      // Return user-friendly format: community@instance
      return '$communityName@$instance';
    }
  }
  return community;
}

/// ❌ DEPRECATED: Image proxy not needed anymore
/// Backend already converts Reddit/Imgur URLs to HTTPS Discord CDN URLs
/// before returning them to the frontend. Direct URL usage works fine.
///
/// Historical note: This was needed when backend returned raw Reddit HTTP URLs,
/// but now the bot uploads images to Discord and returns CDN URLs (HTTPS).
///
/// Keep this code for reference in case we need it again in the future.
/*
String getProxiedImageUrl(String originalUrl) {
  // Proxy external images (Reddit, Imgur, Imgflip)
  if (originalUrl.contains('i.redd.it') ||
      originalUrl.contains('i.imgur.com') ||
      originalUrl.contains('preview.redd.it') ||
      originalUrl.contains('external-preview.redd.it') ||
      originalUrl.contains('imgflip.com')) {
    // Use our backend proxy from environment
    final proxyUrl = dotenv.env['IMAGE_PROXY_URL'] ??
        '${dotenv.env['API_BASE_URL']}/proxy/image';
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return '$proxyUrl?url=$encodedUrl';
  }
  // For other URLs, return as-is
  return originalUrl;
}
*/

class MemeConfigScreen extends StatefulWidget {
  const MemeConfigScreen({super.key});

  @override
  State<MemeConfigScreen> createState() => _MemeConfigScreenState();
}

class _MemeConfigScreenState extends State<MemeConfigScreen> {
  bool _isLoadingRandomMeme = false;
  bool _isSendingMeme = false;
  bool _isLoadingSources = false;
  bool _isLoadingSourceMeme = false;
  bool _randomMemeSent = false; // Track if random meme was sent
  bool _sourceMemeSent = false; // Track if source meme was sent
  Map<String, dynamic>? _randomMemeData;
  Map<String, dynamic>? _sourceMemeData;
  String? _errorMessage;
  List<String> _subreddits = [];
  List<String> _lemmyCommunities = [];
  final TextEditingController _sourceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMemeSources();
  }

  @override
  void dispose() {
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _loadMemeSources() async {
    setState(() {
      _isLoadingSources = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.getMemeSources();

      setState(() {
        _subreddits = List<String>.from(result['sources']['subreddits'] ?? []);
        _lemmyCommunities = List<String>.from(result['sources']['lemmy'] ?? []);
        _isLoadingSources = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading meme sources: $e';
        _isLoadingSources = false;
      });
    }
  }

  Future<void> _getMemeFromSource() async {
    final source = _sourceController.text.trim();
    if (source.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a source (subreddit or Lemmy community)';
      });
      return;
    }

    setState(() {
      _isLoadingSourceMeme = true;
      _errorMessage = null;
      _sourceMemeData = null;
      _sourceMemeSent = false; // Reset sent status for new meme
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.getMemeFromSource(source);

      setState(() {
        _sourceMemeData = result['meme'];
        _isLoadingSourceMeme = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting meme from source: $e';
        _isLoadingSourceMeme = false;
      });
    }
  }

  Future<void> _getRandomMeme() async {
    setState(() {
      _isLoadingRandomMeme = true;
      _errorMessage = null;
      _randomMemeData = null;
      _randomMemeSent = false; // Reset sent status for new meme
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.getRandomMeme();

      setState(() {
        _randomMemeData = result['meme'];
        _isLoadingRandomMeme = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting random meme: $e';
        _isLoadingRandomMeme = false;
      });
    }
  }

  Future<void> _sendMemeToDiscord(Map<String, dynamic> memeData,
      {bool isRandomMeme = false}) async {
    setState(() {
      _isSendingMeme = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.sendMemeToDiscord(memeData);

      setState(() {
        _isSendingMeme = false;
        // Mark the appropriate meme as sent
        if (isRandomMeme) {
          _randomMemeSent = true;
        } else {
          _sourceMemeSent = true;
        }
      });

      // Show success message BEFORE cache update to prevent widget disposal race
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(result['message'] ?? 'Meme sent to Discord!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

      // Optimistically add meme to dashboard cache for immediate display
      if (mounted) {
        debugPrint('🎨 Adding meme to dashboard cache...');
        final cacheProvider =
            Provider.of<DataCacheProvider>(context, listen: false);
        final discordAuth =
            Provider.of<DiscordAuthService>(context, listen: false);

        // Use the memeData that was sent (already contains all necessary info)
        // Note: Random memes use 'url' field for image, while cached memes use 'image_url'
        final optimisticData = {
          'image_url': memeData['image_url'] ??
              memeData['url'], // Try image_url first, fallback to url
          'title': memeData['title'] ?? 'Meme',
          'author': memeData['author'] ?? 'Unknown',
          'score': memeData['score'] ?? 0,
          'is_custom': memeData['is_custom'] ?? false,
          'timestamp': DateTime.now().toIso8601String(),
          // Extract message_id from API response if available
          'message_id': result['message_id'] as String?,
          'upvotes': 0, // New meme starts with 0 upvotes
          // Add requester from current user (will match Discord embed field)
          'requester': discordAuth.userInfo?['username'] ?? 'You',
        };
        debugPrint('🎨 Meme data: $optimisticData');
        cacheProvider.addMemeOptimistically(optimisticData);
        debugPrint(
            '🎨 Meme added to cache, notifyListeners should have been called');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sending meme to Discord: $e';
        _isSendingMeme = false;
      });
    }
  }

  /// Format source for display (handles both Reddit and Lemmy)
  String _formatSourceDisplay(String source) {
    // If it starts with "lemmy:", format it
    if (source.startsWith('lemmy:')) {
      final cleaned = source.substring(6); // Remove "lemmy:"
      if (cleaned.contains('@')) {
        final parts = cleaned.split('@');
        if (parts.length == 2) {
          final instance = parts[0];
          final community = parts[1];
          // Return user-friendly format: community@instance
          return '$community@$instance';
        }
      }
      return cleaned;
    }
    // For Reddit, add r/ prefix if not present
    if (!source.startsWith('r/') && !source.contains('@')) {
      return 'r/$source';
    }
    return source;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 12.0 : 24.0;
        final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
            ThemeData.light().colorScheme.surfaceContainerHigh;
        final cardColor = isMonet
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
            : Theme.of(context).colorScheme.surface;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Memes'),
            actions: [
              IconButton(
                icon: _isLoadingSources
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: _isLoadingSources ? null : _loadMemeSources,
                tooltip: 'Refresh Sources',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Box
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: isMobile ? 18 : 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Test meme functions before they go live. Random memes are fetched from configured sources.',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // Random Meme Card
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 10 : 12),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.shuffle,
                                color: Colors.purple,
                                size: isMobile ? 24 : 28,
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Random Meme',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isMobile ? 18 : null,
                                        ),
                                  ),
                                  SizedBox(height: isMobile ? 2 : 4),
                                  Text(
                                    'Get a random meme from configured Reddit and Lemmy sources',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: isMobile ? 12 : null,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed:
                              _isLoadingRandomMeme ? null : _getRandomMeme,
                          icon: _isLoadingRandomMeme
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.casino),
                          label: Text(_isLoadingRandomMeme
                              ? 'Fetching Meme...'
                              : 'Get Random Meme'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                          ),
                        ),
                        if (_randomMemeData != null) ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Random Meme Image from Reddit/Lemmy - needs proxy for CORS
                                Image.network(
                                  getProxiedImageUrl(_randomMemeData!['url']),
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHigh,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .errorContainer,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image,
                                                size: 48,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Failed to load image',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onErrorContainer,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Meme Info
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _randomMemeData!['title'] ?? 'Untitled',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildInfoChip(
                                            context,
                                            icon: Icons.forum,
                                            // ✅ Format source display (handles both Reddit and Lemmy)
                                            label: _formatSourceDisplay(
                                                _randomMemeData!['subreddit'] ??
                                                    'Unknown'),
                                            color: Colors.deepOrange,
                                          ),
                                          _buildInfoChip(
                                            context,
                                            icon: Icons.person,
                                            label:
                                                'u/${_randomMemeData!['author'] ?? 'Unknown'}',
                                            color: Colors.blue,
                                          ),
                                          _buildInfoChip(
                                            context,
                                            icon: Icons.arrow_upward,
                                            label:
                                                '${_randomMemeData!['score'] ?? 0} upvotes',
                                            color: Colors.green,
                                          ),
                                          if (_randomMemeData!['nsfw'] == true)
                                            _buildInfoChip(
                                              context,
                                              icon: Icons.warning,
                                              label: 'NSFW',
                                              color: Colors.red,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton.icon(
                                              onPressed: (_isSendingMeme ||
                                                      _randomMemeSent)
                                                  ? null
                                                  : () => _sendMemeToDiscord(
                                                      _randomMemeData!,
                                                      isRandomMeme: true),
                                              icon: _isSendingMeme
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : _randomMemeSent
                                                      ? const Icon(
                                                          Icons.check_circle)
                                                      : const Icon(Icons.send),
                                              label: Text(_isSendingMeme
                                                  ? 'Sending...'
                                                  : _randomMemeSent
                                                      ? 'Sent to Discord'
                                                      : 'Send to Discord'),
                                              style: FilledButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          FilledButton.tonalIcon(
                                            onPressed: _getRandomMeme,
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('New Meme'),
                                            style: FilledButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Meme from Source Card
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 10 : 12),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.explore,
                                color: Colors.teal,
                                size: isMobile ? 24 : 28,
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Meme from Source',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isMobile ? 18 : null,
                                        ),
                                  ),
                                  SizedBox(height: isMobile ? 2 : 4),
                                  Text(
                                    'Fetch a meme from a specific subreddit or Lemmy community',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: isMobile ? 12 : null,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingSources)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else ...[
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Select Source',
                              prefixIcon: Icon(Icons.list),
                              border: OutlineInputBorder(),
                              helperText:
                                  'Choose from available subreddits and Lemmy communities',
                            ),
                            items: [
                              ..._subreddits.map((sub) => DropdownMenuItem(
                                    value: sub,
                                    child: Text(
                                      'r/$sub',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )),
                              ..._lemmyCommunities
                                  .map((comm) => DropdownMenuItem(
                                        value: comm,
                                        child: Text(
                                          formatLemmyDisplay(comm),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _sourceController.text = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _isLoadingSourceMeme
                                ? null
                                : _getMemeFromSource,
                            icon: _isLoadingSourceMeme
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download),
                            label: Text(_isLoadingSourceMeme
                                ? 'Fetching...'
                                : 'Fetch Meme'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                            ),
                          ),
                        ],
                        if (_sourceMemeData != null) ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Source Meme Image from Reddit/Lemmy - needs proxy for CORS
                                Image.network(
                                  getProxiedImageUrl(_sourceMemeData!['url']),
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHigh,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .errorContainer,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image,
                                                size: 48,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Failed to load image',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onErrorContainer,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _sourceMemeData!['title'] ?? 'Untitled',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildInfoChip(
                                            context,
                                            icon: Icons.forum,
                                            // ✅ Format source display (handles both Reddit and Lemmy)
                                            label: _formatSourceDisplay(
                                                _sourceMemeData!['subreddit'] ??
                                                    'Unknown'),
                                            color: Colors.deepOrange,
                                          ),
                                          _buildInfoChip(
                                            context,
                                            icon: Icons.person,
                                            label:
                                                'u/${_sourceMemeData!['author'] ?? 'Unknown'}',
                                            color: Colors.blue,
                                          ),
                                          _buildInfoChip(
                                            context,
                                            icon: Icons.arrow_upward,
                                            label:
                                                '${_sourceMemeData!['score'] ?? 0} upvotes',
                                            color: Colors.green,
                                          ),
                                          if (_sourceMemeData!['nsfw'] == true)
                                            _buildInfoChip(
                                              context,
                                              icon: Icons.warning,
                                              label: 'NSFW',
                                              color: Colors.red,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton.icon(
                                              onPressed: (_isSendingMeme ||
                                                      _sourceMemeSent)
                                                  ? null
                                                  : () => _sendMemeToDiscord(
                                                      _sourceMemeData!,
                                                      isRandomMeme: false),
                                              icon: _isSendingMeme
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : _sourceMemeSent
                                                      ? const Icon(
                                                          Icons.check_circle)
                                                      : const Icon(Icons.send),
                                              label: Text(_isSendingMeme
                                                  ? 'Sending...'
                                                  : _sourceMemeSent
                                                      ? 'Sent to Discord'
                                                      : 'Send to Discord'),
                                              style: FilledButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          FilledButton.tonalIcon(
                                            onPressed: _getMemeFromSource,
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('New Meme'),
                                            style: FilledButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Error Display
                if (_errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Error',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Info Card
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Information',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          icon: Icons.explore,
                          text:
                              'Meme from Source lets you test fetching from a specific subreddit or Lemmy community',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          icon: Icons.shuffle,
                          text:
                              'Random Meme fetches a meme from your configured Reddit subreddits and Lemmy communities',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          icon: Icons.schedule_send,
                          text:
                              'Daily Meme Test posts a meme to the configured channel immediately (bypasses schedule)',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          icon: Icons.send,
                          text:
                              'Sending a meme posts it to your Discord meme channel with full embed information',
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber[800],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'These functions interact with your live Discord bot. Use with caution in production mode.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.amber[900],
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(BuildContext context,
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
