import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Centralized data cache provider
/// Prevents unnecessary API calls on tab switches
class DataCacheProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Cache timestamps
  DateTime? _lastMemesLoad;
  DateTime? _lastRankupsLoad;

  // Cached data
  List<Map<String, dynamic>>? _cachedMemes;
  List<Map<String, dynamic>>? _cachedRankups;

  // Loading states
  bool _isLoadingMemes = false;
  bool _isLoadingRankups = false;

  // Cache duration (how long before we refresh data)
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Local upvote overrides (to handle Discord sync delay)
  // Maps message_id -> {upvotes: int, timestamp: DateTime}
  final Map<String, Map<String, dynamic>> _localUpvoteOverrides = {};

  // Getters
  List<Map<String, dynamic>>? get memes => _cachedMemes;
  List<Map<String, dynamic>>? get rankups => _cachedRankups;
  bool get isLoadingMemes => _isLoadingMemes;
  bool get isLoadingRankups => _isLoadingRankups;
  DateTime? get lastMemesLoad => _lastMemesLoad;
  DateTime? get lastRankupsLoad => _lastRankupsLoad;

  /// Get cache age in human-readable format
  String getCacheAge() {
    if (_lastMemesLoad == null && _lastRankupsLoad == null) {
      return 'No data loaded';
    }

    final latestLoad = _lastMemesLoad != null && _lastRankupsLoad != null
        ? (_lastMemesLoad!.isAfter(_lastRankupsLoad!)
            ? _lastMemesLoad!
            : _lastRankupsLoad!)
        : (_lastMemesLoad ?? _lastRankupsLoad!);

    final age = DateTime.now().difference(latestLoad);

    if (age.inSeconds < 60) {
      return 'Just now';
    } else if (age.inMinutes < 60) {
      return '${age.inMinutes}m ago';
    } else {
      return '${age.inHours}h ago';
    }
  }

  /// Load latest memes (with caching)
  Future<void> loadLatestMemes({bool force = false, int limit = 5}) async {
    // If cache is fresh and not forcing, return cached data
    if (!force &&
        _cachedMemes != null &&
        _lastMemesLoad != null &&
        DateTime.now().difference(_lastMemesLoad!) < _cacheDuration) {
      debugPrint(
          '📦 Using cached memes (age: ${DateTime.now().difference(_lastMemesLoad!).inSeconds}s)');
      return;
    }

    if (_isLoadingMemes) {
      debugPrint('⏳ Memes already loading, skipping duplicate request');
      return;
    }

    _isLoadingMemes = true;
    notifyListeners();

    try {
      debugPrint('🔄 Loading latest memes from API...');
      final response = await _apiService.getLatestMemes(limit: limit);
      if (response['success'] == true) {
        final newMemes =
            List<Map<String, dynamic>>.from(response['memes'] ?? []);

        // Preserve optimistically added memes (those with timestamp < 5 seconds old)
        // These are memes we added locally that might not be in the API response yet
        if (_cachedMemes != null && _cachedMemes!.isNotEmpty) {
          final now = DateTime.now();
          final optimisticMemes = _cachedMemes!.where((meme) {
            try {
              final timestamp = DateTime.parse(meme['timestamp']);
              final age = now.difference(timestamp);
              return age.inSeconds < 5; // Keep very recent optimistic adds
            } catch (e) {
              return false;
            }
          }).toList();

          if (optimisticMemes.isNotEmpty) {
            debugPrint(
                '🔄 Preserving ${optimisticMemes.length} optimistic meme(s)');
            // Add optimistic memes that aren't in the API response yet
            for (final optimisticMeme in optimisticMemes) {
              // Check if meme exists in API by image_url (more reliable than title)
              final existsInApi = newMemes.any((apiMeme) =>
                  apiMeme['image_url'] == optimisticMeme['image_url'] ||
                  (apiMeme['title'] == optimisticMeme['title'] &&
                      apiMeme['image_url']?.toString().contains(
                              optimisticMeme['image_url']
                                      ?.toString()
                                      .split('/')
                                      .last ??
                                  '') ==
                          true));
              if (!existsInApi) {
                newMemes.insert(0, optimisticMeme);
                debugPrint(
                    '🔄 Kept optimistic meme: ${optimisticMeme['title']}');
              } else {
                debugPrint(
                    '✅ Optimistic meme already in API response: ${optimisticMeme['title']}');
              }
            }
          }
        }

        // Apply local upvote overrides (for Discord sync delay)
        final now = DateTime.now();
        for (final meme in newMemes) {
          final messageId = meme['message_id'] as String?;
          if (messageId != null &&
              _localUpvoteOverrides.containsKey(messageId)) {
            final override = _localUpvoteOverrides[messageId]!;
            final localUpvotes = override['upvotes'] as int;
            final timestamp = override['timestamp'] as DateTime;
            final apiUpvotes = meme['upvotes'] as int? ?? 0;

            // Check if override is still valid (within 30 seconds)
            final age = now.difference(timestamp);

            if (age.inSeconds < 30) {
              // Override still active
              meme['upvotes'] = localUpvotes;
              debugPrint(
                  '👍 Applied local upvote override for $messageId: $localUpvotes (API: $apiUpvotes, age: ${age.inSeconds}s)');
            } else {
              // Override expired, use API value
              _localUpvoteOverrides.remove(messageId);
              debugPrint(
                  '⏰ Override expired for $messageId (${age.inSeconds}s old), using API: $apiUpvotes');
            }
          }
        }

        _cachedMemes = newMemes;
        _lastMemesLoad = DateTime.now();
        debugPrint('✅ Memes loaded and cached (${_cachedMemes!.length} items)');
      }
    } catch (e) {
      debugPrint('❌ Failed to load memes: $e');
      // Keep old cache if available
    } finally {
      _isLoadingMemes = false;
      notifyListeners();
    }
  }

  /// Load latest rankups (with caching)
  Future<void> loadLatestRankups({bool force = false, int limit = 10}) async {
    if (!force &&
        _cachedRankups != null &&
        _lastRankupsLoad != null &&
        DateTime.now().difference(_lastRankupsLoad!) < _cacheDuration) {
      debugPrint(
          '📦 Using cached rankups (age: ${DateTime.now().difference(_lastRankupsLoad!).inSeconds}s)');
      return;
    }

    if (_isLoadingRankups) {
      debugPrint('⏳ Rankups already loading, skipping duplicate request');
      return;
    }

    _isLoadingRankups = true;
    notifyListeners();

    try {
      debugPrint('🔄 Loading latest rankups from API...');
      final response = await _apiService.getLatestRankups(limit: limit);
      if (response['success'] == true) {
        _cachedRankups =
            List<Map<String, dynamic>>.from(response['rankups'] ?? []);
        _lastRankupsLoad = DateTime.now();
        debugPrint(
            '✅ Rankups loaded and cached (${_cachedRankups!.length} items)');
      }
    } catch (e) {
      debugPrint('❌ Failed to load rankups: $e');
    } finally {
      _isLoadingRankups = false;
      notifyListeners();
    }
  }

  /// Clear all caches (e.g., on logout)
  void clearCache() {
    _cachedMemes = null;
    _cachedRankups = null;
    _lastMemesLoad = null;
    _lastRankupsLoad = null;
    _localUpvoteOverrides.clear();
    notifyListeners();
  }

  /// Invalidate cache (force reload on next access)
  void invalidateCache() {
    _lastMemesLoad = null;
    _lastRankupsLoad = null;
    notifyListeners();
  }

  /// Add a meme optimistically to the cache (for immediate UI update)
  /// This is used when sending a meme to Discord to show it immediately
  void addMemeOptimistically(Map<String, dynamic> memeData) {
    debugPrint('✨ addMemeOptimistically called with: $memeData');
    debugPrint('✨ Current cache: $_cachedMemes');

    if (_cachedMemes == null) {
      _cachedMemes = [];
      debugPrint('✨ Cache was null, initialized empty list');
    }

    // Add the new meme at the beginning of the list
    _cachedMemes!.insert(0, memeData);
    debugPrint(
        '✨ Inserted meme at position 0, new length: ${_cachedMemes!.length}');

    // Keep only the latest items (same as API limit)
    if (_cachedMemes!.length > 10) {
      _cachedMemes = _cachedMemes!.sublist(0, 10);
      debugPrint('✨ Trimmed cache to 10 items');
    }

    _lastMemesLoad = DateTime.now();
    debugPrint('✨ Updated lastMemesLoad to: $_lastMemesLoad');
    debugPrint('✨ Calling notifyListeners() now...');
    notifyListeners();
    debugPrint(
        '✨ notifyListeners() called! Cache now has ${_cachedMemes!.length} items');

    // Schedule a background refresh after 3 seconds to sync with backend
    Future.delayed(const Duration(seconds: 3), () {
      debugPrint('✨ Background refresh triggered after 3s delay');
      loadLatestMemes(force: true);
    });
  }

  /// Update upvotes for a specific meme in the cache
  void updateMemeUpvotes(String? messageId, int upvotes) {
    if (messageId == null) return;

    debugPrint('👍 Updating upvotes for message $messageId to $upvotes');

    // Store as local override with timestamp (expires after 30s)
    _localUpvoteOverrides[messageId] = {
      'upvotes': upvotes,
      'timestamp': DateTime.now(),
    };
    debugPrint(
        '👍 Stored local override for $messageId: $upvotes (expires in 30s)');

    // Also update in current cache if available
    if (_cachedMemes != null) {
      bool updated = false;
      for (int i = 0; i < _cachedMemes!.length; i++) {
        if (_cachedMemes![i]['message_id'] == messageId) {
          _cachedMemes![i]['upvotes'] = upvotes;
          debugPrint(
              '👍 Updated meme at index $i: ${_cachedMemes![i]['title']}');
          updated = true;
          break;
        }
      }

      if (updated) {
        notifyListeners();
        debugPrint('👍 Cache updated and listeners notified');
      } else {
        debugPrint(
            '👍 Meme not found in current cache (will apply on next load)');
      }
    }
  }
}
