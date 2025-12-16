/// Model for Community Posts
/// Represents a user-created post in the community feed
class CommunityPost {
  final int id;
  final String? content;
  final String? imageUrl;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String postType; // 'normal', 'admin', 'announcement'
  final bool isAnnouncement;
  final String? discordChannelId;
  final String? discordMessageId;
  final String createdAt;
  final String? editedAt;
  final String? deletedAt;
  final bool isDeleted;

  CommunityPost({
    required this.id,
    this.content,
    this.imageUrl,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.postType,
    required this.isAnnouncement,
    this.discordChannelId,
    this.discordMessageId,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
    this.isDeleted = false,
  });

  /// Create CommunityPost from JSON response
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    // Handle nested author object from backend
    final author = json['author'] as Map<String, dynamic>?;
    final authorId =
        author?['id']?.toString() ?? json['author_id']?.toString() ?? '';
    final authorName = author?['name']?.toString() ??
        json['author_name']?.toString() ??
        'Unknown';
    final authorAvatar =
        author?['avatar']?.toString() ?? json['author_avatar']?.toString();

    // Helper to convert bool/int/null to bool
    bool _toBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return CommunityPost(
      id: json['id'] as int,
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String?,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      postType: json['post_type'] as String? ?? 'normal',
      isAnnouncement: _toBool(json['is_announcement']),
      discordChannelId: json['discord_channel_id']?.toString(),
      discordMessageId: json['discord_message_id']?.toString(),
      createdAt: json['created_at'] as String,
      editedAt: json['edited_at'] as String?,
      deletedAt: json['deleted_at'] as String?,
      isDeleted: _toBool(json['is_deleted']),
    );
  }

  /// Convert CommunityPost to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'image_url': imageUrl,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'post_type': postType,
      'is_announcement': isAnnouncement ? 1 : 0,
      'discord_channel_id': discordChannelId,
      'discord_message_id': discordMessageId,
      'created_at': createdAt,
      'edited_at': editedAt,
      'deleted_at': deletedAt,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  /// Create a copy with updated fields
  CommunityPost copyWith({
    int? id,
    String? content,
    String? imageUrl,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? postType,
    bool? isAnnouncement,
    String? discordChannelId,
    String? discordMessageId,
    String? createdAt,
    String? editedAt,
    String? deletedAt,
    bool? isDeleted,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      postType: postType ?? this.postType,
      isAnnouncement: isAnnouncement ?? this.isAnnouncement,
      discordChannelId: discordChannelId ?? this.discordChannelId,
      discordMessageId: discordMessageId ?? this.discordMessageId,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Check if post has content
  bool get hasContent => content != null && content!.isNotEmpty;

  /// Check if post has image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Check if post is editable (within 24 hours, not deleted)
  bool get isEditable {
    if (isDeleted) return false;
    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(created);
      return difference.inHours < 24;
    } catch (e) {
      return false;
    }
  }

  /// Get formatted creation date
  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return createdAt;
    }
  }

  /// Check if post was edited
  bool get wasEdited => editedAt != null;

  @override
  String toString() {
    return 'CommunityPost(id: $id, authorName: $authorName, type: $postType, isAnnouncement: $isAnnouncement)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityPost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
