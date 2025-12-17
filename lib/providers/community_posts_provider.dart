import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/community_post.dart';
import '../services/community_posts_service.dart';

/// Provider for Community Posts
/// Manages state and handles CRUD operations for community posts
class CommunityPostsProvider extends ChangeNotifier {
  final CommunityPostsService _service = CommunityPostsService();

  // Cache data
  List<CommunityPost> _posts = [];
  int _totalPosts = 0;
  int _currentLimit = 20;
  int _currentOffset = 0;

  // Loading states
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _hasMore = true;

  // Cache metadata
  DateTime? _lastLoad;
  static const Duration _cacheDuration = Duration(seconds: 20);

  // Auto-refresh timer
  Timer? _refreshTimer;

  // Error handling
  String? _lastError;

  // Getters
  List<CommunityPost> get posts => _posts;
  int get totalPosts => _totalPosts;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  bool get hasMore => _hasMore;
  String? get lastError => _lastError;
  String? get error => _lastError; // Alias for consistency
  DateTime? get lastLoad => _lastLoad;

  /// Check if cache is fresh
  bool get isCacheFresh {
    if (_lastLoad == null) return false;
    final age = DateTime.now().difference(_lastLoad!);
    return age < _cacheDuration;
  }

  /// Get cache age in human-readable format
  String get cacheAge {
    if (_lastLoad == null) return 'Never loaded';
    final age = DateTime.now().difference(_lastLoad!);
    if (age.inSeconds < 60) {
      return 'Just now';
    } else if (age.inMinutes < 60) {
      return '${age.inMinutes}m ago';
    } else {
      return '${age.inHours}h ago';
    }
  }

  /// Load posts with pagination
  ///
  /// [force] - Force refresh even if cache is fresh
  /// [reset] - Reset pagination and start from beginning
  Future<void> loadPosts({bool force = false, bool reset = false}) async {
    // If cache is fresh and not forcing, return cached data
    if (!force && !reset && isCacheFresh && _posts.isNotEmpty) {
      debugPrint('📦 Using cached posts (age: $cacheAge)');
      return;
    }

    // If already loading, skip
    if (_isLoading) {
      debugPrint('⏳ Posts already loading, skipping duplicate request');
      return;
    }

    // Reset pagination if requested
    if (reset) {
      _currentOffset = 0;
      _posts.clear();
      _hasMore = true;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      debugPrint(
          '🔄 Loading posts (offset: $_currentOffset, limit: $_currentLimit)...');

      final result = await _service.fetchPosts(
        limit: _currentLimit,
        offset: _currentOffset,
      );

      final newPosts = result['posts'] as List<CommunityPost>;
      _totalPosts = result['total'] as int;

      if (reset) {
        _posts = newPosts;
      } else {
        // Prepend new posts, avoiding duplicates
        for (final post in newPosts) {
          if (!_posts.any((p) => p.id == post.id)) {
            _posts.insert(0, post);  // Insert at start, not end
          }
        }
      }

      // Update pagination
      _currentOffset += newPosts.length;
      _hasMore = newPosts.length >= _currentLimit;

      _lastLoad = DateTime.now();
      debugPrint(
          '✅ Loaded ${newPosts.length} posts (total cached: ${_posts.length})');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Error loading posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more posts (pagination)
  Future<void> loadMorePosts() async {
    if (!_hasMore || _isLoading) return;
    await loadPosts(force: true, reset: false);
  }

  /// Refresh posts (reset and reload)
  Future<void> refreshPosts() async {
    await loadPosts(force: true, reset: true);
  }

  /// Create a new post
  ///
  /// [content] - Text content (optional if image provided)
  /// [imageBase64] - Base64 encoded image (optional if content provided)
  /// [isAnnouncement] - Mark as announcement (admin/mod only)
  Future<bool> createPost({
    String? content,
    String? imageBase64,
    bool isAnnouncement = false,
  }) async {
    _isCreating = true;
    _lastError = null;
    notifyListeners();

    try {
      debugPrint('📝 Creating post...');

      final post = await _service.createPost(
        content: content,
        imageBase64: imageBase64,
        isAnnouncement: isAnnouncement,
      );

      // Add post to beginning of list (optimistic update)
      _posts.insert(0, post);
      _totalPosts++;

      debugPrint('✅ Post created and added to cache: #${post.id}');

      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Error creating post: $e');
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  /// Update an existing post
  ///
  /// [postId] - ID of the post to update
  /// [content] - New content (optional)
  /// [imageBase64] - New image as base64 (optional)
  Future<bool> updatePost({
    required int postId,
    String? content,
    String? imageBase64,
  }) async {
    _isUpdating = true;
    _lastError = null;
    notifyListeners();

    try {
      debugPrint('✏️  Updating post #$postId...');

      final updatedPost = await _service.updatePost(
        postId: postId,
        content: content,
        imageBase64: imageBase64,
      );

      // Update post in cache
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
      }

      debugPrint('✅ Post updated in cache: #$postId');

      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Error updating post: $e');
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Delete a post
  ///
  /// [postId] - ID of the post to delete
  Future<bool> deletePost(int postId) async {
    _isDeleting = true;
    _lastError = null;
    notifyListeners();

    try {
      debugPrint('🗑️  Deleting post #$postId...');

      final success = await _service.deletePost(postId);

      if (success) {
        // Remove post from cache
        _posts.removeWhere((p) => p.id == postId);
        _totalPosts--;

        debugPrint('✅ Post removed from cache: #$postId');
      }

      return success;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Error deleting post: $e');
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  /// Get a specific post by ID
  CommunityPost? getPostById(int postId) {
    try {
      return _posts.firstWhere((p) => p.id == postId);
    } catch (e) {
      return null;
    }
  }

  /// Clear cache and reset state
  void clearCache() {
    _posts.clear();
    _totalPosts = 0;
    _currentOffset = 0;
    _hasMore = true;
    _lastLoad = null;
    _lastError = null;
    notifyListeners();
    debugPrint('🧹 Community posts cache cleared');
  }

  /// Get image URL helper
  String getImageUrl(String imageUrl) {
    return _service.getImageUrl(imageUrl);
  }

  // ============================================================================
  // AUTO-REFRESH (DISABLED - User feedback: too annoying)
  // Can be re-enabled later or made into a user setting
  // ============================================================================

  // /// Start automatic refresh timer
  // /// Refreshes posts every 20 seconds when screen is active
  // void startAutoRefresh() {
  //   _refreshTimer?.cancel();
  //   _refreshTimer = Timer.periodic(Duration(seconds: 20), (_) {
  //     if (!_isLoading) {
  //       debugPrint('🔄 Auto-refreshing community posts...');
  //       loadPosts(force: true, reset: true);
  //     }
  //   });
  //   debugPrint('✅ Auto-refresh started (20s interval)');
  // }

  // /// Stop automatic refresh timer
  // void stopAutoRefresh() {
  //   _refreshTimer?.cancel();
  //   _refreshTimer = null;
  //   debugPrint('⏹️ Auto-refresh stopped');
  // }

  // @override
  // void dispose() {
  //   stopAutoRefresh();
  //   super.dispose();
  // }
}
