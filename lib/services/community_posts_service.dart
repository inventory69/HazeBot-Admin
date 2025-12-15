import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/community_post.dart';
import 'api_service.dart';

/// Service for Community Posts API interactions
/// Handles all CRUD operations for community posts
class CommunityPostsService {
  // Singleton pattern
  static final CommunityPostsService _instance =
      CommunityPostsService._internal();
  factory CommunityPostsService() => _instance;
  CommunityPostsService._internal();

  final ApiService _apiService = ApiService();

  /// Fetch posts with pagination
  /// 
  /// [limit] - Number of posts to fetch (default: 20)
  /// [offset] - Offset for pagination (default: 0)
  /// [includeDeleted] - Include deleted posts (admin only, default: false)
  /// 
  /// Returns list of [CommunityPost] and total count
  Future<Map<String, dynamic>> fetchPosts({
    int limit = 20,
    int offset = 0,
    bool includeDeleted = false,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (includeDeleted) 'include_deleted': 'true',
      };

      final uri = Uri.parse('${_apiService.baseUrl}/api/posts')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _apiService.getHeaders(),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw ApiTimeoutException(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final postsJson = data['posts'] as List;
        final posts =
            postsJson.map((json) => CommunityPost.fromJson(json)).toList();

        return {
          'posts': posts,
          'total': data['total'] ?? 0,
          'limit': data['limit'] ?? limit,
          'offset': data['offset'] ?? offset,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to fetch posts');
      }
    } on SocketException {
      throw ApiConnectionException();
    } catch (e) {
      debugPrint('❌ Error fetching posts: $e');
      rethrow;
    }
  }

  /// Create a new post
  /// 
  /// [content] - Text content (optional if image provided)
  /// [imageBase64] - Base64 encoded image (optional if content provided)
  /// [isAnnouncement] - Mark as announcement (admin/mod only)
  /// 
  /// Returns created [CommunityPost]
  Future<CommunityPost> createPost({
    String? content,
    String? imageBase64,
    bool isAnnouncement = false,
  }) async {
    try {
      // Validation
      if ((content == null || content.isEmpty) &&
          (imageBase64 == null || imageBase64.isEmpty)) {
        throw Exception('Content or image is required');
      }

      if (content != null && content.length > 2000) {
        throw Exception('Content too long (max 2000 characters)');
      }

      final body = {
        if (content != null && content.isNotEmpty) 'content': content,
        if (imageBase64 != null && imageBase64.isNotEmpty)
          'image': imageBase64,
        'is_announcement': isAnnouncement,
      };

      final response = await http
          .post(
            Uri.parse('${_apiService.baseUrl}/api/posts'),
            headers: await _apiService.getHeaders(),
            body: json.encode(body),
          )
          .timeout(
            const Duration(seconds: 30), // Longer timeout for image uploads
            onTimeout: () => throw ApiTimeoutException(),
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Create post object from response
        final post = CommunityPost(
          id: data['post_id'] as int,
          content: content,
          imageUrl: data['image_url'] as String?,
          authorId: data['author_id'] ?? 'unknown',
          authorName: data['author_name'] ?? 'Unknown',
          authorAvatar: data['author_avatar'] as String?,
          postType: isAnnouncement ? 'announcement' : 'normal',
          isAnnouncement: isAnnouncement,
          discordChannelId: data['discord_channel_id'] as String?,
          discordMessageId: data['discord_message_id'] as String?,
          createdAt: data['created_at'] as String,
          isDeleted: false,
        );

        debugPrint('✅ Post created: #${post.id}');
        return post;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create post');
      }
    } on SocketException {
      throw ApiConnectionException();
    } catch (e) {
      debugPrint('❌ Error creating post: $e');
      rethrow;
    }
  }

  /// Update an existing post
  /// 
  /// [postId] - ID of the post to update
  /// [content] - New content (optional)
  /// [imageBase64] - New image as base64 (optional, use empty string to remove)
  /// 
  /// Returns updated [CommunityPost]
  Future<CommunityPost> updatePost({
    required int postId,
    String? content,
    String? imageBase64,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (content != null) {
        if (content.isEmpty) {
          throw Exception('Content cannot be empty');
        }
        if (content.length > 2000) {
          throw Exception('Content too long (max 2000 characters)');
        }
        body['content'] = content;
      }

      if (imageBase64 != null) {
        body['image'] = imageBase64; // Empty string removes image
      }

      final response = await http
          .put(
            Uri.parse('${_apiService.baseUrl}/api/posts/$postId'),
            headers: await _apiService.getHeaders(),
            body: json.encode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiTimeoutException(),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Fetch updated post to get complete data
        final updatedPosts = await fetchPosts(limit: 1, offset: 0);
        final post = (updatedPosts['posts'] as List<CommunityPost>)
            .firstWhere((p) => p.id == postId);

        debugPrint('✅ Post updated: #$postId');
        return post;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied - You can only edit your own posts');
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update post');
      }
    } on SocketException {
      throw ApiConnectionException();
    } catch (e) {
      debugPrint('❌ Error updating post: $e');
      rethrow;
    }
  }

  /// Delete a post (soft delete)
  /// 
  /// [postId] - ID of the post to delete
  /// 
  /// Returns true if successful
  Future<bool> deletePost(int postId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${_apiService.baseUrl}/api/posts/$postId'),
            headers: await _apiService.getHeaders(),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw ApiTimeoutException(),
          );

      if (response.statusCode == 200) {
        debugPrint('✅ Post deleted: #$postId');
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 403) {
        throw Exception(
            'Permission denied - You can only delete your own posts');
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete post');
      }
    } on SocketException {
      throw ApiConnectionException();
    } catch (e) {
      debugPrint('❌ Error deleting post: $e');
      rethrow;
    }
  }

  /// Get full image URL from relative path
  String getImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    return '${_apiService.baseUrl}/$imageUrl';
  }
}
