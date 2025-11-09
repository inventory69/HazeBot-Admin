import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

/// Helper function to proxy external images through our backend to bypass CORS
String getProxiedImageUrl(String originalUrl) {
  // Proxy external images (Reddit, Imgur, Imgflip)
  if (originalUrl.contains('i.redd.it') ||
      originalUrl.contains('i.imgur.com') ||
      originalUrl.contains('preview.redd.it') ||
      originalUrl.contains('external-preview.redd.it') ||
      originalUrl.contains('imgflip.com')) {
    // Use our backend proxy
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return 'https://test-hazebot-admin.hzwd.xyz/api/proxy/image?url=$encodedUrl';
  }
  // For other URLs, return as-is
  return originalUrl;
}

class MemeConfigScreen extends StatefulWidget {
  const MemeConfigScreen({super.key});

  @override
  State<MemeConfigScreen> createState() => _MemeConfigScreenState();
}

class _MemeConfigScreenState extends State<MemeConfigScreen> {
  bool _isLoadingRandomMeme = false;
  bool _isLoadingDailyMeme = false;
  bool _isSendingMeme = false;
  bool _isLoadingSources = false;
  bool _isLoadingSourceMeme = false;
  Map<String, dynamic>? _randomMemeData;
  Map<String, dynamic>? _sourceMemeData;
  String? _dailyMemeResult;
  String? _errorMessage;
  List<String> _subreddits = [];
  List<String> _lemmyCommunities = [];
  String? _selectedSource;
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

  Future<void> _sendMemeToDiscord(Map<String, dynamic> memeData) async {
    setState(() {
      _isSendingMeme = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.sendMemeToDiscord(memeData);

      setState(() {
        _isSendingMeme = false;
      });

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
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sending meme to Discord: $e';
        _isSendingMeme = false;
      });
    }
  }

  Future<void> _testDailyMeme() async {
    setState(() {
      _isLoadingDailyMeme = true;
      _errorMessage = null;
      _dailyMemeResult = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.testDailyMeme();

      setState(() {
        _dailyMemeResult = result['message'] ?? result.toString();
        _isLoadingDailyMeme = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Daily meme posted successfully!'),
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
    } catch (e) {
      setState(() {
        _errorMessage = 'Error testing daily meme: $e';
        _isLoadingDailyMeme = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 12.0 : 24.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.image,
                      size: isMobile ? 28 : 32,
                      color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meme Management',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontSize: isMobile ? 24 : null,
                              ),
                        ),
                        Text(
                          'Test and manage meme posting functions',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: isMobile ? 13 : null,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 20 : 32),

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
                elevation: 2,
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
                        onPressed: _isLoadingRandomMeme ? null : _getRandomMeme,
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
                                  .withOpacity(0.2),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Meme Image
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
                                        .surfaceContainerHighest,
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
                                    .surfaceContainerHighest,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          label:
                                              _randomMemeData!['subreddit'] ??
                                                  'Unknown',
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
                                            onPressed: _isSendingMeme
                                                ? null
                                                : () => _sendMemeToDiscord(
                                                    _randomMemeData!),
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
                                                : const Icon(Icons.send),
                                            label: Text(_isSendingMeme
                                                ? 'Sending...'
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 14),
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
                elevation: 2,
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
                      const SizedBox(height: 24),
                      Text(
                        'Available Sources',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingSources)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._subreddits.map((sub) => ActionChip(
                                  avatar: const Icon(Icons.reddit, size: 16),
                                  label: Text('r/$sub'),
                                  onPressed: () {
                                    setState(() {
                                      _sourceController.text = sub;
                                    });
                                  },
                                )),
                            ..._lemmyCommunities.map((comm) => ActionChip(
                                  avatar: const Icon(Icons.public, size: 16),
                                  label: Text(comm),
                                  onPressed: () {
                                    setState(() {
                                      _sourceController.text = comm;
                                    });
                                  },
                                )),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _sourceController,
                          decoration: InputDecoration(
                            labelText: 'Source',
                            hintText: 'e.g., memes or lemmy.world@memes',
                            prefixIcon: const Icon(Icons.source),
                            border: const OutlineInputBorder(),
                            helperText:
                                'Enter a subreddit name or Lemmy community (instance@community)',
                          ),
                          onSubmitted: (_) => _getMemeFromSource(),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed:
                              _isLoadingSourceMeme ? null : _getMemeFromSource,
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
                                  .withOpacity(0.2),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                        .surfaceContainerHighest,
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
                                    .surfaceContainerHighest,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          label:
                                              _sourceMemeData!['subreddit'] ??
                                                  'Unknown',
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
                                            onPressed: _isSendingMeme
                                                ? null
                                                : () => _sendMemeToDiscord(
                                                    _sourceMemeData!),
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
                                                : const Icon(Icons.send),
                                            label: Text(_isSendingMeme
                                                ? 'Sending...'
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 14),
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

              // Daily Meme Test Card
              Card(
                elevation: 2,
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
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.schedule_send,
                              color: Colors.green,
                              size: isMobile ? 24 : 28,
                            ),
                          ),
                          SizedBox(width: isMobile ? 12 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Meme Test',
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
                                  'Test the daily meme posting function immediately',
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
                      SizedBox(height: isMobile ? 16 : 24),
                      Container(
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: isMobile ? 18 : 20,
                                color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This bypasses the schedule and posts a meme immediately to Discord.',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      FilledButton.tonalIcon(
                        onPressed: _isLoadingDailyMeme ? null : _testDailyMeme,
                        icon: _isLoadingDailyMeme
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.rocket_launch),
                        label: Text(_isLoadingDailyMeme
                            ? 'Posting Meme...'
                            : 'Post Daily Meme Now'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                        ),
                      ),
                      if (_dailyMemeResult != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _dailyMemeResult!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.w500,
                                      ),
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

              // Error Display
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  elevation: 2,
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
                          color: Theme.of(context).colorScheme.onErrorContainer,
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
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.5),
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
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
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
        );
      },
    );
  }

  Widget _buildInfoChip(BuildContext context,
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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
