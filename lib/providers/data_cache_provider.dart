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
              final existsInApi = newMemes.any((apiMeme) =>
                  apiMeme['image_url'] == optimisticMeme['image_url'] &&
                  apiMeme['title'] == optimisticMeme['title']);
              if (!existsInApi) {
                newMemes.insert(0, optimisticMeme);
                debugPrint(
                    '🔄 Kept optimistic meme: ${optimisticMeme['title']}');
              }
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
}
